import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onRequest} from "firebase-functions/v2/https";
import {getFirestore} from "firebase-admin/firestore";
import {logger} from "firebase-functions/v2";
import {sendVerificationEmail, isEmailSendingSupported} from "./emailService";

const db = getFirestore();

/**
 * Generate HTML response for email verification
 * @param {string} title The page title
 * @param {string} message The message to display
 * @param {boolean} success Whether the operation was successful
 * @return {string} HTML response string
 */
function generateHtmlResponse(
  title: string,
  message: string,
  success: boolean
): string {
  const statusColor = success ? "#10b981" : "#ef4444";
  const statusIcon = success ? "✓" : "✗";

  return `
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${title} - 공무톡</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI',
                         system-ui, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f9fafb;
            color: #374151;
            line-height: 1.6;
        }
        .container {
            max-width: 400px;
            margin: 50px auto;
            background: white;
            padding: 40px;
            border-radius: 12px;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
            text-align: center;
        }
        .status-icon {
            width: 64px;
            height: 64px;
            border-radius: 50%;
            background-color: ${statusColor};
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 32px;
            font-weight: bold;
            margin: 0 auto 20px;
        }
        .title {
            font-size: 24px;
            font-weight: bold;
            color: #1f2937;
            margin-bottom: 12px;
        }
        .message {
            font-size: 16px;
            color: #6b7280;
            margin-bottom: 30px;
        }
        .app-name {
            font-size: 14px;
            color: #9ca3af;
            border-top: 1px solid #e5e7eb;
            padding-top: 20px;
            margin-top: 20px;
        }
        .close-instruction {
            font-size: 14px;
            color: #9ca3af;
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="status-icon">${statusIcon}</div>
        <div class="title">${title}</div>
        <div class="message">${message}</div>
        <div class="app-name">공무톡 (GongMuTalk)</div>
        <div class="close-instruction">이 창을 닫아주세요.</div>
    </div>
</body>
</html>
  `.trim();
}

/**
 * Triggered when a new government email verification token is created
 * Automatically sends verification email for supported domains (@naver.com)
 */
export const sendGovernmentEmailVerification = onDocumentCreated(
  {
    document: "government_email_verification_tokens/{tokenId}",
    region: "us-central1",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.error("No data in verification token creation event");
      return;
    }

    const tokenData = snapshot.data();
    if (!tokenData) {
      logger.error("No token data found");
      return;
    }

    const {
      token,
      email,
      userId,
      expiresAt,
    } = tokenData as {
      token: string;
      email: string;
      userId: string;
      expiresAt: FirebaseFirestore.Timestamp;
    };

    // Only send actual emails for supported domains
    if (!isEmailSendingSupported(email)) {
      logger.info(`Email sending not supported for domain: ${email}`);
      return;
    }

    // Check if token is already expired
    const now = new Date();
    if (expiresAt.toDate() <= now) {
      logger.warn(`Token already expired for ${email}`, {
        token: token.substring(0, 8) + "...",
        expiresAt: expiresAt.toDate(),
        now,
      });
      return;
    }

    // 도메인 추출 및 분류
    const emailDomain = email.substring(email.indexOf("@"));
    const domainType = emailDomain === "@korea.kr" ? "korea_kr" :
      emailDomain === "@naver.com" ? "naver_com" :
        emailDomain.endsWith(".go.kr") ? "go_kr" :
          emailDomain.endsWith(".kr") ? "local_gov_kr" : "other";

    logger.info(`Sending verification email to ${email}`, {
      userId,
      token: token.substring(0, 8) + "...",
      expiresAt: expiresAt.toDate(),
      emailDomain,
      domainType,
    });

    try {
      const success = await sendVerificationEmail({
        to: email,
        token: token,
        appName: "공무톡",
      });

      if (success) {
        // Update the token document to mark email as sent
        await snapshot.ref.update({
          emailSent: true,
          emailSentAt: new Date(),
        });

        logger.info(`Verification email sent successfully to ${email}`, {
          userId,
          token: token.substring(0, 8) + "...",
          emailDomain,
          domainType,
          success: true,
        });
      } else {
        logger.error(`Failed to send verification email to ${email}`, {
          userId,
          token: token.substring(0, 8) + "...",
          emailDomain,
          domainType,
          success: false,
        });

        // Update the token document to mark email sending as failed
        await snapshot.ref.update({
          emailSent: false,
          emailSentAt: new Date(),
          emailError: "Failed to send email",
        });
      }
    } catch (error) {
      logger.error("Error in email verification process", {
        error: error instanceof Error ? error.message : String(error),
        email,
        userId,
        token: token.substring(0, 8) + "...",
      });

      // Update the token document to mark email sending as failed
      await snapshot.ref.update({
        emailSent: false,
        emailSentAt: new Date(),
        emailError: error instanceof Error ? error.message : String(error),
      });
    }
  }
);

