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
  if (!mailHost || !mailFrom) {
    console.warn('⚠️ Mail service: SMTP_HOST (or MAIL_HOST) and SMTP_FROM are not configured. Outgoing emails will be disabled until configured.');
    return;
  }

  try {
    await transporter.verify();
    console.log('✅ Mail service is ready');
  } catch (error) {
    console.warn('⚠️ Mail service connection failed:', error.message);
  }
}

async function sendEmail({ to, subject, text, html }) {
  if (!mailHost || !mailFrom) {
    console.warn(`⚠️ Email to ${to} skipped because SMTP credentials are not yet configured in .env. Subject: "${subject}"`);
    return false;
  }
  try {
    const info = await transporter.sendMail({
      from: mailFrom,
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
