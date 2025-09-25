import {onObjectFinalized} from "firebase-functions/v2/storage";
import {Storage} from "@google-cloud/storage";
import {ImageAnnotatorClient} from "@google-cloud/vision";
import {FieldValue, getFirestore} from "firebase-admin/firestore";

const storage = new Storage();
const visionClient = new ImageAnnotatorClient();

const PAYSTUB_BUCKET =
  process.env.PAYSTUB_BUCKET || "gong-mu-talk.firebasestorage.app";

// eslint-disable-next-line @typescript-eslint/no-var-requires
const pdfParse = require("pdf-parse");

type VerificationResult = {
  detectedTrack?: string;
  detectedKeywords: string[];
  status: "verified" | "failed";
  errorMessage?: string;
};

const TRACK_KEYWORDS: Array<{track: string; keywords: string[]}> = [
  {track: "teacher", keywords: ["국공립교원", "교원구분", "교원구분", "교사"]},
  {track: "publicAdministration", keywords: ["행정직", "행정공무원"]},
  {track: "police", keywords: ["경찰직", "경찰관"]},
  {track: "firefighter", keywords: ["소방직", "소방공무원"]},
  {track: "customs", keywords: ["관세직", "관세공무원"]},
  {track: "educationAdmin", keywords: ["교육행정직"]},
  {track: "itSpecialist", keywords: ["정보화전문직", "정보 직렬"]},
];

/**
 * Process uploaded paystub files, extract text, and attempt to detect a career
 * track. Results are written back to the uploader's verification document.
 */
export const handlePaystubUpload = onObjectFinalized(
  {
    region: "us-central1",
    memory: "1GiB",
    timeoutSeconds: 300,
  },
  async (event) => {
    const object = event.data;
    const metadata = object.metadata ?? {};
    const uid = metadata.uid;
    const docPath = metadata.verificationDocPath;

    if (!uid || !docPath) {
      console.error(
        "Missing verification metadata on uploaded file",
        object.name
      );
      if (docPath) {
        await markVerification(docPath, {
          status: "failed",
          detectedKeywords: [],
          errorMessage:
            "업로드한 파일에서 인증 정보를 확인하지 못했습니다. 다시 시도해주세요.",
        });
      }
      return;
    }

    const bucketName = object.bucket;
    const filePath = object.name;
    if (!bucketName || !filePath) {
      console.error("Invalid storage object data", object);
      await markVerification(docPath, {
        status: "failed",
        detectedKeywords: [],
        errorMessage:
          "업로드한 파일 정보를 확인하지 못했습니다. 다시 시도해주세요.",
      });
      return;
    }

    if (bucketName !== PAYSTUB_BUCKET) {
      console.warn(
        `Processing paystub upload from non-default bucket ${bucketName}`
      );
    }

    const bucket = storage.bucket(bucketName);
    const file = bucket.file(filePath);

    try {
      console.log(`Processing paystub upload for ${uid}: ${filePath}`);
      const [buffer] = await file.download();
      const text = await extractTextFromFile(
        buffer,
        object.contentType ?? ""
      );
      if (!text || text.trim().length === 0) {
        await markVerification(docPath, {
          status: "failed",
          detectedKeywords: [],
          errorMessage: "문서에서 텍스트를 추출하지 못했습니다.",
        });
        return;
      }

      const result = detectCareerTrack(text);
      await markVerification(docPath, {
        ...result,
        detectedKeywords: result.detectedKeywords,
      });
    } catch (error) {
      console.error(
        `Failed to process paystub for ${uid}: ${filePath}`,
        error
      );
      await markVerification(docPath, {
        status: "failed",
        detectedKeywords: [],
        errorMessage: "문서를 분석하는 중 오류가 발생했습니다.",
      });
    }
  }
);

/**
 * Extract raw text from a PDF or image buffer.
 *
 * @param {Buffer} buffer Uploaded file contents.
 * @param {string} contentType MIME type of the uploaded file.
 * @return {Promise<string>} Extracted text content.
 */
async function extractTextFromFile(
  buffer: Buffer,
  contentType: string
): Promise<string> {
  if (contentType.includes("pdf")) {
    const data = await pdfParse(buffer);
    return (data && data.text) || "";
  }

  const [result] = await visionClient.textDetection({
    image: {content: buffer},
  });
  return result.fullTextAnnotation?.text ?? "";
}

/**
 * Determine a career track match from the parsed paystub text.
 *
 * @param {string} text Extracted document text.
 * @return {VerificationResult} Detection outcome.
 */
function detectCareerTrack(text: string): VerificationResult {
  const normalized = text.replace(/\s+/g, "");
  for (const entry of TRACK_KEYWORDS) {
    const matchedKeywords = entry.keywords.filter((keyword) =>
      normalized.includes(keyword.replace(/\s+/g, "")),
    );
    if (matchedKeywords.length > 0) {
      return {
        status: "verified",
        detectedTrack: entry.track,
        detectedKeywords: matchedKeywords,
      };
    }
  }

  return {
    status: "failed",
    detectedKeywords: [],
    errorMessage: "급여 명세서에서 직렬 정보를 찾지 못했습니다.",
  };
}

/**
 * Persist the verification result back to Firestore.
 *
 * @param {string} path Document path to update.
 * @param {VerificationResult} result Detection outcome payload.
 */
async function markVerification(path: string, result: VerificationResult) {
  await getFirestore().doc(path).set(
    {
      status: result.status,
      detectedTrack:
        result.status === "verified" ? result.detectedTrack ?? null : null,
      detectedKeywords: result.detectedKeywords,
      errorMessage: result.errorMessage ?? null,
      updatedAt: FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
}
