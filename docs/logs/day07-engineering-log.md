# Day 7 Engineering Log

Date: 2026-10-19

## Objective

Quantify reproducible SGP4-versus-Newtonian-two-body model disagreement for real
satellite records at 1, 6, and 24 hours in one consistently transformed inertial
frame.

## Dependency and data acquisition

- Downloaded current CelesTrak `EOP-Last5Years.csv` for Earth-orientation and
  leap-second data.
- Downloaded the official CelesTrak/Vallado
  `fundamentals-of-astrodynamics` repository at commit
  `49df0479c950917c0a2c5ac31f2db6477bba57f6`.
- Preserved the upstream AGPL-3.0 license and copied only the unmodified MATLAB
  frame routines and IAU-1980 nutation coefficient file required by this project.
- Refreshed six OMM-compatible CelesTrak GP records by NORAD catalog ID.

## Completed implementation

- [x] Verified SGP4 against the published Vallado epoch state.
- [x] Converted SGP4 TEME states to J2000/FK5 ECI using EOP corrections.
- [x] Initialized `ode45` from the converted SGP4 state exactly.
- [x] Used identical UTC timestamps and WGS-72 `mu` in both model paths.
- [x] Propagated LEO, MEO, and GEO examples for 24 hours at 60-second output spacing.
- [x] Calculated Cartesian, magnitude, velocity, and RTN differences.
- [x] Exported 18 satellite-horizon cases and 8,646 time-series rows.
- [x] Passed 15 comparison verification checks and 3 SGP4 reference checks.
- [x] Generated four PNG figures and four editable MATLAB FIG files.

## Measured results

| Metric | Actual value |
|---|---:|
| Satellites analyzed | 6 |
| Orbital regimes | 3 (LEO, MEO, GEO) |
| Prediction horizons | 3 (1, 6, 24 h) |
| Satellite-horizon cases | 18 |
| Common trajectory samples per satellite | 1,441 |
| Exported time-series rows | 8,646 |
| Analysis runtime | 40.233 s |
| Published SGP4 reference checks | 3/3 passed |
| Day 7 verification checks | 15/15 passed |
| Technical figures | 4 PNG + 4 FIG |
| Largest 24 h separation | 1,905.848 km (NOAA-20) |
| NOAA-20 24 h RMS separation | 1,114.748 km |

### Twenty-four-hour results

| Satellite | Regime | Final separation (km) | RMS (km) | Final R (km) | Final T (km) | Final N (km) |
|---|---|---:|---:|---:|---:|---:|
| ISS (ZARYA) | LEO | 1,072.879 | 591.652 | -74.421 | -965.949 | 460.949 |
| NAVSTAR 48 (USA 151) | MEO | 33.119 | 19.069 | 0.244 | -29.488 | 15.075 |
| NAVSTAR 51 (USA 166) | MEO | 14.211 | 8.057 | -0.130 | 11.255 | -8.675 |
| NOAA 20 (JPSS-1) | LEO | 1,905.848 | 1,114.748 | -266.603 | 1,883.285 | 120.070 |
| LANDSAT 9 | LEO | 443.795 | 250.309 | -7.443 | -427.904 | 117.460 |
| GOES 16 | GEO | 14.131 | 9.473 | -0.005 | -14.049 | 1.518 |

The largest absolute NOAA-20 RTN components over 24 hours were 266.603 km radial,
1,883.285 km along-track, and 120.070 km cross-track. The largest disagreement is
therefore primarily along-track in this experiment.

## Verification evidence

- Initial position mismatch: `0 km`.
- Initial velocity mismatch: `0 km/s`.
- Nonzero SGP4 error codes: `0`.
- Maximum frame-rotation orthogonality error: `3.24e-16`.
- Maximum RTN-basis orthogonality error: `5.30e-16`.
- Maximum RTN reconstruction error: `9.17e-13 km`.
- Repeated two-body propagation mismatch: `0` in stored state units.
- MATLAB code-analyzer findings in project-authored Day 7 files: `0`.

## Interpretation and limitations

The selected LEO cases separate much faster than the MEO and GEO cases, but the
spacecraft-specific differences show why the result cannot be reduced to altitude
alone. The curves combine all differences between SGP4's general-perturbations
theory and an ideal point-mass model. They do not isolate drag, J2, maneuvers, or
element-estimation uncertainty.

The result is not an independently measured orbit-prediction error. No precise
ephemeris or tracking observations were used as truth. The common frame is the
Vallado IAU-76/FK5 J2000 realization; it is deliberately not labeled exact GCRF.
The CelesTrak element epochs were 5.4–9.8 hours old at retrieval, which is retained
in the exported catalog for provenance.

## Evidence

- `results/day07_sgp4_two_body_metrics.csv`
- `results/day07_sgp4_two_body_timeseries.csv`
- `results/day07_verification.csv`
- `results/day07_satellite_catalog.csv`
- `results/day07_sgp4_two_body_comparison.mat`
- `figures/day07_trajectory_comparison.png`
- `figures/day07_position_separation.png`
- `figures/day07_rtn_components.png`
- `figures/day07_regime_comparison.png`

## Sources

- CelesTrak GP data: <https://celestrak.org/NORAD/documentation/gp-data-formats.php>
- Vallado SGP4 reference: <https://celestrak.org/publications/AIAA/2006-6753/>
- CelesTrak EOP documentation: <https://celestrak.org/spacedata/EOP-format.php>
- Vallado astrodynamics software: <https://celestrak.org/software/vallado-sw.php>
