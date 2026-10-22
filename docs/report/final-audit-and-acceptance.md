# Final audit and acceptance review

**Acceptance run:** 2026-10-21, MATLAB R2026b
**Evidence:** `results/final_engineering_sprint.mat`, CSV exports, and six `figures/final_*` PNG/FIG pairs

## Initial audit

| Requirement | Status | Evidence and limitation |
|---|---|---|
| CelesTrak retrieval and cache | PASS | Validated HTTPS retrieval, typed parsing, provenance, two-hour fresh-cache behavior, and stale-cache fallback are covered by six passing Day 5 offline tests. |
| At least five real satellites | PASS | Six records are present: ISS, two NAVSTAR spacecraft, NOAA-20, Landsat 9, and GOES-16. |
| Native `satelliteScenario` | PASS | Five cached TLE records passed eight native-toolbox checks; the viewer and observation panel are implemented. |
| Vallado SGP4 propagation | PASS | Three published reference cases and all real-record SGP4 status codes passed. |
| `ode45` two-body propagation | PASS | The final campaign completed 120/120 full-orbit runs. |
| 1-, 6-, and 24-hour comparison | PASS | Eighteen satellite/horizon cases and 8,646 time-series rows are exported. |
| RTN decomposition | PASS | Reconstruction closure was 9.444e-13 km. |
| Special relativity | PASS | GPS kinematic result was -7.208677 microseconds/day. |
| Gravitational relativity | PASS | GPS gravitational result was +45.660757 microseconds/day. |
| GPS net correction | PASS | The result was +38.452079 microseconds/day, 0.1245% from +38.5. |
| 100+ automated simulations | PASS | 120/120 deterministic simulations passed. |
| 10+ meaningful final checks | PASS | 17/17 consolidated checks passed; no tests were failed or skipped. |
| Real-data dashboard | PASS | The dashboard reads saved real SGP4/J2000 histories and Day 9 timing results; it does not substitute display-only trajectories. |

No `.mlx` or `.mlapp` files were present. The application is implemented as MATLAB functions and a programmatic `uifigure` dashboard. No source file was found to be syntactically broken during the final acceptance run.

## Final measured results

| Metric | Measured result |
|---|---:|
| Maximum two-body–SGP4 position separation | 1,781.797863 km |
| Global RMS position separation | 575.823254 km |
| Maximum relative energy drift | 6.0711e-10 |
| Maximum relative angular-momentum drift | 3.0380e-10 |
| Tightest 6-hour convergence difference | 0.0001157 m |
| GPS net relativistic correction | +38.452079 microseconds/day |
| Successful campaign simulations | 120/120 |
| Consolidated verification checks | 17/17 |
| Hidden-UI cold dashboard startup | 20.166 s |
| Dashboard snapshot update latency | 0.884 ms |

The position separation is **model disagreement**, not independently validated orbit error. SGP4 contains perturbation behavior that the point-mass two-body model intentionally omits, so separation grows with prediction horizon, particularly for LEO cases.

## Reliability review

| Condition | Status | Evidence or remaining work |
|---|---|---|
| Missing internet / failed request | PASS | Automated Day 5 test confirms fallback to a valid stale cache. |
| Stale orbital records | PASS | Cache age and retrieval time are retained separately; stale fallback is labeled. Operational age limits remain a user decision. |
| Invalid timestamps | PASS | Relativity models require strictly increasing time and timezone-aware datetimes. |
| Missing toolbox dependencies | NOT TESTED | Base-MATLAB analysis is independent; native globe launch still requires Satellite Communications Toolbox. A clean MATLAB install without that toolbox was not available. |
| Satellite selection errors | PASS | Dashboard snapshot construction validates catalog bounds and reports a named error. |
| Unsupported/malformed records | PASS | The Day 5 malformed-response test passed. |
| Dashboard shutdown and cleanup | NOT TESTED | Hidden startup and data updates were automated; interactive close behavior was not manually exercised in this headless acceptance run. |
| Live provider availability on acceptance date | NOT TESTED | Final acceptance intentionally used cached records for reproducibility. |

## Final acceptance checklist

| Deliverable | Status |
|---|---|
| Working source code | PASS |
| Functional dashboard | PASS |
| Real satellite orbital data | PASS |
| SGP4 and `ode45` propagation | PASS |
| Relativistic physics calculations | PASS |
| 100+ simulation campaign | PASS |
| Consolidated verification results | PASS |
| Six exported engineering figures | PASS |
| Technical report | PASS |
| GitHub README | PASS |
| Demonstration plan | PASS |
| Resume entry | PASS |

## Known limitations

- Cached element epochs are from 2026-10-18/19 and are evidence for the reproducible acceptance run, not current operational tracking.
- The two-body model excludes drag, oblateness, lunisolar gravity, radiation pressure, and maneuver estimation.
- The TEME-to-J2000 conversion uses the documented Vallado IAU-76/FK5 path and CelesTrak Earth-orientation data; it is not a full modern IAU 2006/2000A reduction.
- The clock model uses a spherical, nonrotating Earth and a stationary equatorial surface reference. It excludes geopotential harmonics, Earth rotation, tides, signal path delays, and the operational GPS time realization.
- No independently surveyed truth ephemeris was used. Model separation must not be labeled tracking accuracy.
