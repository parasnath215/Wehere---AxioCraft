const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const jwksRsa = require('jwks-rsa');
const { OAuth2Client } = require('google-auth-library');

const googleClient = new OAuth2Client();

function getGoogleClientIds() {
  const ids = [];
  if (process.env.GOOGLE_CLIENT_IDS) {
    process.env.GOOGLE_CLIENT_IDS.split(',').forEach(id => {
      const trimmed = id.trim();
      if (trimmed) ids.push(trimmed);
    });
  }
  if (process.env.GOOGLE_CLIENT_ID) {
    const trimmed = process.env.GOOGLE_CLIENT_ID.trim();
    if (trimmed && !ids.includes(trimmed)) ids.push(trimmed);
  }
  return ids;
}

function getAppleClientIds() {
  const ids = [];
  if (process.env.APPLE_CLIENT_IDS) {
    process.env.APPLE_CLIENT_IDS.split(',').forEach(id => {
      const trimmed = id.trim();
      if (trimmed) ids.push(trimmed);
    });
  }
  return ids;
}

const appleJwksClient = jwksRsa({
  jwksUri: 'https://appleid.apple.com/auth/keys',
  cache: true,
  rateLimit: true,
  jwksRequestsPerMinute: 10,
});

function defaultAppleKeyGetter(header, callback) {
  appleJwksClient.getSigningKey(header.kid, (err, key) => {
    if (err) return callback(err);
    const signingKey = key.getPublicKey ? key.getPublicKey() : key.rsaPublicKey;
    callback(null, signingKey);
  });
}

let customAppleKeyGetter = null;
function setAppleKeyGetter(fn) {
  customAppleKeyGetter = fn;
}

function createInvalidCredentialsError(message = 'Invalid social credentials') {
  const err = new Error(message);
  err.code = 'INVALID_CREDENTIALS';
  err.statusCode = 401;
  return err;
}

async function verifyGoogleToken(idToken) {
  const audiences = getGoogleClientIds();
  let payload;
  try {
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: audiences.length > 0 ? audiences : undefined,
    });
    payload = ticket.getPayload();
  } catch (err) {
    throw createInvalidCredentialsError(err.message || 'Google token verification failed');
  }

  if (!payload || payload.email_verified !== true) {
    throw createInvalidCredentialsError('Google account email is not verified');
  }

  let pictureUrl = payload.picture || null;
  if (pictureUrl && typeof pictureUrl === 'string') {
    pictureUrl = pictureUrl.replace(/=s\d+(-c)?$/, '=s512-c');
  }

  return {
    provider: 'google',
    subject: payload.sub,
    email: (payload.email || '').trim().toLowerCase(),
    emailVerified: true,
    name: payload.name || '',
    givenName: payload.given_name || '',
    familyName: payload.family_name || '',
    pictureUrl,
    locale: payload.locale || null,
  };
}

async function verifyAppleToken({ idToken, nonce, givenName, familyName, appleKeyGetter }) {
  const keyGetter = appleKeyGetter || customAppleKeyGetter || defaultAppleKeyGetter;
  const appleClientIds = getAppleClientIds();

  return new Promise((resolve, reject) => {
    jwt.verify(
      idToken,
      keyGetter,
      {
        algorithms: ['RS256'],
        issuer: 'https://appleid.apple.com',
        audience: appleClientIds.length > 0 ? appleClientIds : undefined,
      },
      (err, payload) => {
        if (err || !payload) {
          return reject(createInvalidCredentialsError(err ? err.message : 'Invalid Apple token'));
        }

        // Validate nonce if present in payload or provided by client
        if (payload.nonce) {
          if (!nonce) {
            return reject(createInvalidCredentialsError('Nonce required but not provided'));
          }
          const rawNonceHash = crypto.createHash('sha256').update(nonce).digest('hex');
          if (payload.nonce !== rawNonceHash) {
            return reject(createInvalidCredentialsError('Apple token nonce mismatch'));
          }
        }

        const emailVerified =
          payload.email_verified === true || payload.email_verified === 'true';

        const nameFromHints = [givenName, familyName].filter(Boolean).join(' ').trim();

        resolve({
          provider: 'apple',
          subject: payload.sub,
          email: payload.email ? payload.email.trim().toLowerCase() : null,
          emailVerified,
          name: nameFromHints || '',
          givenName: givenName || '',
          familyName: familyName || '',
          pictureUrl: null,
          locale: null,
        });
      }
    );
  });
}

async function verifySocialToken({ provider, idToken, nonce, givenName, familyName, appleKeyGetter }) {
  if (!idToken || typeof idToken !== 'string') {
    throw createInvalidCredentialsError('idToken is required');
  }

  const normalizedProvider = (provider || '').trim().toLowerCase();
  if (normalizedProvider === 'google') {
    return verifyGoogleToken(idToken);
  } else if (normalizedProvider === 'apple') {
    return verifyAppleToken({ idToken, nonce, givenName, familyName, appleKeyGetter });
  } else {
    throw createInvalidCredentialsError(`Unsupported social provider: ${provider}`);
  }
}

module.exports = {
  verifySocialToken,
  setAppleKeyGetter,
  getGoogleClientIds,
  getAppleClientIds,
};
