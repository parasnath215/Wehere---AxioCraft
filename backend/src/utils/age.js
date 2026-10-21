/**
 * Utilities for Date of Birth parsing and age calculation
 */

function calcAge(dob, now = new Date()) {
  if (!dob) return 0;
  const birthDate = dob instanceof Date ? dob : new Date(dob);
  if (isNaN(birthDate.getTime())) return 0;

  const currentYear = now.getUTCFullYear();
  const currentMonth = now.getUTCMonth();
  const currentDay = now.getUTCDate();

  const birthYear = birthDate.getUTCFullYear();
  const birthMonth = birthDate.getUTCMonth();
  const birthDay = birthDate.getUTCDate();

  let age = currentYear - birthYear;
  const monthDiff = currentMonth - birthMonth;

  if (monthDiff < 0 || (monthDiff === 0 && currentDay < birthDay)) {
    age--;
  }

  return age;
}

function parseDob(str) {
  if (typeof str !== 'string') return null;
  const trimmed = str.trim();
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(trimmed);
  if (!match) return null;

  const year = parseInt(match[1], 10);
  const month = parseInt(match[2], 10);
  const day = parseInt(match[3], 10);

  if (month < 1 || month > 12) return null;
  if (day < 1 || day > 31) return null;

  // Use UTC to avoid timezone day shifts
  const dob = new Date(Date.UTC(year, month - 1, day));
  if (isNaN(dob.getTime())) return null;

  // Check rollover (e.g. 2024-02-30 -> March)
  if (dob.getUTCFullYear() !== year || dob.getUTCMonth() !== month - 1 || dob.getUTCDate() !== day) {
    return null;
  }

  const now = new Date();
  if (dob.getTime() > now.getTime()) {
    return null; // Future date
  }

  const age = calcAge(dob, now);
  if (age < 0 || age > 100) {
    return null; // Reject ages outside 0..100
  }

  return dob;
}

module.exports = {
  calcAge,
  parseDob,
};
