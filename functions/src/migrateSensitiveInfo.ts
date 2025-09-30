import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getFirestore, FieldValue} from "firebase-admin/firestore";

const db = getFirestore();

/**
 * 🔒 민감 정보 마이그레이션 Cloud Function
 *
 * 기존 users 컬렉션의 governmentEmail, primaryEmail을
 * users/{uid}/private/sensitive 서브컬렉션으로 이동
 *
 * 호출 방법:
 * - 본인 데이터만: migrateMyData()
 * - 전체 마이그레이션 (관리자만): migrateAllUsers()
 */

/**
 * 본인의 민감 정보만 마이그레이션
 */
export const migrateMyData = onCall(
  {region: "us-central1"},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "로그인이 필요합니다");
    }

    try {
      const userDoc = await db.collection("users").doc(uid).get();
      if (!userDoc.exists) {
        throw new HttpsError("not-found", "사용자 정보를 찾을 수 없습니다");
      }

      const userData = userDoc.data();
      if (!userData) {
        throw new HttpsError("not-found", "사용자 데이터가 비어있습니다");
      }
      const governmentEmail = userData.governmentEmail as string | undefined;
      const primaryEmail = userData.primaryEmail as string | undefined;

      // 이미 마이그레이션 되었는지 확인
      const sensitiveDoc = await db
        .collection("users")
        .doc(uid)
        .collection("private")
        .doc("sensitive")
        .get();

      if (sensitiveDoc.exists) {
        return {
          success: true,
          message: "이미 마이그레이션 완료됨",
          migrated: false,
        };
      }

      // 민감 정보가 있으면 이동
      if (governmentEmail || primaryEmail) {
        await db
          .collection("users")
          .doc(uid)
          .collection("private")
          .doc("sensitive")
          .set({
            governmentEmail: governmentEmail || null,
            primaryEmail: primaryEmail || null,
            phone: null,
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
            migratedAt: FieldValue.serverTimestamp(),
          });

        console.log(`Migrated sensitive data for user ${uid}`);

        return {
          success: true,
          message: "민감 정보가 안전하게 이동되었습니다",
          migrated: true,
          migratedFields: {
            governmentEmail: !!governmentEmail,
            primaryEmail: !!primaryEmail,
          },
        };
      }

      return {
        success: true,
        message: "마이그레이션할 민감 정보가 없습니다",
        migrated: false,
      };
    } catch (error) {
      console.error(`Migration failed for user ${uid}:`, error);
      throw new HttpsError(
        "internal",
        "마이그레이션 중 오류가 발생했습니다"
      );
    }
  }
);

/**
 * 전체 사용자 마이그레이션 (관리자 전용)
 */
export const migrateAllUsers = onCall(
  {region: "us-central1", timeoutSeconds: 540},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "로그인이 필요합니다");
    }

    // 관리자 권한 확인
    const userDoc = await db.collection("users").doc(uid).get();
    const userData = userDoc.data();
    if (userData?.role !== "admin") {
      throw new HttpsError(
        "permission-denied",
        "관리자 권한이 필요합니다"
      );
    }

    try {
      const usersSnapshot = await db.collection("users").get();
      let migratedCount = 0;
      let skippedCount = 0;
      let noDataCount = 0;

      console.log(`Starting migration for ${usersSnapshot.size} users`);

      for (const userDoc of usersSnapshot.docs) {
        const uid = userDoc.id;
        const userData = userDoc.data();
        const governmentEmail = userData.governmentEmail as string | undefined;
        const primaryEmail = userData.primaryEmail as string | undefined;

        // 이미 마이그레이션 되었는지 확인
        const sensitiveDoc = await db
          .collection("users")
          .doc(uid)
          .collection("private")
          .doc("sensitive")
          .get();

        if (sensitiveDoc.exists) {
          skippedCount++;
          continue;
        }

        // 민감 정보가 있으면 이동
        if (governmentEmail || primaryEmail) {
          await db
            .collection("users")
            .doc(uid)
            .collection("private")
            .doc("sensitive")
            .set({
              governmentEmail: governmentEmail || null,
              primaryEmail: primaryEmail || null,
              phone: null,
              createdAt: FieldValue.serverTimestamp(),
              updatedAt: FieldValue.serverTimestamp(),
              migratedAt: FieldValue.serverTimestamp(),
            });

          migratedCount++;
          console.log(`✅ Migrated user ${uid}`);
        } else {
          noDataCount++;
        }
      }

      const message =
        "마이그레이션 완료!\n" +
        `- 총 사용자: ${usersSnapshot.size}명\n` +
        `- 마이그레이션: ${migratedCount}명\n` +
        `- 이미 완료: ${skippedCount}명\n` +
        `- 데이터 없음: ${noDataCount}명`;

      console.log(message);

      return {
        success: true,
        totalProcessed: usersSnapshot.size,
        migratedCount,
        skippedCount,
        noDataCount,
        message,
      };
    } catch (error) {
      console.error("Bulk migration failed:", error);
      throw new HttpsError(
        "internal",
        `마이그레이션 중 오류: ${error}`
      );
    }
  }
);
