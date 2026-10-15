package telemetry

import (
	"context"
	"errors"
	"log/slog"
	"net"
	"net/http"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/collectors"
	"github.com/prometheus/client_golang/prometheus/promhttp"

	"github.com/terrareality/terrareality/services/api/internal/platform/buildinfo"
)

// Namespace prefixes every TerraReality metric.
const Namespace = "terra"

// MetricsAddr is the internal listener for /metrics (env METRICS_ADDR, e.g.
// ":9090"). Empty disables metrics, which is the dev default.
func MetricsAddr() string { return os.Getenv("METRICS_ADDR") }

// NewRegistry returns a registry with Go runtime, process and build-info collectors.
func NewRegistry(service string) *prometheus.Registry {
	reg := prometheus.NewRegistry()
	reg.MustRegister(
		collectors.NewGoCollector(),
		collectors.NewProcessCollector(collectors.ProcessCollectorOpts{}),
		prometheus.NewGaugeFunc(prometheus.GaugeOpts{
			Namespace: Namespace, Name: "build_info", Help: "Build information of the running binary.",
			ConstLabels: prometheus.Labels{"service": service, "version": buildinfo.Version, "commit": buildinfo.Commit},
		}, func() float64 { return 1 }),
	)
	return reg
}

// ServeMetrics serves /metrics from reg on addr in the background. The listener
// is separate from the public API so it is never exposed through Caddy.
func ServeMetrics(addr string, reg *prometheus.Registry, log *slog.Logger) (func(context.Context) error, error) {
	ln, err := net.Listen("tcp", addr)
	if err != nil {
		return nil, err
	}
	mux := http.NewServeMux()
	mux.Handle("/metrics", promhttp.HandlerFor(reg, promhttp.HandlerOpts{Registry: reg}))
	srv := &http.Server{Handler: mux, ReadHeaderTimeout: 5 * time.Second}
	go func() {
		if err := srv.Serve(ln); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Error("metrics listener", "err", err)
		}
	}()
	log.Info("metrics listening", "addr", ln.Addr().String())
	return srv.Shutdown, nil
}

// poolCollector exports pgxpool statistics on every scrape.
type poolCollector struct {
	pool                                                *pgxpool.Pool
	acquired, idle, total, max, constructing            *prometheus.Desc
	acquireCount, acquireSeconds, emptyAcquire, cancels *prometheus.Desc
}

// NewPoolCollector exports connection pool stats of pool.
func NewPoolCollector(pool *pgxpool.Pool) prometheus.Collector {
	d := func(name, help string) *prometheus.Desc {
		return prometheus.NewDesc(prometheus.BuildFQName(Namespace, "db_pool", name), help, nil, nil)
	}
	return &poolCollector{pool: pool,
		acquired:       d("acquired_conns", "Connections currently checked out."),
		idle:           d("idle_conns", "Idle connections."),
		total:          d("total_conns", "Open connections."),
		max:            d("max_conns", "Configured maximum connections."),
		constructing:   d("constructing_conns", "Connections being established."),
		acquireCount:   d("acquires_total", "Successful acquires."),
		acquireSeconds: d("acquire_seconds_total", "Total time spent waiting for a connection."),
		emptyAcquire:   d("empty_acquires_total", "Acquires that had to wait because the pool was empty."),
		cancels:        d("canceled_acquires_total", "Acquires canceled by the caller's context."),
	}
}

func (c *poolCollector) Describe(ch chan<- *prometheus.Desc) {
	for _, d := range []*prometheus.Desc{c.acquired, c.idle, c.total, c.max, c.constructing,
		c.acquireCount, c.acquireSeconds, c.emptyAcquire, c.cancels} {
		ch <- d
	}
}

func (c *poolCollector) Collect(ch chan<- prometheus.Metric) {
	s := c.pool.Stat()
	g := func(d *prometheus.Desc, v float64) { ch <- prometheus.MustNewConstMetric(d, prometheus.GaugeValue, v) }
	k := func(d *prometheus.Desc, v float64) {
		ch <- prometheus.MustNewConstMetric(d, prometheus.CounterValue, v)
	}
	g(c.acquired, float64(s.AcquiredConns()))
	g(c.idle, float64(s.IdleConns()))
	g(c.total, float64(s.TotalConns()))
	g(c.max, float64(s.MaxConns()))
	g(c.constructing, float64(s.ConstructingConns()))
	k(c.acquireCount, float64(s.AcquireCount()))
	k(c.acquireSeconds, s.AcquireDuration().Seconds())
	k(c.emptyAcquire, float64(s.EmptyAcquireCount()))
	k(c.cancels, float64(s.CanceledAcquireCount()))
}
