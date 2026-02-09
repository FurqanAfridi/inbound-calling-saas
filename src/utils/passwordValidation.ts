/**
 * Validates password strength
 * Requirements:
 * - Minimum 8 characters
 * - At least one capital letter
 */
export interface PasswordValidationResult {
  isValid: boolean;
  errors: string[];
}

export const validatePassword = (password: string): PasswordValidationResult => {
  const errors: string[] = [];

  if (password.length < 8) {
    errors.push('Password must be at least 8 characters long');
  }

  if (!/[A-Z]/.test(password)) {
    errors.push('Password must include at least one capital letter');
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

export const getPasswordRequirements = (): string[] => {
  return [
    'Minimum 8 characters',
    'At least one capital letter (A-Z)',
  ];
};
