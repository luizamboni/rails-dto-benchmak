# V1 vs V2 Performance Report

## Summary

Baseline comparison of v1 and v2 registration endpoints using `wrk` and Docker
memory sampling.

## Test Setup

- Date: 2026-01-29
- Tool: `wrk`
- Duration: 10s per endpoint
- Threads: 4
- Connections: 20
- Method: POST
- Payload:
  - `{"user":{"email":"perf@example.com","password":"password","password_confirmation":"password"}}`
- Headers:
  - `Content-Type: application/json`
- Base URL: `http://localhost:3000`
- Docker container: `registration_api-web-1`
- Memory sampling: `docker stats` every 0.5s (avg/max RSS)

## Results

| Endpoint | Req/s | Latency | Memory Avg (MB) | Memory Max (MB) | Samples |
|---|---:|---:|---:|---:|---:|
| v1 (`/api/v1/registrations`) | 29.20 | 664.76ms | 151.06 | 177.70 | 5 |
| v2 (`/api/v2/registrations`) | 31.54 | 614.61ms | 208.70 | 230.00 | 5 |

### Delta (v2 - v1)

- Throughput: +2.34 req/s
- Latency: -50.15ms
- Memory: +57.64 MB avg, +52.30 MB max

## Notes

- Results are single-run snapshots; consider longer durations and multiple runs
  for more stable statistics.
- Docker overhead affects absolute numbers; comparisons are still valid if the
  environment is consistent across v1/v2.

