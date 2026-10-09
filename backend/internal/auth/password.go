package auth

import (
	"errors"

	"golang.org/x/crypto/bcrypt"
)

// maxPasswordBytes is bcrypt's hard input limit; longer inputs are silently
// truncated by the algorithm, so we reject them explicitly.
const maxPasswordBytes = 72

// HashPassword hashes a plaintext password with bcrypt at the given cost. It
// returns ErrPasswordTooLong if the password exceeds bcrypt's 72-byte limit.
func HashPassword(password string, cost int) (string, error) {
	if len(password) > maxPasswordBytes {
		return "", ErrPasswordTooLong
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(password), cost)
	if err != nil {
		return "", err
	}
	return string(hash), nil
}

// ComparePassword compares a bcrypt hash against a plaintext password. It
// returns nil on match, ErrInvalidCredentials on mismatch.
func ComparePassword(hash, password string) error {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	if err != nil {
		if errors.Is(err, bcrypt.ErrMismatchedHashAndPassword) {
			return ErrInvalidCredentials
		}
		return err
	}
	return nil
}
