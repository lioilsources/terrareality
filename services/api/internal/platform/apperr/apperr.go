// Package apperr defines errors that carry an HTTP status and a stable
// machine-readable code. Handlers return them; the API layer renders them as
// RFC 9457 problem responses and clients translate the code.
package apperr

import (
	"errors"
	"net/http"
)

// Error is a client-facing error.
type Error struct {
	Status int
	Code   string
	Detail string
}

func (e *Error) Error() string { return e.Code + ": " + e.Detail }

func newErr(status int, code, detail string) *Error {
	return &Error{Status: status, Code: code, Detail: detail}
}

// Constructors for common statuses.
func BadRequest(code, detail string) *Error   { return newErr(http.StatusBadRequest, code, detail) }
func Unauthorized(code, detail string) *Error { return newErr(http.StatusUnauthorized, code, detail) }
func Forbidden(code, detail string) *Error    { return newErr(http.StatusForbidden, code, detail) }
func NotFound(code, detail string) *Error     { return newErr(http.StatusNotFound, code, detail) }
func Conflict(code, detail string) *Error     { return newErr(http.StatusConflict, code, detail) }
func Unprocessable(code, detail string) *Error {
	return newErr(http.StatusUnprocessableEntity, code, detail)
}
func TooMany(detail string) *Error { return newErr(http.StatusTooManyRequests, "rate_limited", detail) }
func Unavailable(code, detail string) *Error {
	return newErr(http.StatusServiceUnavailable, code, detail)
}

// Common errors.
var (
	ErrUnauthenticated = Unauthorized("unauthenticated", "authentication required")
	ErrForbidden       = Forbidden("forbidden", "not allowed")
	ErrImpersonation   = Forbidden("impersonation_forbidden", "not allowed while impersonating")
)

// As extracts an *Error.
func As(err error) (*Error, bool) {
	var e *Error
	ok := errors.As(err, &e)
	return e, ok
}
