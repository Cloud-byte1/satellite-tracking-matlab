# Day 5 Engineering Log

Date: 2026-10-18

## Objective

Build a reliable, provenance-preserving CelesTrak data-ingestion layer that will
support SGP4 propagation and near-real-time visualization in later stages.

## Actual starting status

- Days 1–3: complete and previously executed.
- Day 4: Task 1 complete; Tasks 2–6 pending.
- Day 2 CelesTrak preparation: endpoint and catalog configuration only.
- Live CelesTrak retrievals completed by the MATLAB application: **0**.
- Real satellite records parsed by the MATLAB application: **0**.
- SGP4 current-position predictions completed: **0**.

These zero values are intentional and prevent planning work from being reported as
completed integration.

## Progress

- [x] Reviewed existing data configuration and actual completion state.
- [x] Verified the current official GP query and format documentation.
- [x] Selected OMM-compatible CSV as the primary application format.
- [x] Defined independent element-retrieval, propagation, and display loops.
- [x] Documented TLE/OMM semantics, epoch handling, and SGP4 coupling.
- [x] Defined the exact Task 2–8 file plan.
- [x] Implement live HTTPS retrieval and caching.
- [x] Retrieve and assemble five current records by stable catalog ID.
- [x] Add deterministic fixtures and failure-case tests.
- [x] Record live latency, success rate, record age, and cache behavior.
- [x] Propagate the five real records with SGP4 and provide an interactive viewer.

## Current dependency findings

1. `celesTrakConfig.m` and `buildCelesTrakGpUrl.m` provide a useful starting point.
2. The existing catalog has one ISS plus four GPS satellites; Day 5 requires two
   additional active non-GPS spacecraft and therefore needs a revised catalog.
3. No parser, cache, live retrieval, provenance timestamp, or offline response
   fixture currently exists.
4. Day 3's classical-element conversion must not be used directly on GP mean
   elements. Day 6 will provide the SGP4 propagation boundary.

## Task 1 result

Task 1 is complete as a design and teaching milestone. It produces no live API
success metric because no network request was made during this step.

## Task 2 measured results

The first live MATLAB request was executed on 2026-10-19 at 02:57:00 UTC using
`CATNR=25544` and OMM-compatible CSV.

| Metric | Measured result |
|---|---:|
| Live HTTPS requests attempted | 1 |
| Live HTTPS requests successful | 1 |
| Live retrieval success rate | 100% |
| Valid records returned | 1 |
| NORAD catalog match | 25544 |
| Network request duration | 3.369858 s |
| ISS element epoch | 2026-10-18 18:57:18.891936 UTC |
| Element age at retrieval | 7.994788 h |
| Deterministic offline checks | 6 of 6 passed |
| Invalid fixture responses rejected | 1 |
| Simulated network failures handled by stale cache | 1 |
| Cold cache-only load measurement | 1.655714 s |
| MATLAB code-analyzer findings | 0 |

Evidence:

- `data/raw/celestrak_CATNR_25544_20261019T025700Z.csv`
- `data/raw/latest_CATNR_25544.mat`
- `results/day05_task2_retrieval_summary.csv`
- `results/day05_task2_offline_verification.csv`
- `results/day05_task2_live_response.mat`

The successful Task 2 request establishes the transport/cache layer only. It does
not yet satisfy the five-satellite dataset requirement and does not constitute
current-position tracking.

## Task 3 measured results

Task 3 retrieved or reused validated records for five real spacecraft. Four new
HTTPS requests were made; all four returned valid GP CSV records. The existing ISS
record was reused from cache. The first assembly attempt stopped after discovering
that catalog ID 26407 now uses a NAVSTAR name rather than its older GPS BIIR label;
the name policy was repaired without repeating that request.

| Metric | Measured result |
|---|---:|
| Real satellites assembled | 5 |
| New live HTTPS requests | 4 |
| Successful new live responses | 4 |
| New live request success rate | 100% |
| Unique NORAD catalog IDs | 5 |
| Mission groups represented | 4 |
| GPS satellites | 2 |
| Additional non-GPS satellites beyond ISS | 2 |
| Task 3 verification checks | 11 of 11 passed |
| MATLAB code-analyzer findings | 0 |
| Minimum element age at retrieval | 6.801868 h |
| Maximum element age at retrieval | 22.662675 h |

Approximate periods measured from the retrieved mean motion values:

| Satellite | Period (min) | Inclination (deg) | Eccentricity |
|---|---:|---:|---:|
| ISS (ZARYA) | 92.9674 | 51.6325 | 0.0006764 |
| NAVSTAR 48 (USA 151) | 717.9942 | 54.8307 | 0.0116394 |
| NAVSTAR 51 (USA 166) | 718.0114 | 54.8601 | 0.0152075 |
| NOAA 20 (JPSS-1) | 101.4419 | 98.7876 | 0.0000206 |
| LANDSAT 9 | 98.8254 | 98.2158 | 0.00013101 |

Evidence:

- `results/day05_task3_satellite_catalog.csv`
- `results/day05_task3_verification.csv`
- `data/processed/day05_satellite_catalog_latest.csv`
- `data/processed/day05_satellite_catalog_latest.mat`
- Five timestamped source responses under `data/raw`

## Requested real-record simulation extension

The five Task 3 OMM records were initialized and propagated with the official
Vallado/CelesTrak SGP4 MATLAB reference implementation. The simulation uses one
common UTC interval of 12 hours with 120-second output spacing and preserves SGP4's
native TEME Cartesian frame.

| Metric | Measured result |
|---|---:|
| Satellites propagated | 5 |
| Samples per satellite | 361 |
| SGP4 state evaluations | 1,805 |
| Propagation runtime | 2.002 s |
| Published reference checks | 3 of 3 passed |
| Simulation integrity checks | 8 of 8 passed |
| SGP4 nonzero error codes | 0 |

Measured altitude ranges over the common interval were 417.08–421.82 km for ISS,
19,878–20,487 km for NAVSTAR 48, 19,774–20,592 km for NAVSTAR 51,
819.33–834.41 km for NOAA-20, and 694.11–710.77 km for Landsat 9.

Evidence:

- `results/day05_real_satellite_simulation.mat`
- `results/day05_real_satellite_simulation_summary.csv`
- `results/day05_sgp4_reference_verification.csv`
- `results/day05_real_satellite_simulation_verification.csv`
- `figures/day05_real_satellites_sgp4_teme.png`
- `figures/day05_real_satellites_sgp4_teme.fig`

## Sources reviewed

- CelesTrak GP formats and queries:
  <https://celestrak.org/NORAD/documentation/gp-data-formats.php>
- CelesTrak usage policy:
  <https://celestrak.org/usage-policy.php>
- CelesTrak TLE field layout:
  <https://celestrak.org/NORAD/documentation/tle-fmt.php>
- CelesTrak NORAD documentation index:
  <https://celestrak.org/NORAD/documentation/>
- Vallado et al. SGP4 reference implementation and verification files:
  <https://celestrak.org/publications/AIAA/2006-6753/>
- CelesTrak SGP4 implementation FAQ and TEME output-frame notes:
  <https://celestrak.org/publications/AIAA/2006-6753/faq.php>
