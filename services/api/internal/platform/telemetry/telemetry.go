// Package telemetry wires OpenTelemetry tracing and Prometheus metrics. Without
// an OTLP endpoint it installs a no-op tracer provider and without METRICS_ADDR
// no metrics listener is started, so instrumentation is free in dev.
package telemetry

import (
	"context"
	"os"
	"strconv"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.26.0"

	"github.com/terrareality/terrareality/services/api/internal/platform/buildinfo"
)

// Setup returns a shutdown function that flushes pending spans. The sampling
// ratio comes from OTEL_TRACES_SAMPLER_ARG (0..1, default 1) and is applied
// parent-based, so a sampled caller (web, api) keeps its trace in the worker.
func Setup(ctx context.Context, service, endpoint, env string) (func(context.Context) error, error) {
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(
		propagation.TraceContext{}, propagation.Baggage{}))
	if endpoint == "" {
		return func(context.Context) error { return nil }, nil
	}
	exp, err := otlptracehttp.New(ctx, otlptracehttp.WithEndpointURL(endpoint))
	if err != nil {
		return nil, err
	}
	res := resource.NewWithAttributes(semconv.SchemaURL,
		semconv.ServiceName(service),
		semconv.ServiceVersion(buildinfo.Version),
		semconv.DeploymentEnvironment(env),
	)
	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exp),
		sdktrace.WithResource(res),
		sdktrace.WithSampler(sdktrace.ParentBased(sdktrace.TraceIDRatioBased(SampleRatio(os.Getenv("OTEL_TRACES_SAMPLER_ARG"))))),
	)
	otel.SetTracerProvider(tp)
	return tp.Shutdown, nil
}

// SampleRatio parses OTEL_TRACES_SAMPLER_ARG; invalid or empty values sample everything.
func SampleRatio(v string) float64 {
	f, err := strconv.ParseFloat(v, 64)
	if err != nil || f < 0 || f > 1 {
		return 1
	}
	return f
}
