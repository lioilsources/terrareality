// Package storage is the object storage adapter (S3 compatible: SeaweedFS in
// dev and on the NAS, Hetzner Object Storage in production).
package storage

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"net/url"
	"strings"
	"sync"
	"time"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

// Blob stores private objects and hands out short-lived links.
type Blob interface {
	Put(ctx context.Context, key, contentType string, body []byte) error
	Get(ctx context.Context, key string) ([]byte, error)
	// GetLimited reads an object of at most max bytes. It checks the stored
	// size before reading and never buffers more than max+1 bytes, so a huge
	// upload through a presigned PUT cannot exhaust memory (ErrTooLarge).
	GetLimited(ctx context.Context, key string, max int64) ([]byte, error)
	Delete(ctx context.Context, key string) error
	PresignGet(ctx context.Context, key string, ttl time.Duration) (string, error)
	// PresignDownload is PresignGet with a forced
	// "Content-Disposition: attachment" (and the given file name) and the
	// given, server-validated Content-Type (octet-stream when empty), so a
	// user supplied file never renders as a page on the storage origin
	// whatever Content-Type the uploader set on the presigned PUT.
	PresignDownload(ctx context.Context, key, filename, contentType string, ttl time.Duration) (string, error)
	PresignPut(ctx context.Context, key string, ttl time.Duration) (string, error)
	Ping(ctx context.Context) error
}

// ErrNotFound is returned for missing objects.
var ErrNotFound = errors.New("object not found")

// ErrTooLarge is returned by GetLimited for objects above the limit.
var ErrTooLarge = errors.New("object too large")

// AttachmentDisposition is the Content-Disposition header value that makes a
// browser download filename instead of rendering it.
func AttachmentDisposition(filename string) string {
	name := strings.Map(func(r rune) rune {
		if r < 0x20 || r == 0x7f || r == '"' || r == '\\' {
			return '_'
		}
		return r
	}, filename)
	if name == "" {
		name = "download"
	}
	ascii := strings.Map(func(r rune) rune {
		if r > 0x7e {
			return '_'
		}
		return r
	}, name)
	return fmt.Sprintf(`attachment; filename="%s"; filename*=UTF-8''%s`, ascii, url.PathEscape(name))
}

// safeContentType allows only types that browsers never execute as a
// document; everything else is served as application/octet-stream.
func safeContentType(ct string) string {
	switch ct {
	case "image/jpeg", "image/png", "image/webp", "image/heic", "application/pdf":
		return ct
	}
	return "application/octet-stream"
}

func notFound(err error) bool {
	code := minio.ToErrorResponse(err).Code
	return code == "NoSuchKey" || code == "NotFound"
}

// S3Config configures the S3 adapter.
type S3Config struct {
	Endpoint, AccessKey, SecretKey, Bucket, Region string
	UseSSL                                         bool
}

// S3 implements Blob with minio-go.
type S3 struct {
	c      *minio.Client
	bucket string
	region string
	once   sync.Once
	err    error
}

// NewS3 creates the adapter; the bucket is created on first use.
func NewS3(cfg S3Config) (*S3, error) {
	c, err := minio.New(cfg.Endpoint, &minio.Options{
		Creds: credentials.NewStaticV4(cfg.AccessKey, cfg.SecretKey, ""), Secure: cfg.UseSSL, Region: cfg.Region,
	})
	if err != nil {
		return nil, err
	}
	return &S3{c: c, bucket: cfg.Bucket, region: cfg.Region}, nil
}

func (s *S3) ensure(ctx context.Context) error {
	s.once.Do(func() {
		ok, err := s.c.BucketExists(ctx, s.bucket)
		if err == nil && !ok {
			err = s.c.MakeBucket(ctx, s.bucket, minio.MakeBucketOptions{Region: s.region})
		}
		s.err = err
	})
	return s.err
}

// Put implements Blob.
func (s *S3) Put(ctx context.Context, key, contentType string, body []byte) error {
	if err := s.ensure(ctx); err != nil {
		return err
	}
	_, err := s.c.PutObject(ctx, s.bucket, key, bytes.NewReader(body), int64(len(body)),
		minio.PutObjectOptions{ContentType: contentType})
	return err
}

// Get implements Blob.
func (s *S3) Get(ctx context.Context, key string) ([]byte, error) {
	o, err := s.c.GetObject(ctx, s.bucket, key, minio.GetObjectOptions{})
	if err != nil {
		return nil, err
	}
	defer o.Close()
	b, err := io.ReadAll(o)
	if notFound(err) {
		return nil, ErrNotFound
	}
	return b, err
}

