/**
 * Calculates and updates user streak based on the 24h + 12h rule:
 * - On new account creation or first login: streak starts at 0.
 * - diffHours < 24: Still within the same 24-hour cycle. Streak remains unchanged,
 *   and lastLoginDate is NOT updated so the 24-hour anchor is preserved.
 * - 24 <= diffHours <= 36 (i.e. after 24 hrs, with a 12 hrs window): User logged in
 *   during the streak window. Streak increments by 1 and lastLoginDate is updated to now.
 * - diffHours > 36: More than 36 hrs passed (missed the 12h window after 24h).
 *   Streak resets to 0 and lastLoginDate is updated to now.
 * - If lastLoginDate is missing: sets lastLoginDate to now, streak remains 0.
 */

function evaluateStreak(user, now = new Date()) {
  const currentStreak = typeof user.currentStreak === 'number' ? user.currentStreak : 0;

  if (!user.lastLoginDate) {
    return {
      currentStreak: 0,
      lastLoginDate: now,
      shouldUpdate: true,
    };
  }

  const lastLogin = new Date(user.lastLoginDate);
  const diffMs = now.getTime() - lastLogin.getTime();
  const diffHours = diffMs / (1000 * 60 * 60);

  if (diffHours < 24) {
    // Less than 24 hours elapsed: no change in streak, preserve lastLoginDate anchor
    return {
      currentStreak,
      lastLoginDate: lastLogin,
      shouldUpdate: false,
    };
  } else if (diffHours >= 24 && diffHours <= 36) {
    // Between 24 and 36 hours (within the 12-hour grace period): counts as streak!
    return {
      currentStreak: currentStreak + 1,
      lastLoginDate: now,
      shouldUpdate: true,
    };
  } else {
    // More than 36 hours: missed the window, reset streak to 0
    return {
      currentStreak: 0,
      lastLoginDate: now,
      shouldUpdate: true,
    };
  }
}

module.exports = { evaluateStreak };
