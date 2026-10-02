const nodemailer = require('nodemailer');

const mailConfig = {
  host: process.env.MAIL_HOST || 'localhost',
  port: parseInt(process.env.MAIL_PORT || '1025', 10),
  secure: process.env.MAIL_SECURE === 'true',
  auth: process.env.MAIL_USER ? {
    user: process.env.MAIL_USER,
    pass: process.env.MAIL_PASS,
  } : undefined,
};

const transporter = nodemailer.createTransport(mailConfig);

async function verifyMailConfig() {
  if (process.env.NODE_ENV === 'production' && process.env.TEST_OTP_ENABLED !== 'true') {
    if (!process.env.MAIL_HOST || !process.env.MAIL_FROM) {
      console.error('FATAL ERROR: MAIL_HOST and MAIL_FROM must be configured in production.');
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
      from: process.env.MAIL_FROM || '"Wehere" <noreply@wehere.com>',
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
