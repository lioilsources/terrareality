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
	"sync"
	"time"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

// Blob stores private objects and hands out short-lived links.
type Blob interface {
	Put(ctx context.Context, key, contentType string, body []byte) error
	Get(ctx context.Context, key string) ([]byte, error)
	Delete(ctx context.Context, key string) error
	PresignGet(ctx context.Context, key string, ttl time.Duration) (string, error)
	PresignPut(ctx context.Context, key string, ttl time.Duration) (string, error)
	Ping(ctx context.Context) error
}

// ErrNotFound is returned for missing objects.
var ErrNotFound = errors.New("object not found")

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
	if minio.ToErrorResponse(err).Code == "NoSuchKey" {
		return nil, ErrNotFound
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

// PresignPut implements Blob.
func (m *Memory) PresignPut(ctx context.Context, key string, ttl time.Duration) (string, error) {
	return m.PresignGet(ctx, key, ttl)
}

// Ping implements Blob.
func (m *Memory) Ping(context.Context) error { return nil }
