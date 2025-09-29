import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onRequest} from "firebase-functions/v2/https";
import {getFirestore} from "firebase-admin/firestore";
import {logger} from "firebase-functions/v2";
import {sendVerificationEmail, isEmailSendingSupported} from "./emailService";

const db = getFirestore();

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

    logger.info(`Sending verification email to ${email}`, {
      userId,
      token: token.substring(0, 8) + "...",
      expiresAt: expiresAt.toDate(),
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
        });
      } else {
        logger.error(`Failed to send verification email to ${email}`, {
          userId,
          token: token.substring(0, 8) + "...",
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
  },
  async (req, res) => {
    // Only allow GET requests
    if (req.method !== "GET") {
      res.status(405).json({error: "Method not allowed"});
      return;
    }

    const token = req.query.token as string;
    if (!token) {
      res.status(400).json({error: "Token parameter is required"});
      return;
    }

    try {
      // Look up the verification token
      const tokenDoc = await db.collection("government_email_verification_tokens")
        .doc(token)
        .get();

      if (!tokenDoc.exists) {
        logger.warn(`Token not found: ${token.substring(0, 8)}...`);
        res.status(404).json({error: "Invalid or expired token"});
        return;
      }

      const tokenData = tokenDoc.data()!;
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
        res.status(200).json({
          success: true,
          message: "이메일이 이미 인증되었습니다.",
          email,
        });
        return;
      }

      // Check if expired
      const now = new Date();
      if (expiresAt.toDate() <= now) {
        logger.warn(`Token expired: ${token.substring(0, 8)}...`);
        res.status(400).json({error: "Token has expired"});
        return;
      }

      // Mark token as verified
      await tokenDoc.ref.update({
        verifiedAt: now,
      });

      // Update government email claim to verified
      const normalizedEmail = email.trim().toLowerCase();
      const emailDocId = Buffer.from(normalizedEmail, "utf8").toString("base64url");

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

      logger.info(`Email verification completed successfully`, {
        email,
        userId,
        token: token.substring(0, 8) + "...",
      });

      // Return success response or redirect to app
      res.status(200).json({
        success: true,
        message: "이메일 인증이 완료되었습니다.",
        email,
      });

    } catch (error) {
      logger.error("Error verifying email token", {
        error: error instanceof Error ? error.message : String(error),
        token: token.substring(0, 8) + "...",
      });

      res.status(500).json({error: "Internal server error"});
    }
  }
);