/**
 * Phone number validation + normalization for the Number Check feature.
 *
 * Design: the same physical number must resolve to the same registry entry
 * whether or not the user typed a leading "+". We therefore key on a
 * canonical DIGITS-ONLY form, while preserving a tidy display form that keeps
 * the "+" when one was provided.
 */

export interface PhoneParse {
  /** True when the input is a plausible phone number. */
  valid: boolean;
  /** Canonical key: digits only, no "+", used for lookup/storage. */
  key: string;
  /** Human-friendly form: "+" (if provided or E.164-length) then digits. */
  display: string;
  /** Reason it's invalid (for UI messaging); empty when valid. */
  error: string;
}

// E.164 allows up to 15 digits; require at least 7 to reject obvious junk.
const MIN_DIGITS = 7;
const MAX_DIGITS = 15;

/**
 * Parse and validate a raw phone input.
 * Accepts spaces, dashes, parens, dots and an optional single leading "+".
 */
export function parsePhone(input: string): PhoneParse {
  const raw = input.trim();

  if (!raw) {
    return { valid: false, key: '', display: '', error: 'Enter a phone number.' };
  }

  // A "+" is only allowed as the very first character.
  const hadPlus = raw.startsWith('+');
  const body = hadPlus ? raw.slice(1) : raw;

  // Reject anything that isn't a digit or common separator.
  if (/[^\d\s\-().]/.test(body)) {
    return {
      valid: false,
      key: '',
      display: '',
      error: 'Use digits only, with an optional leading "+".',
    };
  }

  const digits = body.replace(/\D/g, '');

  if (digits.length < MIN_DIGITS) {
    return {
      valid: false,
      key: digits,
      display: digits,
      error: `Too short — a phone number has at least ${MIN_DIGITS} digits.`,
    };
  }
  if (digits.length > MAX_DIGITS) {
    return {
      valid: false,
      key: digits,
      display: digits,
      error: `Too long — a phone number has at most ${MAX_DIGITS} digits.`,
    };
  }

  // Canonical key is digits-only so "+X" and "X" match the same entry.
  // Display keeps a "+" if the user typed one, or if it looks like a full
  // international number (11+ digits), which conventionally carries a "+".
  const display = hadPlus || digits.length >= 11 ? `+${digits}` : digits;

  return { valid: true, key: digits, display, error: '' };
}

/** Convenience: is this input a valid phone number? */
export function isValidPhone(input: string): boolean {
  return parsePhone(input).valid;
}
