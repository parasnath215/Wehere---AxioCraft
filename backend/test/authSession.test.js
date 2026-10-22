const test = require('node:test');
const assert = require('node:assert/strict');
const { isOnboardingComplete, assertAccountAllowed } = require('../src/services/authSession');

test('isOnboardingComplete checks', () => {
  assert.equal(isOnboardingComplete(null), false);
  assert.equal(isOnboardingComplete(undefined), false);
  assert.equal(isOnboardingComplete({}), false);
  assert.equal(isOnboardingComplete({ location: 'New York', interests: [] }), false);
  assert.equal(isOnboardingComplete({ location: '', interests: ['Music'] }), false);
  assert.equal(isOnboardingComplete({ location: 'London', interests: null }), false);
  assert.equal(isOnboardingComplete({ location: 'London', interests: ['Reading'] }), true);
  assert.equal(isOnboardingComplete({ location: 'Delhi', interests: ['Tech', 'Art'] }), true);
});

test('assertAccountAllowed checks', () => {
  // Normal active user passes
  assert.doesNotThrow(() => {
    assertAccountAllowed({ id: 'u1', isBanned: false, underageBlockedAt: null });
  });

  // Banned user throws ACCOUNT_BANNED
  assert.throws(
    () => {
      assertAccountAllowed({ id: 'u2', isBanned: true, underageBlockedAt: null });
    },
    (err) => {
      assert.equal(err.code, 'ACCOUNT_BANNED');
      assert.equal(err.status, 403);
      return true;
    }
  );

  // Underage blocked user throws UNDERAGE
  assert.throws(
    () => {
      assertAccountAllowed({ id: 'u3', isBanned: false, underageBlockedAt: new Date() });
    },
    (err) => {
      assert.equal(err.code, 'UNDERAGE');
      assert.equal(err.status, 403);
      return true;
    }
  );
});
