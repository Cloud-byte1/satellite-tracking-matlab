# Day 8 Engineering Log

## Completed scope

- Audited Day 7 velocities, units, frame, timestamps, and finite-state behavior.
- Reused six 24-hour SGP4 J2000/FK5 velocity histories at 60-second spacing.
- Implemented a cancellation-resistant exact special-relativistic clock model.
- Implemented and compared the leading `-v^2/(2c^2)` approximation.
- Added theoretical 500 km circular, GPS circular, and elliptical scenarios.
- Integrated all clock histories and exported summary/time-series CSV files.
- Generated four PNG and four editable FIG engineering graphics.
- Ran static analysis, automated verification, `timeit`, and MATLAB profiling.

## Actual run results — 2026-10-19

| Metric | Measured result |
|---|---:|
| Orbital scenarios | 9 |
| Real satellites | 6 |
| Clock-correction samples | 12,969 |
| Theoretical GPS SR drift | -7.208677 microseconds/day |
| Difference from -7.2 benchmark | 0.008677 microseconds/day |
| Maximum exact/approximate accumulated difference | 0.004598 ps |
| Verification checks | 15/15 passed |
| Technical figures | 4 PNG + 4 FIG |
| Elliptical analytical-integration error | 8.085e-17 s |
| Elliptical relative integration error | 2.833e-11 |
| Core analysis runtime | 6.398 s |
| Reusable clock-function `timeit` result | 1.525 ms per 1,441 samples |
| MATLAB code-analyzer findings | 0 |

## Input evidence

- Frame: J2000/FK5 ECI via Vallado IAU-76/FK5 TEME conversion.
- Velocity unit: km/s.
- Time span: 2026-10-19 11:13:47 UTC through 2026-10-20 11:13:47 UTC.
- Sampling: 1,441 states per satellite at exactly 60 seconds.
- Day 7 frame-rotation orthogonality error: `5.09e-16`.
- Day 7 verification: 15/15 checks passed.

## Verification evidence

The Day 8 test suite independently checked:

1. Zero velocity gives exactly zero kinematic correction.
2. Increasing speed makes the rate more negative.
3. Seconds-to-microseconds conversions remain consistent.
4. Exact and leading-order rates agree at orbital velocities.
5. The theoretical GPS result lies near -7.2 microseconds/day.
6. Constant-speed numerical integration matches the analytical result.
7. Elliptical perigee speed exceeds apogee speed.
8. Elliptical perigee correction is more negative than at apogee.
9. One-period numerical averaging matches the analytical Kepler estimate.
10. Repeated calculations are bitwise reproducible for the tested history.
11. At least five scenarios are present.
12. At least five real satellites are integrated.
13. All histories are finite with nonpositive kinematic corrections.
14. The 60-second timestamp spacing is preserved.
15. The velocity input frame remains explicitly documented as J2000/FK5.

## Assumptions and remaining issues

- Results are model predictions, not observed spacecraft-clock telemetry.
- Only the kinematic special-relativistic term is included.
- No comparison to a moving ground reference clock is made.
- Gravitational potential, Earth rotation, geopotential harmonics, and GPS system
  coordinate-time conventions are deferred to Day 9.
- J2000/FK5 geocentric inertial coordinates provide the stated engineering
  approximation; a full precision-timing system would use relativistic reference
  systems and standards appropriate to the mission.
