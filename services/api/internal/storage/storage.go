// Package storage is the object storage adapter (S3 compatible: SeaweedFS in
// dev and on the NAS, Hetzner Object Storage in production). It lives in
// ol1n_platform_kit/storage (ADR 0013).
package storage

import kit "github.com/lioilsources/ol1n_platform_kit/storage"

type (
	Blob     = kit.Blob
	S3       = kit.S3
	S3Config = kit.S3Config
	Memory   = kit.Memory
)

var (
	ErrNotFound           = kit.ErrNotFound
	ErrTooLarge           = kit.ErrTooLarge
	NewS3                 = kit.NewS3
	NewMemory             = kit.NewMemory
	AttachmentDisposition = kit.AttachmentDisposition
)
