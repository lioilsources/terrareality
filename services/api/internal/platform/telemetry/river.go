package telemetry

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/riverqueue/river"
)

// riverQueueCollector reports the River backlog straight from river_job. It is
// River's own table (not part of the sqlc schema), so the query lives here.
type riverQueueCollector struct {
	pool             *pgxpool.Pool
	jobs, oldest, ok *prometheus.Desc
}

// NewRiverQueueCollector exports pending jobs per queue/state and the age of the
// oldest runnable job. Register it in one process only (the worker).
func NewRiverQueueCollector(pool *pgxpool.Pool) prometheus.Collector {
	return &riverQueueCollector{pool: pool,
		jobs: prometheus.NewDesc(Namespace+"_river_jobs", "Unfinished River jobs by queue and state.",
			[]string{"queue", "state"}, nil),
		oldest: prometheus.NewDesc(Namespace+"_river_oldest_available_seconds",
			"Age of the oldest job that is available but not yet running.", []string{"queue"}, nil),
		ok: prometheus.NewDesc(Namespace+"_river_queue_scrape_success", "1 if the backlog query succeeded.", nil, nil),
	}
}

func (c *riverQueueCollector) Describe(ch chan<- *prometheus.Desc) {
	ch <- c.jobs
	ch <- c.oldest
	ch <- c.ok
}

const riverBacklogSQL = `SELECT queue, state::text, count(*)::bigint,
	COALESCE(EXTRACT(EPOCH FROM now() - min(scheduled_at)), 0)::float8
FROM river_job
WHERE state IN ('available', 'running', 'retryable', 'scheduled')
GROUP BY queue, state`

func (c *riverQueueCollector) Collect(ch chan<- prometheus.Metric) {
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	rows, err := c.pool.Query(ctx, riverBacklogSQL)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var queue, state string
			var n int64
			var age float64
			if err = rows.Scan(&queue, &state, &n, &age); err != nil {
				break
			}
			ch <- prometheus.MustNewConstMetric(c.jobs, prometheus.GaugeValue, float64(n), queue, state)
			if state == "available" {
				ch <- prometheus.MustNewConstMetric(c.oldest, prometheus.GaugeValue, max(age, 0), queue)
			}
		}
		if err == nil {
			err = rows.Err()
		}
	}
	ok := 1.0
	if err != nil {
		ok = 0
	}
	ch <- prometheus.MustNewConstMetric(c.ok, prometheus.GaugeValue, ok)
}

// RiverEvents are the event kinds ObserveRiver understands; pass them to Client.Subscribe.
var RiverEvents = []river.EventKind{river.EventKindJobCompleted, river.EventKindJobFailed,
	river.EventKindJobCancelled, river.EventKindJobSnoozed}

// ObserveRiver counts finished job runs and their durations until events closes or ctx ends.
func ObserveRiver(ctx context.Context, reg prometheus.Registerer, events <-chan *river.Event) {
	runs := prometheus.NewCounterVec(prometheus.CounterOpts{Namespace: Namespace, Name: "river_job_runs_total",
		Help: "Finished River job attempts by kind, queue and outcome."}, []string{"kind", "queue", "outcome"})
	run := prometheus.NewHistogramVec(prometheus.HistogramOpts{Namespace: Namespace, Name: "river_job_run_seconds",
		Help:    "Time spent in the job worker.",
		Buckets: []float64{.01, .05, .1, .25, .5, 1, 2.5, 5, 10, 30, 60, 300}}, []string{"kind"})
	wait := prometheus.NewHistogramVec(prometheus.HistogramOpts{Namespace: Namespace, Name: "river_job_queue_wait_seconds",
		Help:    "Time a job waited in the available state before it started.",
		Buckets: []float64{.05, .1, .5, 1, 5, 10, 30, 60, 300, 900}}, []string{"queue"})
	reg.MustRegister(runs, run, wait)
	for {
		select {
		case <-ctx.Done():
			return
		case ev, open := <-events:
			if !open {
				return
			}
			if ev == nil || ev.Job == nil {
				continue
			}
			runs.WithLabelValues(ev.Job.Kind, ev.Job.Queue, string(ev.Kind)).Inc()
			if ev.JobStats != nil {
				run.WithLabelValues(ev.Job.Kind).Observe(ev.JobStats.RunDuration.Seconds())
				wait.WithLabelValues(ev.Job.Queue).Observe(ev.JobStats.QueueWaitDuration.Seconds())
			}
		}
	}
}
