import * as nodemailer from "nodemailer";
import {logger} from "firebase-functions/v2";

interface EmailConfig {
  host: string;
  port: number;
  secure: boolean;
  auth: {
    user: string;
    pass: string;
  };
}

interface VerificationEmailOptions {
  to: string;
  token: string;
  appName?: string;
}

/**
 * Create a nodemailer transporter for sending emails
 * In production, you would configure this with your SMTP provider
 * For now, using a generic SMTP configuration
 * @return {nodemailer.Transporter} Email transporter
 */
function createEmailTransporter(): nodemailer.Transporter {
  // Get SMTP configuration from environment variables
  const emailConfig: EmailConfig = {
    host: process.env.SMTP_HOST || "smtp.gmail.com",
    port: parseInt(process.env.SMTP_PORT || "587"),
    secure: false, // true for 465, false for other ports
    auth: {
      user: process.env.SMTP_USER || "",
      pass: process.env.SMTP_PASS || "",
    },
  };

  if (!emailConfig.auth.user || !emailConfig.auth.pass) {
    logger.warn("SMTP credentials not configured, using test account");
    // For development/testing, we'll log the email instead of sending
    return nodemailer.createTransport({
      streamTransport: true,
      newline: "unix",
      buffer: true,
    });
  }

  return nodemailer.createTransport(emailConfig);
}

/**
 * Send a government email verification email
 * @param {VerificationEmailOptions} options - Email options
 * @return {Promise<boolean>} Success status
 */
export async function sendVerificationEmail(
  options: VerificationEmailOptions
): Promise<boolean> {
  const {to, token, appName = "공무톡"} = options;

  try {
    const transporter = createEmailTransporter();

    // Create verification URL pointing to actual Firebase Function
    const verificationUrl =
      `https://verifyemailtoken-e2flivnuba-uc.a.run.app?token=${token}`;

    const htmlContent = `
      <div style="font-family: Arial, sans-serif; max-width: 600px;
        margin: 0 auto; padding: 20px;">
        <div style="text-align: center; margin-bottom: 30px;">
          <h1 style="color: #2563eb; font-size: 24px; margin: 0;">
            ${appName}
          </h1>
          <p style="color: #64748b; margin: 5px 0 0 0;">공무원 이메일 인증</p>
        </div>

        <div style="background: #f8fafc; border: 1px solid #e2e8f0;
          border-radius: 8px; padding: 30px; margin-bottom: 20px;">
          <h2 style="color: #1e293b; font-size: 20px; margin: 0 0 20px 0;">
            이메일 주소를 인증해주세요
          </h2>

          <p style="color: #475569; line-height: 1.6; margin: 0 0 20px 0;">
            안녕하세요!<br>
            ${appName}에서 공무원 이메일 인증을 요청하셨습니다.
          </p>

          <p style="color: #475569; line-height: 1.6; margin: 0 0 30px 0;">
            아래 버튼을 클릭하여 이메일 주소를 인증해주세요:
          </p>

          <div style="text-align: center; margin: 30px 0;">
            <a href="${verificationUrl}"
               style="background: #2563eb; color: white; padding: 12px 30px;
               text-decoration: none; border-radius: 6px; font-weight: 500;
               display: inline-block;">
              이메일 인증하기
            </a>
          </div>

          <p style="color: #64748b; font-size: 14px; line-height: 1.5;
             margin: 20px 0 0 0;">
            또는 아래 링크를 브라우저에 복사하여 붙여넣으세요:<br>
            <a href="${verificationUrl}"
               style="color: #2563eb; word-break: break-all;">
              ${verificationUrl}
            </a>
          </p>
        </div>

        <div style="border-top: 1px solid #e2e8f0; padding-top: 20px;">
          <p style="color: #64748b; font-size: 14px; line-height: 1.5;
             margin: 0;">
            <strong>📝 참고사항:</strong><br>
            • 이 링크는 24시간 동안만 유효합니다.<br>
            • 인증을 완료하면 커뮤니티, 매칭 등 확장 기능을 이용할 수 있습니다.<br>
            • 이 메일에 직접 회신하지 마세요.
          </p>

          <p style="color: #64748b; font-size: 12px; margin: 20px 0 0 0;">
            이 메일을 요청하지 않으셨다면 무시하세요.
          </p>
        </div>
      </div>
    `;

    const textContent = `
${appName} - 공무원 이메일 인증

안녕하세요!
${appName}에서 공무원 이메일 인증을 요청하셨습니다.

아래 링크를 클릭하여 이메일 주소를 인증해주세요:
${verificationUrl}

참고사항:
• 이 링크는 24시간 동안만 유효합니다.
• 인증을 완료하면 커뮤니티, 매칭 등 확장 기능을 이용할 수 있습니다.
• 이 메일에 직접 회신하지 마세요.

이 메일을 요청하지 않으셨다면 무시하세요.
    `;

    const mailOptions: nodemailer.SendMailOptions = {
      from: {
        name: appName,
        address: process.env.SMTP_FROM || process.env.SMTP_USER ||
                 "noreply@gongmutalk.com",
      },
      to: to,
      subject: `[${appName}] 공무원 이메일 인증을 완료해주세요`,
      text: textContent,
      html: htmlContent,
    };

    const result = await transporter.sendMail(mailOptions);

    if (result.messageId) {
      logger.info(`Verification email sent successfully to ${to}`, {
        messageId: result.messageId,
        token: token.substring(0, 8) + "...",
      });
      return true;
    } else {
      logger.error(`Failed to send verification email to ${to}`);
      return false;
    }
  } catch (error) {
    logger.error("Error sending verification email", {
      error: error instanceof Error ? error.message : String(error),
      to,
      token: token.substring(0, 8) + "...",
    });
    return false;
  }
}

/**
 * Check if email domain is supported for actual email sending
 * Supports government email domains (@korea.kr, .go.kr) and @naver.com
 * @param {string} email - Email address to check
 * @return {boolean} Whether email sending is supported
 */
export function isEmailSendingSupported(email: string): boolean {
  const normalizedEmail = email.trim().toLowerCase();

  // 중앙정부 도메인 목록
  const centralGovDomains = [
    "@korea.kr", // 공직자통합메일
    "@naver.com", // 공무원 테스트용
  ];

  // 지방자치단체 도메인 목록
  const localGovDomains = [
    "@seoul.kr", // 서울특별시
    "@busan.kr", // 부산광역시
    "@daegu.kr", // 대구광역시
    "@incheon.kr", // 인천광역시
    "@gwangju.kr", // 광주광역시
    "@daejeon.kr", // 대전광역시
    "@ulsan.kr", // 울산광역시
    "@sejong.kr", // 세종특별자치시
    "@gyeonggi.kr", // 경기도
    "@gangwon.kr", // 강원도
    "@chungbuk.kr", // 충청북도
    "@chungnam.kr", // 충청남도
    "@jeonbuk.kr", // 전라북도
    "@jeonnam.kr", // 전라남도
    "@gyeongbuk.kr", // 경상북도
    "@gyeongnam.kr", // 경상남도
    "@jeju.kr", // 제주특별자치도
  ];

  // 직접 매칭되는 도메인 확인
  const centralMatch = centralGovDomains.some((domain) =>
    normalizedEmail.endsWith(domain)
  );

  const localMatch = localGovDomains.some((domain) =>
    normalizedEmail.endsWith(domain)
  );

  // .go.kr로 끝나는 정부기관 도메인 확인
  const isGoKrDomain = normalizedEmail.includes(".go.kr") &&
                       normalizedEmail.endsWith(".go.kr");

  return centralMatch || localMatch || isGoKrDomain;
}