/**
 * HTTP endpoint for email verification
 * This handles the verification link clicks
 */
export const verifyEmailToken = onRequest(
  {
    region: "us-central1",
    cors: true,
    invoker: "public",
  },
  async (req, res) => {
    // Set CORS headers
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET");
    res.set("Access-Control-Allow-Headers", "Content-Type");

    // Only allow GET requests
    if (req.method !== "GET") {
      res.status(405).send(generateHtmlResponse(
        "오류",
        "잘못된 요청 방식입니다.",
        false
      ));
      return;
    }

    const token = req.query.token as string;
    if (!token) {
      res.status(400).send(generateHtmlResponse(
        "오류",
        "인증 토큰이 필요합니다.",
        false
      ));
      return;
    }

    try {
      // Look up the verification token
      const tokenDoc =
        await db.collection("government_email_verification_tokens")
          .doc(token)
          .get();

      if (!tokenDoc.exists) {
        logger.warn(`Token not found: ${token.substring(0, 8)}...`);
        res.status(404).send(generateHtmlResponse(
          "인증 실패",
          "유효하지 않거나 만료된 인증 토큰입니다.",
          false
        ));
        return;
      }

      const tokenData = tokenDoc.data();
      const {
        email,
        userId,
        expiresAt,
        verifiedAt,
      } = tokenData as {
        email: string;
        userId: string;
        expiresAt: FirebaseFirestore.Timestamp;
        verifiedAt?: FirebaseFirestore.Timestamp;
      };

      // Check if already verified
      if (verifiedAt) {
        logger.info(`Token already verified: ${token.substring(0, 8)}...`);
        res.status(200).send(generateHtmlResponse(
          "인증 완료",
          "이메일이 이미 인증되었습니다.",
          true
        ));
        return;
      }

      // Check if expired
      const now = new Date();
      if (expiresAt.toDate() <= now) {
        logger.warn(`Token expired: ${token.substring(0, 8)}...`);
        res.status(400).send(generateHtmlResponse(
          "인증 실패",
          "인증 토큰이 만료되었습니다. 새로운 인증 요청을 해주세요.",
          false
        ));
        return;
      }

      // Mark token as verified
      await tokenDoc.ref.update({
        verifiedAt: now,
      });

      // Update government email claim to verified
      const normalizedEmail = email.trim().toLowerCase();
      const emailDocId =
        Buffer.from(normalizedEmail, "utf8").toString("base64url");

      await db.collection("government_email_index").doc(emailDocId).set({
        email: normalizedEmail,
        userId: userId,
        status: "verified",
        verifiedAt: now,
        updatedAt: now,
      }, {merge: true});

      // Update user profile with government email
      await db.collection("users").doc(userId).update({
        governmentEmail: normalizedEmail,
        governmentEmailVerifiedAt: now,
        updatedAt: now,
      });

      // 도메인 분석 및 분류
      const emailDomain = email.substring(email.indexOf("@"));
      const domainType = emailDomain === "@korea.kr" ? "korea_kr" :
        emailDomain === "@naver.com" ? "naver_com" :
          emailDomain.endsWith(".go.kr") ? "go_kr" :
            emailDomain.endsWith(".kr") ? "local_gov_kr" : "other";

      logger.info("Email verification completed successfully", {
        email,
        userId,
        token: token.substring(0, 8) + "...",
        emailDomain,
        domainType,
        verificationSuccess: true,
      });

      // Return success response
      res.status(200).send(generateHtmlResponse(
        "인증 완료",
        `공무원 이메일 인증이 완료되었습니다. (${email})`,
        true
      ));
    } catch (error) {
      logger.error("Error verifying email token", {
        error: error instanceof Error ? error.message : String(error),
        token: token.substring(0, 8) + "...",
      });

      res.status(500).send(generateHtmlResponse(
        "서버 오류",
        "인증 처리 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.",
        false
      ));
    }
  }
);
