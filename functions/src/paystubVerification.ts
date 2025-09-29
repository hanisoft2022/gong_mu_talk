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

// 계층적 직렬 키워드 매칭 시스템
const ENHANCED_TRACK_KEYWORDS: Array<{
  track: string;
  keywords: string[];
  institutionKeywords?: string[];
  priority: number; // 높을수록 우선순위 높음
}> = [
  // 교육 분야 - 초등교사
  {
    track: "elementary_teacher",
    keywords: ["교사(초등)", "초등교사"],
    institutionKeywords: ["초등학교"],
    priority: 10,
  },

  // 교육 분야 - 중등교사 (교과별)
  {
    track: "secondary_math_teacher",
    keywords: ["교사(중등)", "중등교사", "수학"],
    institutionKeywords: ["중학교", "고등학교"],
    priority: 10,
  },
  {
    track: "secondary_korean_teacher",
    keywords: ["교사(중등)", "중등교사", "국어"],
    institutionKeywords: ["중학교", "고등학교"],
    priority: 10,
  },
  {
    track: "secondary_english_teacher",
    keywords: ["교사(중등)", "중등교사", "영어"],
    institutionKeywords: ["중학교", "고등학교"],
    priority: 10,
  },
  {
    track: "secondary_science_teacher",
    keywords: ["교사(중등)", "중등교사", "과학", "물리", "화학", "생물"],
    institutionKeywords: ["중학교", "고등학교"],
    priority: 10,
  },
  {
    track: "secondary_social_teacher",
    keywords: ["교사(중등)", "중등교사", "사회", "역사", "지리"],
    institutionKeywords: ["중학교", "고등학교"],
    priority: 10,
  },
  {
    track: "secondary_arts_teacher",
    keywords: ["교사(중등)", "중등교사", "체육", "음악", "미술", "기술", "가정"],
    institutionKeywords: ["중학교", "고등학교"],
    priority: 10,
  },

  // 교육 분야 - 특수교사
  {
    track: "counselor_teacher",
    keywords: ["상담교사", "전문상담교사"],
    institutionKeywords: ["학교"],
    priority: 10,
  },
  {
    track: "health_teacher",
    keywords: ["보건교사"],
    institutionKeywords: ["학교"],
    priority: 10,
  },
  {
    track: "librarian_teacher",
    keywords: ["사서교사"],
    institutionKeywords: ["학교"],
    priority: 10,
  },
  {
    track: "nutrition_teacher",
    keywords: ["영양교사"],
    institutionKeywords: ["학교"],
    priority: 10,
  },

  // 행정직 - 국가직
  {
    track: "admin_9th_national",
    keywords: ["9급", "행정직", "국가직"],
    institutionKeywords: ["부", "청", "처", "원"],
    priority: 9,
  },
  {
    track: "admin_7th_national",
    keywords: ["7급", "행정직", "국가직"],
    institutionKeywords: ["부", "청", "처", "원"],
    priority: 9,
  },
  {
    track: "admin_5th_national",
    keywords: ["5급", "행정관", "국가직"],
    institutionKeywords: ["부", "청", "처", "원"],
    priority: 9,
  },

  // 행정직 - 지방직
  {
    track: "admin_9th_local",
    keywords: ["9급", "행정직", "지방직"],
    institutionKeywords: ["시청", "구청", "도청", "군청"],
    priority: 9,
  },
  {
    track: "admin_7th_local",
    keywords: ["7급", "행정직", "지방직"],
    institutionKeywords: ["시청", "구청", "도청", "군청"],
    priority: 9,
  },
  {
    track: "admin_5th_local",
    keywords: ["5급", "행정관", "지방직"],
    institutionKeywords: ["시청", "구청", "도청", "군청"],
    priority: 9,
  },

  // 치안/안전
  {
    track: "police",
    keywords: ["경찰관", "경사", "경위", "경찰직"],
    institutionKeywords: ["경찰서", "지방경찰청"],
    priority: 8,
  },
  {
    track: "firefighter",
    keywords: ["소방사", "소방교", "소방장", "소방직"],
    institutionKeywords: ["소방서", "소방본부"],
    priority: 8,
  },
  {
    track: "coast_guard",
    keywords: ["해양경찰", "해경"],
    institutionKeywords: ["해양경찰서"],
    priority: 8,
  },

  // 군인
  {
    track: "army",
    keywords: ["육군", "장교", "부사관", "병사"],
    institutionKeywords: ["사단", "연대", "대대"],
    priority: 7,
  },
  {
    track: "navy",
    keywords: ["해군", "장교", "부사관", "병사"],
    institutionKeywords: ["함대", "전단"],
    priority: 7,
  },
  {
    track: "air_force",
    keywords: ["공군", "장교", "부사관", "병사"],
    institutionKeywords: ["비행단", "전투비행단"],
    priority: 7,
  },

  // 기타 직렬
  {
    track: "postal_service",
    keywords: ["우정직", "집배원"],
    institutionKeywords: ["우체국"],
    priority: 6,
  },
  {
    track: "legal_correction",
    keywords: ["검사", "판사", "교정직", "법무행정"],
    institutionKeywords: ["법원", "검찰청", "교정청"],
    priority: 6,
  },

  // 일반적인 키워드 (낮은 우선순위)
  {
    track: "teacher", // 세분화되지 않은 일반 교사
    keywords: ["국공립교원", "교원구분", "교사"],
    priority: 5,
  },
  {
    track: "admin", // 세분화되지 않은 일반 행정직
    keywords: ["행정직", "행정공무원"],
    priority: 5,
  },
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
 * Determine a career track match from the parsed paystub text with enhanced
 * keyword matching and institution verification.
 *
 * @param {string} text Extracted document text.
 * @return {VerificationResult} Detection outcome.
 */
function detectCareerTrack(text: string): VerificationResult {
  const normalized = text.replace(/\s+/g, "");
  const candidates: Array<{
    track: string;
    matchedKeywords: string[];
    score: number;
    priority: number;
  }> = [];

  // 모든 키워드 패턴을 확인
  for (const entry of ENHANCED_TRACK_KEYWORDS) {
    const matchedKeywords = entry.keywords.filter((keyword) =>
      normalized.includes(keyword.replace(/\s+/g, "")),
    );

    if (matchedKeywords.length > 0) {
      let score = matchedKeywords.length;

      // 기관명 키워드가 있는 경우 추가 검증
      if (entry.institutionKeywords) {
        const matchedInstitutions = entry.institutionKeywords.filter(
          (institution) =>
            normalized.includes(institution.replace(/\s+/g, "")),
        );

        if (matchedInstitutions.length > 0) {
          // 기관명이 매칭되면 높은 점수 부여
          score += matchedInstitutions.length * 2;
        } else {
          // 기관명이 없으면 점수 감점 (하지만 완전히 배제하지는 않음)
          score *= 0.7;
        }
      }

      candidates.push({
        track: entry.track,
        matchedKeywords,
        score,
        priority: entry.priority,
      });
    }
  }

  if (candidates.length === 0) {
    return {
      status: "failed",
      detectedKeywords: [],
      errorMessage: "급여 명세서에서 직렬 정보를 찾지 못했습니다.",
    };
  }

  // 우선순위와 점수를 기준으로 정렬
  candidates.sort((a, b) => {
    // 1순위: 우선순위 (높을수록 우선)
    if (a.priority !== b.priority) {
      return b.priority - a.priority;
    }
    // 2순위: 매칭 점수 (높을수록 우선)
    return b.score - a.score;
  });

  const bestMatch = candidates[0];

  console.log(`Career detection results:`, {
    totalCandidates: candidates.length,
    bestMatch: {
      track: bestMatch.track,
      score: bestMatch.score,
      priority: bestMatch.priority,
      keywords: bestMatch.matchedKeywords,
    },
    allCandidates: candidates.map(c => ({
      track: c.track,
      score: c.score,
      priority: c.priority,
    })),
  });

  return {
    status: "verified",
    detectedTrack: bestMatch.track,
    detectedKeywords: bestMatch.matchedKeywords,
  };
}

/**
 * Persist the verification result back to Firestore.
 *
 * @param {string} path Document path to update.
 * @param {VerificationResult} result Detection outcome payload.
 */
/**
 * Generate career hierarchy from detected track
 */
function generateCareerHierarchy(careerTrack: string): any {
  switch (careerTrack) {
    // 초등교사
    case "elementary_teacher":
      return {
        specificCareer: "elementary_teacher",
        level1: "all",
        level2: "teacher",
        level3: "elementary_teacher",
      };

    // 중등교사들
    case "secondary_math_teacher":
      return {
        specificCareer: "secondary_math_teacher",
        level1: "all",
        level2: "teacher",
        level3: "secondary_teacher",
        level4: "secondary_math_teacher",
      };
    case "secondary_korean_teacher":
      return {
        specificCareer: "secondary_korean_teacher",
        level1: "all",
        level2: "teacher",
        level3: "secondary_teacher",
        level4: "secondary_korean_teacher",
      };
    case "secondary_english_teacher":
      return {
        specificCareer: "secondary_english_teacher",
        level1: "all",
        level2: "teacher",
        level3: "secondary_teacher",
        level4: "secondary_english_teacher",
      };
    case "secondary_science_teacher":
      return {
        specificCareer: "secondary_science_teacher",
        level1: "all",
        level2: "teacher",
        level3: "secondary_teacher",
        level4: "secondary_science_teacher",
      };
    case "secondary_social_teacher":
      return {
        specificCareer: "secondary_social_teacher",
        level1: "all",
        level2: "teacher",
        level3: "secondary_teacher",
        level4: "secondary_social_teacher",
      };
    case "secondary_arts_teacher":
      return {
        specificCareer: "secondary_arts_teacher",
        level1: "all",
        level2: "teacher",
        level3: "secondary_teacher",
        level4: "secondary_arts_teacher",
      };

    // 행정직들
    case "admin_9th_national":
      return {
        specificCareer: "admin_9th_national",
        level1: "all",
        level2: "admin",
        level3: "national_admin",
        level4: "admin_9th_national",
      };
    case "admin_7th_national":
      return {
        specificCareer: "admin_7th_national",
        level1: "all",
        level2: "admin",
        level3: "national_admin",
        level4: "admin_7th_national",
      };
    case "admin_5th_national":
      return {
        specificCareer: "admin_5th_national",
        level1: "all",
        level2: "admin",
        level3: "national_admin",
        level4: "admin_5th_national",
      };
    case "admin_9th_local":
      return {
        specificCareer: "admin_9th_local",
        level1: "all",
        level2: "admin",
        level3: "local_admin",
        level4: "admin_9th_local",
      };
    case "admin_7th_local":
      return {
        specificCareer: "admin_7th_local",
        level1: "all",
        level2: "admin",
        level3: "local_admin",
        level4: "admin_7th_local",
      };
    case "admin_5th_local":
      return {
        specificCareer: "admin_5th_local",
        level1: "all",
        level2: "admin",
        level3: "local_admin",
        level4: "admin_5th_local",
      };

    // 치안/안전 (2단계)
    case "police":
      return {
        specificCareer: "police",
        level1: "all",
        level2: "police",
      };
    case "firefighter":
      return {
        specificCareer: "firefighter",
        level1: "all",
        level2: "firefighter",
      };
    case "coast_guard":
      return {
        specificCareer: "coast_guard",
        level1: "all",
        level2: "coast_guard",
      };

    // 군인 (3단계)
    case "army":
      return {
        specificCareer: "army",
        level1: "all",
        level2: "military",
        level3: "army",
      };
    case "navy":
      return {
        specificCareer: "navy",
        level1: "all",
        level2: "military",
        level3: "navy",
      };
    case "air_force":
      return {
        specificCareer: "air_force",
        level1: "all",
        level2: "military",
        level3: "air_force",
      };

    // 기타
    case "postal_service":
    case "legal_correction":
    case "security_protection":
    case "diplomatic_international":
    case "independent_agencies":
      return {
        specificCareer: careerTrack,
        level1: "all",
        level2: careerTrack,
      };

    // 일반적인 분류 (fallback)
    case "teacher":
      return {
        specificCareer: "teacher",
        level1: "all",
        level2: "teacher",
      };
    case "admin":
      return {
        specificCareer: "admin",
        level1: "all",
        level2: "admin",
      };

    default:
      return {
        specificCareer: careerTrack,
        level1: "all",
      };
  }
}

/**
 * Get accessible lounge IDs from career track
 */
function getLoungeIdsFromCareer(careerTrack: string): string[] {
  const careerToLoungeMapping: Record<string, string[]> = {
    // 교육 분야
    elementary_teacher: ["all", "teacher", "elementary_teacher"],
    secondary_math_teacher: ["all", "teacher", "secondary_teacher", "secondary_math_teacher"],
    secondary_korean_teacher: ["all", "teacher", "secondary_teacher", "secondary_korean_teacher"],
    secondary_english_teacher: ["all", "teacher", "secondary_teacher", "secondary_english_teacher"],
    secondary_science_teacher: ["all", "teacher", "secondary_teacher", "secondary_science_teacher"],
    secondary_social_teacher: ["all", "teacher", "secondary_teacher", "secondary_social_teacher"],
    secondary_arts_teacher: ["all", "teacher", "secondary_teacher", "secondary_arts_teacher"],
    counselor_teacher: ["all", "teacher"],
    health_teacher: ["all", "teacher"],
    librarian_teacher: ["all", "teacher"],
    nutrition_teacher: ["all", "teacher"],

    // 행정직
    admin_9th_national: ["all", "admin", "national_admin", "admin_9th_national"],
    admin_7th_national: ["all", "admin", "national_admin", "admin_7th_national"],
    admin_5th_national: ["all", "admin", "national_admin", "admin_5th_national"],
    admin_9th_local: ["all", "admin", "local_admin", "admin_9th_local"],
    admin_7th_local: ["all", "admin", "local_admin", "admin_7th_local"],
    admin_5th_local: ["all", "admin", "local_admin", "admin_5th_local"],

    // 치안/안전
    police: ["all", "police"],
    firefighter: ["all", "firefighter"],
    coast_guard: ["all", "coast_guard"],

    // 군인
    army: ["all", "military", "army"],
    navy: ["all", "military", "navy"],
    air_force: ["all", "military", "air_force"],

    // 기타
    postal_service: ["all", "postal_service"],
    legal_correction: ["all", "legal_correction"],
    security_protection: ["all", "security_protection"],
    diplomatic_international: ["all", "diplomatic_international"],
    independent_agencies: ["all", "independent_agencies"],

    // 일반적인 분류 (fallback)
    teacher: ["all", "teacher"],
    admin: ["all", "admin"],
  };

  return careerToLoungeMapping[careerTrack] || ["all"];
}

/**
 * Get default lounge ID from career hierarchy
 */
function getDefaultLoungeId(careerHierarchy: any): string {
  // 가장 구체적인 레벨부터 확인
  if (careerHierarchy.level4) {
    return careerHierarchy.level4;
  }
  if (careerHierarchy.level3) {
    return careerHierarchy.level3;
  }
  if (careerHierarchy.level2) {
    return careerHierarchy.level2;
  }
  return "all";
}

async function markVerification(path: string, result: VerificationResult) {
  const db = getFirestore();

  await db.doc(path).set(
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

  // 인증 성공 시 사용자 프로필 업데이트
  if (result.status === "verified" && result.detectedTrack) {
    try {
      // path에서 userId 추출: users/{userId}/verifications/paystub
      const pathParts = path.split("/");
      if (pathParts.length >= 2 && pathParts[0] === "users") {
        const userId = pathParts[1];

        const careerHierarchy = generateCareerHierarchy(result.detectedTrack);
        const accessibleLoungeIds = getLoungeIdsFromCareer(result.detectedTrack);
        const defaultLoungeId = getDefaultLoungeId(careerHierarchy);

        await db.collection("users").doc(userId).update({
          // 기존 필드
          careerTrack: result.detectedTrack,
          careerTrackVerifiedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),

          // 새로운 계층적 라운지 시스템
          careerHierarchy: careerHierarchy,
          accessibleLoungeIds: accessibleLoungeIds,
          defaultLoungeId: defaultLoungeId,

          // 검증 상태
          careerVerificationStatus: "verified",
          careerVerificationMethod: "paystub",
        });

        console.log(`Updated user profile for ${userId}`, {
          careerTrack: result.detectedTrack,
          accessibleLoungeIds,
          defaultLoungeId,
        });
      }
    } catch (error) {
      console.error("Failed to update user profile after verification", {
        error: error instanceof Error ? error.message : String(error),
        path,
        detectedTrack: result.detectedTrack,
      });
      // 사용자 프로필 업데이트 실패는 verification 자체의 실패로 처리하지 않음
    }
  }
}
