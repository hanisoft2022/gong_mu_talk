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
  // ================================
  // 교육공무원 (Education Officials)
  // ================================

  // 중등교사 - 교과별 (Priority 10)
  {
    track: "secondary_math_teacher",
    keywords: ["교사(중등)", "중등교사", "중등", "수학"],
    institutionKeywords: ["중학교", "고등학교", "중·고등학교"],
    priority: 10,
  },
  {
    track: "secondary_korean_teacher",
    keywords: ["교사(중등)", "중등교사", "중등", "국어"],
    institutionKeywords: ["중학교", "고등학교", "중·고등학교"],
    priority: 10,
  },
  {
    track: "secondary_english_teacher",
    keywords: ["교사(중등)", "중등교사", "중등", "영어"],
    institutionKeywords: ["중학교", "고등학교", "중·고등학교"],
    priority: 10,
  },
  {
    track: "secondary_science_teacher",
    keywords: ["교사(중등)", "중등교사", "중등", "과학", "물리", "화학", "생물", "지구과학"],
    institutionKeywords: ["중학교", "고등학교", "중·고등학교"],
    priority: 10,
  },
  {
    track: "secondary_social_teacher",
    keywords: ["교사(중등)", "중등교사", "중등", "사회", "역사", "지리", "도덕", "윤리"],
    institutionKeywords: ["중학교", "고등학교", "중·고등학교"],
    priority: 10,
  },
  {
    track: "secondary_arts_teacher",
    keywords: ["교사(중등)", "중등교사", "중등", "체육", "음악", "미술", "기술", "가정", "한문", "제2외국어"],
    institutionKeywords: ["중학교", "고등학교", "중·고등학교"],
    priority: 10,
  },

  // 초등교사 (Priority 10)
  {
    track: "elementary_teacher",
    keywords: ["교사(초등)", "초등교사", "초등"],
    institutionKeywords: ["초등학교"],
    priority: 10,
  },

  // 유치원교사 (Priority 10)
  {
    track: "kindergarten_teacher",
    keywords: ["교사(유치원)", "유치원교사", "유아교사"],
    institutionKeywords: ["유치원"],
    priority: 10,
  },

  // 특수교육교사 (Priority 10)
  {
    track: "special_education_teacher",
    keywords: ["특수교사", "특수교육교사", "특수교육"],
    institutionKeywords: ["특수학교", "학교"],
    priority: 10,
  },

  // 비교과교사 (Priority 9)
  {
    track: "counselor_teacher",
    keywords: ["상담교사", "전문상담교사", "상담"],
    institutionKeywords: ["학교", "초등학교", "중학교", "고등학교"],
    priority: 9,
  },
  {
    track: "health_teacher",
    keywords: ["보건교사", "보건"],
    institutionKeywords: ["학교", "초등학교", "중학교", "고등학교"],
    priority: 9,
  },
  {
    track: "librarian_teacher",
    keywords: ["사서교사", "사서"],
    institutionKeywords: ["학교", "초등학교", "중학교", "고등학교"],
    priority: 9,
  },
  {
    track: "nutrition_teacher",
    keywords: ["영양교사", "영양"],
    institutionKeywords: ["학교", "초등학교", "중학교", "고등학교"],
    priority: 9,
  },

  // 교육행정직 (Priority 8)
  {
    track: "education_admin",
    keywords: ["교육행정", "교육공무원", "교육전문직"],
    institutionKeywords: ["교육청", "교육지원청", "교육부"],
    priority: 8,
  },

  // ================================
  // 일반행정직 (Administrative)
  // ================================

  // 국가행정직 - 직급별 (Priority 9)
  {
    track: "admin_9th_national",
    keywords: ["9급", "서기보", "행정", "국가직", "일반행정"],
    institutionKeywords: ["부", "청", "처", "원", "국"],
    priority: 9,
  },
  {
    track: "admin_7th_national",
    keywords: ["7급", "주사보", "행정", "국가직", "일반행정"],
    institutionKeywords: ["부", "청", "처", "원", "국"],
    priority: 9,
  },
  {
    track: "admin_5th_national",
    keywords: ["5급", "사무관", "행정관", "국가직", "일반행정"],
    institutionKeywords: ["부", "청", "처", "원", "국"],
    priority: 9,
  },

  // 지방행정직 - 직급별 (Priority 9)
  {
    track: "admin_9th_local",
    keywords: ["9급", "서기보", "행정", "지방직", "일반행정"],
    institutionKeywords: ["시청", "구청", "도청", "군청", "읍사무소", "면사무소"],
    priority: 9,
  },
  {
    track: "admin_7th_local",
    keywords: ["7급", "주사보", "행정", "지방직", "일반행정"],
    institutionKeywords: ["시청", "구청", "도청", "군청", "읍사무소", "면사무소"],
    priority: 9,
  },
  {
    track: "admin_5th_local",
    keywords: ["5급", "사무관", "행정관", "지방직", "일반행정"],
    institutionKeywords: ["시청", "구청", "도청", "군청"],
    priority: 9,
  },

  // 세무직 (Priority 8)
  {
    track: "tax_official",
    keywords: ["세무직", "세무", "세무서기", "세무주사", "국세"],
    institutionKeywords: ["세무서", "국세청", "지방국세청"],
    priority: 8,
  },

  // 관세직 (Priority 8)
  {
    track: "customs_official",
    keywords: ["관세직", "관세", "관세서기", "관세주사"],
    institutionKeywords: ["세관", "관세청", "공항", "항만"],
    priority: 8,
  },

  // ================================
  // 전문행정직 (Specialized Administrative)
  // ================================

  {
    track: "job_counselor",
    keywords: ["직업상담직", "직업상담", "고용노동"],
    institutionKeywords: ["고용센터", "고용노동부", "워크넷"],
    priority: 7,
  },
  {
    track: "statistics_officer",
    keywords: ["통계직", "통계", "통계서기", "통계주사"],
    institutionKeywords: ["통계청"],
    priority: 7,
  },
  {
    track: "librarian",
    keywords: ["사서직", "사서", "도서관"],
    institutionKeywords: ["도서관", "국립도서관"],
    priority: 7,
  },
  {
    track: "auditor",
    keywords: ["감사직", "감사", "감사관"],
    institutionKeywords: ["감사원", "시청", "도청"],
    priority: 7,
  },
  {
    track: "security_officer",
    keywords: ["방호직", "방호", "시설관리"],
    institutionKeywords: ["청사", "청"],
    priority: 7,
  },

  // ================================
  // 보건복지직 (Health & Welfare)
  // ================================

  {
    track: "public_health_officer",
    keywords: ["보건직", "보건", "보건서기", "보건주사"],
    institutionKeywords: ["보건소", "보건복지부", "시청", "구청"],
    priority: 7,
  },
  {
    track: "medical_technician",
    keywords: ["의료기술직", "의료기술", "방사선사", "임상병리사", "물리치료사"],
    institutionKeywords: ["보건소", "병원", "의료원"],
    priority: 7,
  },
  {
    track: "nurse",
    keywords: ["간호직", "간호", "간호사"],
    institutionKeywords: ["보건소", "병원", "의료원"],
    priority: 7,
  },
  {
    track: "medical_officer",
    keywords: ["의무직", "의사", "의무관"],
    institutionKeywords: ["보건소", "병원", "의료원"],
    priority: 7,
  },
  {
    track: "pharmacist",
    keywords: ["약무직", "약사"],
    institutionKeywords: ["보건소", "병원", "의료원"],
    priority: 7,
  },
  {
    track: "food_sanitation",
    keywords: ["식품위생직", "식품위생", "위생"],
    institutionKeywords: ["보건소", "시청", "구청"],
    priority: 7,
  },
  {
    track: "social_worker",
    keywords: ["사회복지직", "사회복지", "복지", "사회복지사"],
    institutionKeywords: ["구청", "시청", "복지관", "주민센터"],
    priority: 7,
  },

  // ================================
  // 공안직 (Public Security)
  // ================================

  {
    track: "correction_officer",
    keywords: ["교정직", "교정", "교도관", "교정서기", "교정주사"],
    institutionKeywords: ["교도소", "구치소", "교정청", "법무부"],
    priority: 8,
  },
  {
    track: "probation_officer",
    keywords: ["보호직", "보호관찰", "보호관찰관"],
    institutionKeywords: ["보호관찰소", "법무부"],
    priority: 8,
  },
  {
    track: "prosecution_officer",
    keywords: ["검찰직", "검찰", "검찰서기", "검찰주사"],
    institutionKeywords: ["검찰청", "지방검찰청", "고등검찰청"],
    priority: 8,
  },
  {
    track: "drug_investigation_officer",
    keywords: ["마약수사직", "마약수사", "마약"],
    institutionKeywords: ["검찰청", "경찰청"],
    priority: 8,
  },
  {
    track: "immigration_officer",
    keywords: ["출입국관리직", "출입국", "출입국관리"],
    institutionKeywords: ["출입국관리사무소", "출입국·외국인청", "법무부"],
    priority: 8,
  },
  {
    track: "railroad_police",
    keywords: ["철도경찰직", "철도경찰", "철도"],
    institutionKeywords: ["철도경찰대", "국토교통부"],
    priority: 8,
  },
  {
    track: "security_guard",
    keywords: ["경위직", "경비", "경호"],
    institutionKeywords: ["국회", "법원", "헌법재판소"],
    priority: 8,
  },

  // ================================
  // 치안/안전 (Public Safety)
  // ================================

  {
    track: "police",
    keywords: ["경찰관", "경찰", "경사", "경위", "경감", "경정", "순경", "경장"],
    institutionKeywords: ["경찰서", "지방경찰청", "경찰청"],
    priority: 8,
  },
  {
    track: "firefighter",
    keywords: ["소방관", "소방", "소방사", "소방교", "소방장", "소방위", "소방경"],
    institutionKeywords: ["소방서", "소방본부", "소방청"],
    priority: 8,
  },
  {
    track: "coast_guard",
    keywords: ["해양경찰", "해경", "해양경비"],
    institutionKeywords: ["해양경찰서", "해양경찰청"],
    priority: 8,
  },

  // ================================
  // 군인 (Military)
  // ================================

  {
    track: "army",
    keywords: ["육군", "장교", "부사관", "병사", "하사", "중사", "상사", "소위", "중위", "대위"],
    institutionKeywords: ["사단", "연대", "대대", "여단"],
    priority: 7,
  },
  {
    track: "navy",
    keywords: ["해군", "장교", "부사관", "병사", "수병", "하사", "중사"],
    institutionKeywords: ["함대", "전단", "해군"],
    priority: 7,
  },
  {
    track: "air_force",
    keywords: ["공군", "장교", "부사관", "병사", "하사", "중사"],
    institutionKeywords: ["비행단", "전투비행단", "공군"],
    priority: 7,
  },
  {
    track: "military_civilian",
    keywords: ["군무원", "국방", "군무"],
    institutionKeywords: ["국방부", "사단", "부대"],
    priority: 7,
  },

  // ================================
  // 공업직 (Industrial/Engineering)
  // ================================

  {
    track: "mechanical_engineer",
    keywords: ["기계직", "기계", "기계서기", "기계주사", "일반기계"],
    institutionKeywords: ["시청", "도청", "공단", "연구소"],
    priority: 6,
  },
  {
    track: "electrical_engineer",
    keywords: ["전기직", "전기", "전기서기", "전기주사"],
    institutionKeywords: ["시청", "도청", "공단", "한국전력"],
    priority: 6,
  },
  {
    track: "electronics_engineer",
    keywords: ["전자직", "전자", "전자서기", "전자주사"],
    institutionKeywords: ["시청", "도청", "연구소"],
    priority: 6,
  },
  {
    track: "chemical_engineer",
    keywords: ["화공직", "화공", "화학", "화공서기"],
    institutionKeywords: ["시청", "도청", "연구소", "환경"],
    priority: 6,
  },
  {
    track: "shipbuilding_engineer",
    keywords: ["조선직", "조선", "선박"],
    institutionKeywords: ["해양", "항만", "조선소"],
    priority: 6,
  },
  {
    track: "nuclear_engineer",
    keywords: ["원자력직", "원자력", "방사선"],
    institutionKeywords: ["원자력안전위원회", "원자력", "발전소"],
    priority: 6,
  },
  {
    track: "metal_engineer",
    keywords: ["금속직", "금속", "재료"],
    institutionKeywords: ["연구소", "시청"],
    priority: 6,
  },
  {
    track: "textile_engineer",
    keywords: ["섬유직", "섬유"],
    institutionKeywords: ["연구소", "시청"],
    priority: 6,
  },

  // ================================
  // 시설환경직 (Facilities & Environment)
  // ================================

  {
    track: "civil_engineer",
    keywords: ["토목직", "토목", "토목서기", "토목주사"],
    institutionKeywords: ["시청", "도청", "국토부", "도로", "건설"],
    priority: 6,
  },
  {
    track: "architect",
    keywords: ["건축직", "건축", "건축서기", "건축주사"],
    institutionKeywords: ["시청", "도청", "국토부"],
    priority: 6,
  },
  {
    track: "landscape_architect",
    keywords: ["조경직", "조경", "조경서기"],
    institutionKeywords: ["시청", "도청", "공원"],
    priority: 6,
  },
  {
    track: "traffic_engineer",
    keywords: ["교통직", "교통", "교통서기"],
    institutionKeywords: ["시청", "도청", "국토부"],
    priority: 6,
  },
  {
    track: "cadastral_officer",
    keywords: ["지적직", "지적", "지적서기"],
    institutionKeywords: ["시청", "구청", "국토부"],
    priority: 6,
  },
  {
    track: "designer",
    keywords: ["디자인직", "디자인"],
    institutionKeywords: ["시청", "도청"],
    priority: 6,
  },
  {
    track: "environmental_officer",
    keywords: ["환경직", "환경", "환경서기", "환경주사"],
    institutionKeywords: ["환경부", "시청", "도청", "환경청"],
    priority: 6,
  },

  // ================================
  // 농림수산직 (Agriculture, Forestry, Fisheries)
  // ================================

  {
    track: "agriculture_officer",
    keywords: ["농업직", "농업", "농촌지도", "농업서기"],
    institutionKeywords: ["농업기술센터", "농림축산식품부", "시청", "도청"],
    priority: 6,
  },
  {
    track: "plant_quarantine",
    keywords: ["식물검역직", "식물검역", "검역"],
    institutionKeywords: ["검역소", "농림축산검역본부", "공항", "항만"],
    priority: 6,
  },
  {
    track: "livestock_officer",
    keywords: ["축산직", "축산", "가축"],
    institutionKeywords: ["축산기술센터", "농림축산식품부", "시청"],
    priority: 6,
  },
  {
    track: "forestry_officer",
    keywords: ["임업직", "산림", "산림자원", "산림보호"],
    institutionKeywords: ["산림청", "국립산림과학원", "시청", "도청"],
    priority: 6,
  },
  {
    track: "marine_officer",
    keywords: ["해양직", "해양", "해양수산"],
    institutionKeywords: ["해양수산부", "해양경찰청", "수산청"],
    priority: 6,
  },
  {
    track: "fisheries_officer",
    keywords: ["수산직", "수산", "어업"],
    institutionKeywords: ["해양수산부", "수협", "시청"],
    priority: 6,
  },
  {
    track: "ship_officer",
    keywords: ["선박직", "선박", "항해", "기관"],
    institutionKeywords: ["해양수산부", "항만청", "선박"],
    priority: 6,
  },
  {
    track: "veterinarian",
    keywords: ["수의직", "수의", "수의사"],
    institutionKeywords: ["시청", "도청", "보건소", "가축위생시험소"],
    priority: 6,
  },
  {
    track: "agricultural_extension",
    keywords: ["지도직", "농촌지도사", "지도사"],
    institutionKeywords: ["농업기술센터", "농촌진흥청"],
    priority: 6,
  },

  // ================================
  // IT통신직 (IT & Communications)
  // ================================

  {
    track: "computer_officer",
    keywords: ["전산직", "전산", "정보", "컴퓨터", "전산서기"],
    institutionKeywords: ["시청", "도청", "정보화", "정보통신"],
    priority: 6,
  },
  {
    track: "broadcasting_communication",
    keywords: ["방송통신직", "방송통신", "통신", "방송"],
    institutionKeywords: ["방송통신위원회", "KBS", "시청"],
    priority: 6,
  },

  // ================================
  // 관리운영직 (Management & Operations)
  // ================================

  {
    track: "facility_management",
    keywords: ["관리운영직", "시설관리", "운영", "관리"],
    institutionKeywords: ["시청", "도청", "청사"],
    priority: 6,
  },
  {
    track: "sanitation_worker",
    keywords: ["위생직", "위생", "청소"],
    institutionKeywords: ["시청", "구청", "환경"],
    priority: 6,
  },
  {
    track: "cook",
    keywords: ["조리직", "조리", "급식"],
    institutionKeywords: ["학교", "청사", "복지관"],
    priority: 6,
  },

  // ================================
  // 기타 직렬 (Others)
  // ================================

  {
    track: "postal_service",
    keywords: ["우정직", "우정", "집배원", "우체국"],
    institutionKeywords: ["우체국", "우정사업본부"],
    priority: 6,
  },
  {
    track: "researcher",
    keywords: ["연구직", "연구", "연구사", "연구관"],
    institutionKeywords: ["연구소", "연구원", "과학기술"],
    priority: 6,
  },

  // ================================
  // Fallback - 일반 직렬 (Priority 5)
  // ================================

  {
    track: "teacher",
    keywords: ["국공립교원", "교원구분", "교사", "교원"],
    institutionKeywords: ["학교"],
    priority: 5,
  },
  {
    track: "admin",
    keywords: ["행정직", "행정공무원", "일반행정"],
    institutionKeywords: [],
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

  console.log("Career detection results:", {
    totalCandidates: candidates.length,
    bestMatch: {
      track: bestMatch.track,
      score: bestMatch.score,
      priority: bestMatch.priority,
      keywords: bestMatch.matchedKeywords,
    },
    allCandidates: candidates.map((c) => ({
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
 * Generate career hierarchy from detected track
 *
 * @param {string} careerTrack The detected career track identifier.
 * @return {object} Career hierarchy object with level structure.
 */
function generateCareerHierarchy(
  careerTrack: string
): Record<string, string> {
  switch (careerTrack) {
  // ================================
  // 교육공무원 (Education Officials)
  // ================================

  // 초등교사 (Elementary Teacher)
  case "elementary_teacher":
    return {
      specificCareer: "elementary_teacher",
      level1: "all",
      level2: "teacher",
      level3: "elementary_teacher",
    };

  // 중등교사 - 교과별 (Secondary Teachers by Subject)
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

  // 유치원 교사 (Kindergarten Teacher)
  case "kindergarten_teacher":
    return {
      specificCareer: "kindergarten_teacher",
      level1: "all",
      level2: "teacher",
      level3: "kindergarten_teacher",
    };

  // 특수교육 교사 (Special Education Teacher)
  case "special_education_teacher":
    return {
      specificCareer: "special_education_teacher",
      level1: "all",
      level2: "teacher",
      level3: "special_education_teacher",
    };

  // 비교과 교사들 (Non-Subject Teachers) - 통합 라운지
  case "counselor_teacher":
  case "health_teacher":
  case "librarian_teacher":
  case "nutrition_teacher":
    return {
      specificCareer: careerTrack,
      level1: "all",
      level2: "teacher",
      level3: "non_subject_teacher",
    };

  // ================================
  // 일반행정직 (General Administrative)
  // ================================

  // 국가직 (National)
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

  // 지방직 (Local)
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

  // 세무·관세직 (Tax & Customs) - 통합 라운지
  case "tax_officer":
  case "customs_officer":
    return {
      specificCareer: careerTrack,
      level1: "all",
      level2: "admin",
      level3: "tax_customs",
    };

  // ================================
  // 전문행정직 (Specialized Administrative)
  // ================================

  case "job_counselor":
  case "statistics_officer":
  case "librarian":
  case "auditor":
  case "security_officer":
    return {
      specificCareer: careerTrack,
      level1: "all",
      level2: "admin",
      level3: "specialized_admin",
    };

  // ================================
  // 보건복지직 (Health & Welfare)
  // ================================

  case "public_health_officer":
  case "medical_technician":
  case "nurse":
  case "medical_officer":
  case "pharmacist":
  case "food_sanitation":
  case "social_worker":
    return {
      specificCareer: careerTrack,
      level1: "all",
      level2: "health_welfare",
    };

  // ================================
  // 공안직 (Public Security)
  // ================================

  case "correction_officer":
  case "probation_officer":
  case "prosecution_officer":
  case "drug_investigation_officer":
  case "immigration_officer":
  case "railroad_police":
  case "security_guard":
    return {
      specificCareer: careerTrack,
      level1: "all",
      level2: "public_security",
    };

  // ================================
  // 치안/안전 (Public Safety)
  // ================================

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

  // ================================
  // 군인 (Military)
  // ================================

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
  case "military_civilian":
    return {
      specificCareer: "military_civilian",
      level1: "all",
      level2: "military",
      level3: "military_civilian",
    };

  // ================================
  // 기술직 (Technical Tracks)
  // ================================

  // 공업직 (Industrial/Engineering) - 통합 라운지
  case "mechanical_engineer":
  case "electrical_engineer":
  case "electronics_engineer":
  case "chemical_engineer":
  case "shipbuilding_engineer":
  case "nuclear_engineer":
  case "metal_engineer":
  case "textile_engineer":
    return {
      specificCareer: careerTrack,
      level1: "all",
      level2: "technical",
      level3: "industrial_engineer",
    };

  // 시설환경직 (Facilities & Environment) - 통합 라운지
  case "civil_engineer":
  case "architect":
  case "landscape_architect":
  case "traffic_engineer":
  case "cadastral_officer":
  case "designer":
  case "environmental_officer":
    return {
      specificCareer: careerTrack,
      level1: "all",
      level2: "technical",
      level3: "facilities_environment",
    };

  // 농림수산직 (Agriculture, Forestry, Fisheries) - 통합 라운지
  case "agriculture_officer":
  case "plant_quarantine":
  case "livestock_officer":
  case "forestry_officer":
  case "marine_officer":
  case "fisheries_officer":
  case "ship_officer":
  case "veterinarian":
  case "agricultural_extension":
    return {
      specificCareer: careerTrack,
      level1: "all",
      level2: "technical",
      level3: "agriculture_forestry_fisheries",
    };

  // IT통신직 (IT & Communications) - 통합 라운지
  case "computer_officer":
  case "broadcasting_communication":
    return {
      specificCareer: careerTrack,
      level1: "all",
      level2: "technical",
      level3: "it_communications",
    };

  // 관리운영직 (Management & Operations) - 통합 라운지
  case "facility_management":
  case "sanitation_worker":
  case "cook":
    return {
      specificCareer: careerTrack,
      level1: "all",
      level2: "technical",
      level3: "management_operations",
    };

  // ================================
  // 기타 직렬 (Others)
  // ================================

  case "postal_service":
    return {
      specificCareer: "postal_service",
      level1: "all",
      level2: "postal_service",
    };
  case "researcher":
    return {
      specificCareer: "researcher",
      level1: "all",
      level2: "researcher",
    };

  // ================================
  // Fallback - 일반 직렬
  // ================================

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
    // 미분류 직렬은 "all" 라운지만 접근 가능
    return {
      specificCareer: careerTrack,
      level1: "all",
    };
  }
}

/**
 * Get accessible lounge IDs from career track
 *
 * @param {string} careerTrack The career track identifier.
 * @return {string[]} Array of accessible lounge IDs.
 */
function getLoungeIdsFromCareer(careerTrack: string): string[] {
  const careerToLoungeMapping: Record<string, string[]> = {
    // ================================
    // 교육공무원 (Education Officials)
    // ================================

    // 초등교사 (Elementary Teacher)
    elementary_teacher: ["all", "teacher", "elementary_teacher"],

    // 중등교사 - 교과별 (Secondary Teachers by Subject)
    secondary_math_teacher: [
      "all",
      "teacher",
      "secondary_teacher",
      "secondary_math_teacher",
    ],
    secondary_korean_teacher: [
      "all",
      "teacher",
      "secondary_teacher",
      "secondary_korean_teacher",
    ],
    secondary_english_teacher: [
      "all",
      "teacher",
      "secondary_teacher",
      "secondary_english_teacher",
    ],
    secondary_science_teacher: [
      "all",
      "teacher",
      "secondary_teacher",
      "secondary_science_teacher",
    ],
    secondary_social_teacher: [
      "all",
      "teacher",
      "secondary_teacher",
      "secondary_social_teacher",
    ],
    secondary_arts_teacher: [
      "all",
      "teacher",
      "secondary_teacher",
      "secondary_arts_teacher",
    ],

    // 유치원 교사 (Kindergarten Teacher)
    kindergarten_teacher: ["all", "teacher", "kindergarten_teacher"],

    // 특수교육 교사 (Special Education Teacher)
    special_education_teacher: ["all", "teacher", "special_education_teacher"],

    // 비교과 교사들 (Non-Subject Teachers) - 통합 라운지
    counselor_teacher: ["all", "teacher", "non_subject_teacher"],
    health_teacher: ["all", "teacher", "non_subject_teacher"],
    librarian_teacher: ["all", "teacher", "non_subject_teacher"],
    nutrition_teacher: ["all", "teacher", "non_subject_teacher"],

    // ================================
    // 일반행정직 (General Administrative)
    // ================================

    // 국가직 (National)
    admin_9th_national: [
      "all",
      "admin",
      "national_admin",
      "admin_9th_national",
    ],
    admin_7th_national: [
      "all",
      "admin",
      "national_admin",
      "admin_7th_national",
    ],
    admin_5th_national: [
      "all",
      "admin",
      "national_admin",
      "admin_5th_national",
    ],

    // 지방직 (Local)
    admin_9th_local: ["all", "admin", "local_admin", "admin_9th_local"],
    admin_7th_local: ["all", "admin", "local_admin", "admin_7th_local"],
    admin_5th_local: ["all", "admin", "local_admin", "admin_5th_local"],

    // 세무·관세직 (Tax & Customs) - 통합 라운지
    tax_officer: ["all", "admin", "tax_customs"],
    customs_officer: ["all", "admin", "tax_customs"],

    // ================================
    // 전문행정직 (Specialized Administrative)
    // ================================

    job_counselor: ["all", "admin", "specialized_admin"],
    statistics_officer: ["all", "admin", "specialized_admin"],
    librarian: ["all", "admin", "specialized_admin"],
    auditor: ["all", "admin", "specialized_admin"],
    security_officer: ["all", "admin", "specialized_admin"],

    // ================================
    // 보건복지직 (Health & Welfare)
    // ================================

    public_health_officer: ["all", "health_welfare"],
    medical_technician: ["all", "health_welfare"],
    nurse: ["all", "health_welfare"],
    medical_officer: ["all", "health_welfare"],
    pharmacist: ["all", "health_welfare"],
    food_sanitation: ["all", "health_welfare"],
    social_worker: ["all", "health_welfare"],

    // ================================
    // 공안직 (Public Security)
    // ================================

    correction_officer: ["all", "public_security"],
    probation_officer: ["all", "public_security"],
    prosecution_officer: ["all", "public_security"],
    drug_investigation_officer: ["all", "public_security"],
    immigration_officer: ["all", "public_security"],
    railroad_police: ["all", "public_security"],
    security_guard: ["all", "public_security"],

    // ================================
    // 치안/안전 (Public Safety)
    // ================================

    police: ["all", "police"],
    firefighter: ["all", "firefighter"],
    coast_guard: ["all", "coast_guard"],

    // ================================
    // 군인 (Military)
    // ================================

    army: ["all", "military", "army"],
    navy: ["all", "military", "navy"],
    air_force: ["all", "military", "air_force"],
    military_civilian: ["all", "military", "military_civilian"],

    // ================================
    // 기술직 (Technical Tracks)
    // ================================

    // 공업직 (Industrial/Engineering) - 통합 라운지
    mechanical_engineer: ["all", "technical", "industrial_engineer"],
    electrical_engineer: ["all", "technical", "industrial_engineer"],
    electronics_engineer: ["all", "technical", "industrial_engineer"],
    chemical_engineer: ["all", "technical", "industrial_engineer"],
    shipbuilding_engineer: ["all", "technical", "industrial_engineer"],
    nuclear_engineer: ["all", "technical", "industrial_engineer"],
    metal_engineer: ["all", "technical", "industrial_engineer"],
    textile_engineer: ["all", "technical", "industrial_engineer"],

    // 시설환경직 (Facilities & Environment) - 통합 라운지
    civil_engineer: ["all", "technical", "facilities_environment"],
    architect: ["all", "technical", "facilities_environment"],
    landscape_architect: ["all", "technical", "facilities_environment"],
    traffic_engineer: ["all", "technical", "facilities_environment"],
    cadastral_officer: ["all", "technical", "facilities_environment"],
    designer: ["all", "technical", "facilities_environment"],
    environmental_officer: ["all", "technical", "facilities_environment"],

    // 농림수산직 (Agriculture, Forestry, Fisheries) - 통합 라운지
    agriculture_officer: ["all", "technical", "agriculture_forestry_fisheries"],
    plant_quarantine: ["all", "technical", "agriculture_forestry_fisheries"],
    livestock_officer: ["all", "technical", "agriculture_forestry_fisheries"],
    forestry_officer: ["all", "technical", "agriculture_forestry_fisheries"],
    marine_officer: ["all", "technical", "agriculture_forestry_fisheries"],
    fisheries_officer: ["all", "technical", "agriculture_forestry_fisheries"],
    ship_officer: ["all", "technical", "agriculture_forestry_fisheries"],
    veterinarian: ["all", "technical", "agriculture_forestry_fisheries"],
    agricultural_extension: ["all", "technical", "agriculture_forestry_fisheries"],

    // IT통신직 (IT & Communications) - 통합 라운지
    computer_officer: ["all", "technical", "it_communications"],
    broadcasting_communication: ["all", "technical", "it_communications"],

    // 관리운영직 (Management & Operations) - 통합 라운지
    facility_management: ["all", "technical", "management_operations"],
    sanitation_worker: ["all", "technical", "management_operations"],
    cook: ["all", "technical", "management_operations"],

    // ================================
    // 기타 직렬 (Others)
    // ================================

    postal_service: ["all", "postal_service"],
    researcher: ["all", "researcher"],

    // ================================
    // Fallback - 일반 직렬
    // ================================

    teacher: ["all", "teacher"],
    admin: ["all", "admin"],
  };

  return careerToLoungeMapping[careerTrack] || ["all"];
}

/**
 * Get default lounge ID from career hierarchy
 *
 * @param {Record<string, string>} careerHierarchy Career hierarchy object.
 * @return {string} Most specific lounge ID.
 */
function getDefaultLoungeId(
  careerHierarchy: Record<string, string>
): string {
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

/**
 * Persist the verification result back to Firestore.
 *
 * @param {string} path Document path to update.
 * @param {VerificationResult} result Detection outcome payload.
 */
async function markVerification(
  path: string,
  result: VerificationResult
) {
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

        const careerHierarchy = generateCareerHierarchy(
          result.detectedTrack
        );
        const accessibleLoungeIds = getLoungeIdsFromCareer(
          result.detectedTrack
        );
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
