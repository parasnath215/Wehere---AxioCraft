const nodemailer = require('nodemailer');

const mailHost = process.env.SMTP_HOST || process.env.MAIL_HOST;
const mailFrom = process.env.SMTP_FROM || process.env.MAIL_FROM;
const mailPort = parseInt(process.env.SMTP_PORT || process.env.MAIL_PORT || '587', 10);
const mailSecure = (process.env.SMTP_SECURE || process.env.MAIL_SECURE) === 'true';
const mailUser = process.env.SMTP_USER || process.env.MAIL_USER;
const mailPass = process.env.SMTP_PASS || process.env.MAIL_PASS;

const mailConfig = {
  host: mailHost || 'localhost',
  port: mailPort,
  secure: mailSecure,
  auth: mailUser ? {
    user: mailUser,
    pass: mailPass,
  } : undefined,
};

const transporter = nodemailer.createTransport(mailConfig);

async function verifyMailConfig() {
  if (process.env.NODE_ENV === 'production' && process.env.TEST_OTP_ENABLED !== 'true') {
    if (!mailHost || !mailFrom) {
      console.error('FATAL ERROR: SMTP_HOST (or MAIL_HOST) and SMTP_FROM (or MAIL_FROM) must be configured in production.');
      process.exit(1);
    }
  }

  try {
    await transporter.verify();
    console.log('✅ Mail service is ready');
  } catch (error) {
    if (process.env.NODE_ENV === 'production' && process.env.TEST_OTP_ENABLED !== 'true') {
      console.error('FATAL ERROR: Failed to connect to the mail server in production.');
      console.error(error);
      process.exit(1);
    } else {
      console.warn('⚠️ Mail service connection failed (expected if local Mailpit is down or TEST_OTP_ENABLED=true):', error.message);
    }
  }
}

async function sendEmail({ to, subject, text, html }) {
  try {
    const info = await transporter.sendMail({
      from: mailFrom || '"Wehere" <noreply@wehere.com>',
      to,
      subject,
      text,
      html,
    });
    console.log(`✉️ Email sent to ${to}. MessageId: ${info.messageId}`);
    return true;
  } catch (error) {
    console.error(`❌ Failed to send email to ${to}:`, error.message);
    throw new Error('Failed to send email. Please try again later.');
  }
}

module.exports = {
  verifyMailConfig,
  sendEmail,
};
