# Day 5 CelesTrak Integration Guide

## Readiness assessment

The project is ready to begin real-world data ingestion, with important scope
limits recorded explicitly:

- Days 1–3 are complete: the two-body propagator, ideal orbit scenarios,
  classical-element conversion, 3D visualization, and 12 Day 3 checks ran in
  MATLAB R2026b.
- Day 4 Task 1 is complete: six energy histories and three energy checks ran.
- Day 4 Tasks 2–6 are still pending. Angular-momentum vector analysis, the
  convergence campaign, consolidated test suite, 100+ simulations, and final
  performance analysis must not be claimed as complete.
- Day 2 established a CelesTrak URL/data contract and a five-object catalog, but
  performed zero live retrievals. Its catalog contains one ISS and four GPS
  spacecraft, so it does not yet meet Day 5's requirement for two non-GPS active
  spacecraft.

None of the unfinished Day 4 work blocks an isolated, cached data-ingestion layer.
The existing two-body element conversion must not be applied directly to CelesTrak
mean elements and presented as SGP4 tracking.

## Day 5 roadmap

| Sequence | Task | Estimated focused-work time | Status |
|---:|---|---:|---|
| 1 | Understand GP/TLE/OMM data and define integration boundaries | 45 min | Complete |
| 2 | Implement HTTPS retrieval, error handling, timestamps, and cache policy | 75 min | Complete |
| 3 | Select and retrieve ISS, two GPS, and two other active satellites | 45 min | Complete |
| 4 | Parse, validate, deduplicate, and classify record freshness | 75 min | Pending |
| 5 | Add search/filter/update/persistence catalog operations | 60 min | Pending |
| 6 | Document independent data, propagation, and display refresh loops | 30 min | Pending |
| 7 | Document frame/time contracts for Day 6 SGP4 | 45 min | Pending |
| 8 | Run deterministic fixtures, failure cases, and one live integration check | 75 min | Pending |

## Proposed data pipeline

```text
Official CelesTrak GP API
          |
          v                         every >= 2 hours
HTTPS retrieval -----> timestamped raw CSV -----> validated cache
                                                   |
                                                   v
                                        normalized catalog table
                                                   |
                              +--------------------+-------------------+
                              |                                        |
                              v                                        v
                    Day 6 SGP4 propagation                   provenance/age display
                    (TEME state at target UTC)                         |
                              |                                        |
                              +--------------------+-------------------+
                                                   v
                                         frame transformation
                                                   |
                                                   v
                                         3D/dashboard refresh
```

Three clocks remain independent:

1. **Element refresh:** network retrieval no more often than the data source update
   interval. CelesTrak currently states that GP data updates once every two hours,
   so the cache freshness threshold will default to two hours.
2. **Position propagation:** Day 6 SGP4 can propagate cached elements to a target
   UTC time as often as needed without downloading new elements.
3. **Visualization refresh:** the dashboard may redraw more frequently than either
   element retrieval or propagation, depending on display needs.

Source: <https://celestrak.org/usage-policy.php>

## Exact implementation file plan

Existing files will be reused where appropriate; the planned additions are:

| File | Purpose |
|---|---|
| `config/day05TrackingConfig.m` | Endpoint, CSV format, UTC rules, cache age, timeouts |
| `config/day05SatelliteCatalog.m` | Required stable catalog IDs and mission roles |
| `src/io/fetchCelesTrakGp.m` | HTTPS retrieval, latency measurement, and network errors |
| `src/io/parseCelesTrakGpCsv.m` | Convert OMM-compatible CSV text into typed MATLAB data |
| `src/io/validateSatelliteRecords.m` | Required fields, ranges, epochs, duplicates, staleness |
| `src/io/loadCelesTrakCache.m` | Load a valid cached response and provenance metadata |
| `src/io/saveCelesTrakCache.m` | Save raw and normalized timestamped evidence |
| `src/io/selectSatelliteRecords.m` | Search by name/ID and filter orbital characteristics |
| `scripts/run_day05_data_ingestion.m` | Reproducible live-or-cache top-level workflow |
| `tests/fixtures/celestrak-valid.csv` | Deterministic representative valid response |
| `tests/fixtures/celestrak-malformed.csv` | Missing/invalid-field failure fixture |
| `tests/fixtures/celestrak-duplicate.csv` | Duplicate catalog-ID failure fixture |
| `tests/fixtures/celestrak-stale.csv` | Deterministic stale-epoch fixture |
| `tests/runDay05DataTests.m` | Offline tests plus separately reported live check |
| `results/day05_satellite_records.csv` | Normalized five-or-more-satellite dataset |
| `results/day05_data_verification.csv` | Measured integration and failure-case evidence |
| `docs/logs/day05-engineering-log.md` | Retrieval timestamps, latency, errors, and metrics |

