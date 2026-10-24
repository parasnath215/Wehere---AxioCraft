const nodemailer = require('nodemailer');

const brevoApiKey = process.env.BREVO_API_KEY;
const brevoSenderEmail = process.env.BREVO_SENDER_EMAIL || process.env.SMTP_FROM || process.env.MAIL_FROM || 'grievance@wehere.co.in';
const brevoSenderName = process.env.BREVO_SENDER_NAME || 'Wehere';

const mailHost = process.env.SMTP_HOST || process.env.MAIL_HOST;
const mailFrom = process.env.SMTP_FROM || process.env.MAIL_FROM || 'grievance@wehere.co.in';
const mailPort = parseInt(process.env.SMTP_PORT || process.env.MAIL_PORT || '587', 10);
const mailSecure = (process.env.SMTP_SECURE || process.env.MAIL_SECURE) === 'true';
const mailUser = process.env.SMTP_USER || process.env.MAIL_USER;
const mailPass = process.env.SMTP_PASS || process.env.MAIL_PASS;

let transporter = null;
if (mailHost && (mailUser || mailHost === 'localhost')) {
  transporter = nodemailer.createTransport({
    host: mailHost,
    port: mailPort,
    secure: mailSecure,
    auth: mailUser ? {
      user: mailUser,
      pass: mailPass,
    } : undefined,
  });
}

async function verifyMailConfig() {
  let isConfigured = false;

  if (brevoApiKey) {
    console.log('📧 Mail service: Configured with Brevo Transactional Email API');
    isConfigured = true;
  }

  if (transporter) {
    try {
      await transporter.verify();
      console.log('✅ Mail service: SMTP transport verified and ready');
      isConfigured = true;
    } catch (error) {
      console.warn('⚠️ Mail service: SMTP transport check failed:', error.message);
    }
  }

  if (!isConfigured) {
    console.warn('⚠️ Mail service: Neither BREVO_API_KEY nor SMTP credentials configured. Outgoing emails will be skipped.');
  }
}

async function sendViaBrevo({ to, subject, text, html }) {
  if (!brevoApiKey) return false;

  // Parse sender format "Name <email@domain>" if provided
  let senderEmail = brevoSenderEmail;
  let senderName = brevoSenderName;
  const match = String(senderEmail).match(/^(?:(.*)<)?([^>]+)>?$/);
  if (match) {
    if (match[1] && match[1].trim()) senderName = match[1].trim();
    if (match[2] && match[2].trim()) senderEmail = match[2].trim();
  }

  const payload = {
    sender: { name: senderName, email: senderEmail },
    to: [{ email: to }],
    subject,
    htmlContent: html,
    textContent: text,
  };

  const response = await fetch('https://api.brevo.com/v3/smtp/email', {
    method: 'POST',
    headers: {
      'api-key': brevoApiKey,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    const errorMsg = data.message || `Brevo HTTP ${response.status}`;
    console.error(`❌ Brevo delivery error (${response.status}) to ${to}:`, data);
    if (data.code === 'unauthorized' && errorMsg.includes('unrecognised IP address')) {
      console.warn('⚠️ [Brevo IP Restriction] Your IP address is not authorized in Brevo.');
      console.warn('👉 Please authorize your IP at: https://app.brevo.com/security/authorised_ips');
    }
    throw new Error(errorMsg);
  }

  console.log(`✉️ Email successfully sent to ${to} via Brevo. Message ID: ${data.messageId || 'OK'}`);
  return true;
}

async function sendEmail({ to, subject, text, html }) {
  // 1. Try Brevo REST API first if configured
  if (brevoApiKey) {
    try {
      return await sendViaBrevo({ to, subject, text, html });
    } catch (brevoErr) {
      console.error(`❌ Brevo email failed: ${brevoErr.message}`);
      if (!transporter) {
        throw brevoErr;
      }
      console.log(`🔄 Attempting fallback to SMTP transport...`);
    }
  }

  // 2. Try SMTP transport if configured
  if (transporter && mailFrom) {
    try {
      const info = await transporter.sendMail({
        from: mailFrom,
        to,
        subject,
        text,
        html,
      });
      console.log(`✉️ Email sent to ${to} via SMTP. MessageId: ${info.messageId}`);
      return true;
    } catch (smtpErr) {
      console.error(`❌ Failed to send email via SMTP to ${to}:`, smtpErr.message);
      throw new Error('Failed to send email. Please try again later.');
    }
  }

  console.warn(`⚠️ Outgoing email to ${to} skipped (No email provider configured). Subject: "${subject}"`);
  return false;
}

module.exports = {
  verifyMailConfig,
  sendEmail,
};