// GetLimited implements Blob.
func (s *S3) GetLimited(ctx context.Context, key string, max int64) ([]byte, error) {
	st, err := s.c.StatObject(ctx, s.bucket, key, minio.StatObjectOptions{})
	if notFound(err) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if st.Size > max {
		return nil, ErrTooLarge
	}
	o, err := s.c.GetObject(ctx, s.bucket, key, minio.GetObjectOptions{})
	if err != nil {
		return nil, err
	}
	defer o.Close()
	// The object may have been replaced between stat and read.
	b, err := io.ReadAll(io.LimitReader(o, max+1))
	if notFound(err) {
		return nil, ErrNotFound
	}
	if err == nil && int64(len(b)) > max {
		return nil, ErrTooLarge
	}
	return b, err
}

// Delete implements Blob.
func (s *S3) Delete(ctx context.Context, key string) error {
	return s.c.RemoveObject(ctx, s.bucket, key, minio.RemoveObjectOptions{})
}

// PresignGet implements Blob.
func (s *S3) PresignGet(ctx context.Context, key string, ttl time.Duration) (string, error) {
	u, err := s.c.PresignedGetObject(ctx, s.bucket, key, ttl, url.Values{})
	if err != nil {
		return "", err
	}
	return u.String(), nil
}

// PresignDownload implements Blob.
func (s *S3) PresignDownload(ctx context.Context, key, filename, contentType string, ttl time.Duration) (string, error) {
	q := url.Values{}
	q.Set("response-content-disposition", AttachmentDisposition(filename))
	q.Set("response-content-type", safeContentType(contentType))
	u, err := s.c.PresignedGetObject(ctx, s.bucket, key, ttl, q)
	if err != nil {
		return "", err
	}
	return u.String(), nil
}

// PresignPut implements Blob.
func (s *S3) PresignPut(ctx context.Context, key string, ttl time.Duration) (string, error) {
	if err := s.ensure(ctx); err != nil {
		return "", err
	}
	u, err := s.c.PresignedPutObject(ctx, s.bucket, key, ttl)
	if err != nil {
		return "", err
	}
	return u.String(), nil
}

// Ping implements Blob.
func (s *S3) Ping(ctx context.Context) error { return s.ensure(ctx) }

// Memory implements Blob in memory (tests, and dev without S3).
type Memory struct {
	mu      sync.Mutex
	objects map[string][]byte
	BaseURL string
}

// NewMemory creates an empty in-memory store.
func NewMemory(baseURL string) *Memory {
	return &Memory{objects: map[string][]byte{}, BaseURL: baseURL}
}

// Put implements Blob.
func (m *Memory) Put(_ context.Context, key, _ string, body []byte) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.objects[key] = append([]byte(nil), body...)
	return nil
}

// Get implements Blob.
func (m *Memory) Get(_ context.Context, key string) ([]byte, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	b, ok := m.objects[key]
	if !ok {
		return nil, ErrNotFound
	}
	return b, nil
}

// GetLimited implements Blob.
func (m *Memory) GetLimited(ctx context.Context, key string, max int64) ([]byte, error) {
	b, err := m.Get(ctx, key)
	if err != nil {
		return nil, err
	}
	if int64(len(b)) > max {
		return nil, ErrTooLarge
	}
	return b, nil
}

// Delete implements Blob.
func (m *Memory) Delete(_ context.Context, key string) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	delete(m.objects, key)
	return nil
}

// PresignGet implements Blob.
func (m *Memory) PresignGet(_ context.Context, key string, ttl time.Duration) (string, error) {
	return fmt.Sprintf("%s/%s?expires=%d", m.BaseURL, key, time.Now().Add(ttl).Unix()), nil
}

// PresignDownload implements Blob.
func (m *Memory) PresignDownload(_ context.Context, key, filename, contentType string, ttl time.Duration) (string, error) {
	return fmt.Sprintf("%s/%s?expires=%d&response-content-disposition=%s&response-content-type=%s", m.BaseURL, key,
		time.Now().Add(ttl).Unix(), url.QueryEscape(AttachmentDisposition(filename)), url.QueryEscape(safeContentType(contentType))), nil
}

// Keys lists stored object keys (tests).
func (m *Memory) Keys() []string {
	m.mu.Lock()
	defer m.mu.Unlock()
	out := make([]string, 0, len(m.objects))
	for k := range m.objects {
		out = append(out, k)
	}
	return out
}

// PresignPut implements Blob.
func (m *Memory) PresignPut(ctx context.Context, key string, ttl time.Duration) (string, error) {
	return m.PresignGet(ctx, key, ttl)
}

// Ping implements Blob.
func (m *Memory) Ping(context.Context) error { return nil }
