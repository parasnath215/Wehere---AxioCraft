const { z } = require('zod');

const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#$%^&*()_+={}\[\]|\\:;"'<>,.?/~`]).{8,}$/;

const passwordSchema = z.string().regex(
  passwordRegex,
  'Password must be at least 8 characters, contain 1 uppercase, 1 lowercase, and 1 special character.'
);

module.exports = {
  passwordRegex,
  passwordSchema,
};
