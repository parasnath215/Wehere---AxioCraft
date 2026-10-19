// Identity and Alias Content Filtering Service
// Ensures psychological safety and prevents offensive or triggering display names

const BLOCKED_WORDS_REGEX = new RegExp(
  [
    '\\b(die|kill|suicide|selfharm|hang|overdose)\\b', // Self-harm / violence triggers
    '\\b(fuck|shit|bitch|bastard|asshole|cunt|dick|pussy)\\b', // Profanity
    '\\b(nigger|nigga|faggot|retard|chink|kike|spic)\\b', // Slurs / Hate speech
    '\\b(nazi|hitler|terrorist|isis|jihad)\\b', // Hate groups / Extremism
    '\\b(porn|sex|escort|camgirl|horny|nude)\\b', // Inappropriate sexualized aliases
  ].join('|'),
  'i'
);

function validateDisplayName(displayName) {
  if (!displayName || typeof displayName !== 'string') {
    return { isValid: false, error: 'Display name is required.' };
  }

  const trimmed = displayName.trim();
  if (trimmed.length < 2) {
    return { isValid: false, error: 'Display name must be at least 2 characters long.' };
  }
  if (trimmed.length > 50) {
    return { isValid: false, error: 'Display name cannot exceed 50 characters.' };
  }

  // Check against trigger and profanity regex
  if (BLOCKED_WORDS_REGEX.test(trimmed)) {
    return {
      isValid: false,
      error: 'Display name contains inappropriate or triggering words. Please choose a safe and supportive alias.'
    };
  }

  // Allow standard characters: unicode letters, numbers, spaces, dots, dashes, underscores
  const validCharRegex = /^[\p{L}\p{N}_\s.-]+$/u;
  if (!validCharRegex.test(trimmed)) {
    return {
      isValid: false,
      error: 'Display name contains invalid special characters.'
    };
  }

  return { isValid: true, cleaned: trimmed };
}

function sanitizeHandle(handle) {
  if (!handle) return null;
  return handle
    .toLowerCase()
    .trim()
    .replace(/^@+/, '')
    .replace(/[^a-z0-9_.-]/g, '');
}

module.exports = {
  validateDisplayName,
  sanitizeHandle,
};
