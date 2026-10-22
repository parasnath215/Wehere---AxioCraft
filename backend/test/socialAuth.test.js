const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');

// Ensure APPLE_CLIENT_IDS is configured for test
process.env.APPLE_CLIENT_IDS = 'com.wehere.app,com.wehere.app.dev';

const { verifySocialToken } = require('../src/services/socialAuth');

test('verifySocialToken Apple path with injected test key', async (t) => {
  // Generate primary RSA keypair
  const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
    modulusLength: 2048,
    publicKeyEncoding: { type: 'spki', format: 'pem' },
    privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
  });

  // Generate an alternate keypair for bad signature test
  const altKeys = crypto.generateKeyPairSync('rsa', {
    modulusLength: 2048,
    publicKeyEncoding: { type: 'spki', format: 'pem' },
    privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
  });

  const appleKeyGetter = (header, cb) => {
    cb(null, publicKey);
  };

  const rawNonce = 'random_client_nonce_1234567890';
  const hashedNonce = crypto.createHash('sha256').update(rawNonce).digest('hex');

  await t.test('valid Apple token resolves normalised profile', async () => {
    const validToken = jwt.sign(
      {
        iss: 'https://appleid.apple.com',
        aud: 'com.wehere.app',
        sub: 'apple_user_sub_001',
        email: 'user@privaterelay.appleid.com',
        email_verified: true,
        nonce: hashedNonce,
      },
      privateKey,
      { algorithm: 'RS256', expiresIn: '1h' }
    );

    const profile = await verifySocialToken({
      provider: 'apple',
      idToken: validToken,
      nonce: rawNonce,
      givenName: 'Jane',
      familyName: 'Doe',
      appleKeyGetter,
    });

    assert.equal(profile.provider, 'apple');
    assert.equal(profile.subject, 'apple_user_sub_001');
    assert.equal(profile.email, 'user@privaterelay.appleid.com');
    assert.equal(profile.emailVerified, true);
    assert.equal(profile.name, 'Jane Doe');
    assert.equal(profile.givenName, 'Jane');
    assert.equal(profile.familyName, 'Doe');
  });

  await t.test('wrong audience throws INVALID_CREDENTIALS', async () => {
    const wrongAudToken = jwt.sign(
      {
        iss: 'https://appleid.apple.com',
        aud: 'wrong.bundle.id',
        sub: 'apple_user_sub_002',
        email: 'user@example.com',
        email_verified: true,
      },
      privateKey,
      { algorithm: 'RS256', expiresIn: '1h' }
    );

    await assert.rejects(
      async () => {
        await verifySocialToken({
          provider: 'apple',
          idToken: wrongAudToken,
          appleKeyGetter,
        });
      },
      (err) => {
        assert.equal(err.code, 'INVALID_CREDENTIALS');
        assert.equal(err.statusCode, 401);
        return true;
      }
    );
  });

  await t.test('expired token throws INVALID_CREDENTIALS', async () => {
    const expiredToken = jwt.sign(
      {
        iss: 'https://appleid.apple.com',
        aud: 'com.wehere.app',
        sub: 'apple_user_sub_003',
        email: 'user@example.com',
        email_verified: true,
        exp: Math.floor(Date.now() / 1000) - 300, // 5 min ago
      },
      privateKey,
      { algorithm: 'RS256' }
    );

    await assert.rejects(
      async () => {
        await verifySocialToken({
          provider: 'apple',
          idToken: expiredToken,
          appleKeyGetter,
        });
      },
      (err) => {
        assert.equal(err.code, 'INVALID_CREDENTIALS');
        assert.equal(err.statusCode, 401);
        return true;
      }
    );
  });

  await t.test('bad signature throws INVALID_CREDENTIALS', async () => {
    const badSigToken = jwt.sign(
      {
        iss: 'https://appleid.apple.com',
        aud: 'com.wehere.app',
        sub: 'apple_user_sub_004',
        email: 'user@example.com',
        email_verified: true,
      },
      altKeys.privateKey, // Signed with different key
      { algorithm: 'RS256', expiresIn: '1h' }
    );

    await assert.rejects(
      async () => {
        await verifySocialToken({
          provider: 'apple',
          idToken: badSigToken,
          appleKeyGetter, // Verification tries with publicKey from primary keypair
        });
      },
      (err) => {
        assert.equal(err.code, 'INVALID_CREDENTIALS');
        assert.equal(err.statusCode, 401);
        return true;
      }
    );
  });

  await t.test('wrong nonce throws INVALID_CREDENTIALS', async () => {
    const tokenWithNonce = jwt.sign(
      {
        iss: 'https://appleid.apple.com',
        aud: 'com.wehere.app',
        sub: 'apple_user_sub_005',
        email: 'user@example.com',
        email_verified: true,
        nonce: hashedNonce,
      },
      privateKey,
      { algorithm: 'RS256', expiresIn: '1h' }
    );

    await assert.rejects(
      async () => {
        await verifySocialToken({
          provider: 'apple',
          idToken: tokenWithNonce,
          nonce: 'completely_different_nonce',
          appleKeyGetter,
        });
      },
      (err) => {
        assert.equal(err.code, 'INVALID_CREDENTIALS');
        assert.equal(err.statusCode, 401);
        return true;
      }
    );
  });
});