Raw responses will be stored under `data/raw`; normalized cache files will be
stored under `data/processed`. No code should silently replace historical raw
evidence.

## Task 1: what the orbital data represents

### GP data, TLE, and OMM

CelesTrak distributes General Perturbations (GP) element sets. A traditional
Two-Line Element set is a compact fixed-width encoding designed to be used with
the SGP4/SDP4 analytical propagator. It is not a telemetry packet and it does not
contain a directly measured current Cartesian position.

The Orbit Mean-Elements Message (OMM) represents the same class of SGP4-compatible
mean-element information with named fields. CelesTrak's current GP query supports
CSV, JSON, XML, KVN, and legacy TLE variants. For this educational application,
OMM-compatible CSV is the preferred ingestion format because it is compact,
inspectable, works naturally with MATLAB tables, preserves ISO-style epochs, and
supports catalog numbers longer than five digits. CelesTrak notes that new
six-digit catalog objects can no longer be represented in legacy TLE format.

Official format documentation:
<https://celestrak.org/NORAD/documentation/gp-data-formats.php>

### Element set versus telemetry

An updated element set is a fitted orbital model derived from observations. It is
not a continuous live stream from the spacecraft. “Near-real-time tracking” in
this project will mean retrieving reasonably fresh public elements, then using
SGP4 to predict a state at the requested time. The dashboard must display the
element epoch, retrieval timestamp, and element age so users can distinguish data
freshness from current-time propagation.

### NORAD catalog number

The NORAD catalog number is the stable numeric identifier used to request and
match a resident space object. Names can change, contain aliases, or be duplicated;
catalog IDs therefore remain the primary selection key. The CelesTrak GP endpoint
supports `CATNR`, `INTDES`, `GROUP`, `NAME`, and special-set queries, with uppercase
query names.

### Epoch and time

The epoch is the time at which the published mean elements are referenced. In
legacy TLE text it is encoded as a two-digit year plus fractional day of year,
where the day begins at UTC midnight. OMM-compatible responses use an explicit
date-time representation and avoid the legacy two-digit-year ambiguity.

The retrieval timestamp is different: it records when this application downloaded
the record. Element age at retrieval is

```text
element age = retrieval UTC - element epoch UTC.
```

Both values must be retained. A recent download can still contain an older element
set.

TLE field/epoch documentation:
<https://celestrak.org/NORAD/documentation/tle-fmt.php>

### Meaning of key fields

| Field | Meaning |
|---|---|
| Inclination | Tilt of the mean orbital plane relative to the reference equator |
| RAAN | Mean orientation of the ascending-node direction |
| Eccentricity | Mean orbit shape parameter |
| Argument of pericenter | Mean in-plane orientation of perigee |
| Mean anomaly | Model phase at the element epoch |
| Mean motion | Mean revolutions per day used by the GP model |
| BSTAR | SGP4 drag-like coefficient, not a direct physical ballistic coefficient |
| Mean-motion derivatives | Legacy/model fields whose interpretation follows the GP format |

Approximate period follows directly from mean motion:

```text
period_minutes = 1440 / mean_motion_rev_per_day.
```

It is an approximate mean period, not a measurement of the next osculating
perigee-to-perigee interval.

### Why these are not classical osculating elements

The published quantities are model-specific **mean** elements. Periodic effects
have been removed according to the SGP4/SDP4 formulation, and the parameters are
fitted so that the matching propagator reproduces observations. Treating them as
instantaneous Keplerian elements and passing them through the Day 3
`orbitalElementsToState` function mixes incompatible definitions. The resulting
state may look plausible but is not an SGP4 result and cannot support a valid
two-body-versus-SGP4 comparison.

CelesTrak's documentation describes the element sets as mean values, and the
SGP4 reference explicitly defines mean motion, eccentricity, inclination, anomaly,
argument of perigee, and node at epoch as model inputs:
<https://celestrak.org/NORAD/documentation/>

### Why SGP4 is required

SGP4 is paired with GP/TLE mean elements. It reconstructs modeled periodic and
secular behavior using Earth zonal harmonics, drag terms, and near-/deep-space
logic. Day 6 should use a tested SGP4 implementation rather than re-creating the
algorithm ad hoc. Its output frame contract must be recorded as TEME.

### Public-data limitations and element age

Prediction quality depends on orbit regime, atmospheric drag, maneuvers, quality
and timing of observations, element-fit quality, and propagation distance from the
epoch. A low-drag stable orbit may remain useful longer than a maneuvering or
low-perigee object. Therefore the software will flag age using a configurable
policy, not claim that one universal age threshold guarantees accuracy.

Fresh elements also do not imply precise truth data. Day 6 comparisons will measure
differences between propagation models, not absolute position error, unless an
independent trusted ephemeris is introduced.

## Task 1 completion gate

Before Task 2 begins, confirm these design choices:

- OMM-compatible CSV is the primary ingestion format.
- Catalog number is the primary key.
- Epoch UTC and retrieval UTC are stored separately.
- GP elements are never passed off as osculating elements.
- SGP4/TEME propagation waits until Day 6.
- A two-hour cache interval is the default and visualization refreshes do not
  trigger network downloads.

## Task 2: HTTPS retrieval and caching

Task 2 adds `day05TrackingConfig`, `fetchCelesTrakGp`, a deterministic test runner,
and a reproducible top-level script. The retrieval function:

1. Builds an official `gp.php` query through the existing URL builder.
2. Uses MATLAB `webread` with text content, a 30-second timeout, and an identifying
   user-agent string.
3. Rejects empty, HTML, malformed, field-incomplete, or physically implausible
   responses before saving them as valid cache entries.
4. Converts catalog ID, inclination, eccentricity, and mean motion to numeric data
   and converts the element epoch to a timezone-aware UTC `datetime`.
5. Stores the element epoch in the record table and the retrieval UTC separately
   in cache metadata.
6. Preserves a timestamped raw CSV and a typed-table cache index.
7. Reuses cache younger than two hours without a network request.
8. Falls back to an older valid cache after a network failure, explicitly labeling
   the source `stale-cache` and retaining the error message.

The Task 2 workflow intentionally retrieves only the ISS. Selecting and retrieving
the complete five-satellite portfolio dataset belongs to Task 3.

## Task 3: five real-spacecraft dataset

The stable-ID target catalog now contains:

| Mission role | NORAD catalog ID | Returned CelesTrak name | Mission group |
|---|---:|---|---|
| Crewed space station | 25544 | ISS (ZARYA) | ISS |
| Navigation | 26407 | NAVSTAR 48 (USA 151) | GPS |
| Navigation | 27663 | NAVSTAR 51 (USA 166) | GPS |
| Weather/Earth observation | 43013 | NOAA 20 (JPSS-1) | JPSS |
| Earth observation | 49260 | LANDSAT 9 | Landsat |

`retrieveTrackedSatelliteCatalog` queries each object by catalog number, requires
one matching record, performs a secondary name-pattern check, and assembles the
required typed table. The approximate period is calculated from mean motion:

```text
period_minutes = 1440 / mean_motion_rev_per_day.
```

The first run correctly exposed an obsolete Day 2 naming assumption: catalog ID
26407 is currently labeled `NAVSTAR 48 (USA 151)`, rather than the older
`GPS BIIR-5 (PRN 22)` label. The stable ID was correct. GPS secondary checks now
accept either GPS or NAVSTAR naming while catalog ID remains authoritative.

The completed dataset is stored in both `results` for evidence and
`data/processed` as the latest reusable catalog. Task 3 does not convert the mean
elements to Cartesian states; that remains the Day 6 SGP4 boundary.
