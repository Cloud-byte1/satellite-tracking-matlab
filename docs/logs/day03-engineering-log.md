# Day 3 Engineering Log

Date: 2026-10-18

## Objective

Extend the verified two-body propagator into a reusable multi-scenario orbital
simulation framework with classical-element conversion, 3D visualization,
comparative analysis, and explicit engineering verification.

## Completed work

- [x] Reviewed and preserved the Day 1–2 implementation.
- [x] Defined six idealized orbit scenarios.
- [x] Implemented validated classical-elements-to-ECI conversion.
- [x] Implemented ECI-state-to-classical-elements recovery.
- [x] Propagated every scenario for one analytical Kepler period using `ode45`.
- [x] Calculated periods, apsis altitudes, speed extrema, energy, angular momentum,
  eccentricity, invariant drift, and one-period closure.
- [x] Exported a professional interactive FIG and static PNG comparison.
- [x] Executed 12 automated Day 3 verification checks in MATLAB R2026b.

## Quantitative orbit results

These values were produced by executing `run_day03_advanced_orbits.m` in MATLAB
R2026b on 2026-10-18. Full precision is preserved in
`results/day03_orbit_comparison.csv` and complete states in
`results/day03_simulations.mat`.

| Scenario | Period (min) | Perigee altitude (km) | Apogee altitude (km) | Minimum speed (km/s) | Maximum speed (km/s) |
|---|---:|---:|---:|---:|---:|
| LEO 500 km | 94.616 | 500.000 | 500.000 | 7.6126 | 7.6126 |
| GPS-like MEO | 717.963 | 19,916.263 | 20,447.463 | 3.8354 | 3.9129 |
| Geostationary | 1,436.060 | 35,785.863 | 35,785.863 | 3.0747 | 3.0747 |
| Elliptical e=0.30 | 161.554 | 500.000 | 6,395.546 | 4.6737 | 8.6797 |
| High-e Molniya-like | 719.585 | 537.863 | 39,905.863 | 1.4964 | 10.0142 |
| Inclined 98 deg | 105.119 | 1,000.000 | 1,000.000 | 7.3501 | 7.3501 |

## Verification results

- Tests passed: **12 of 12**.
- Largest COE/state round-trip position error: `5.16494e-12 km`.
- LEO circular-speed error: `8.88178e-16 km/s`.
- Largest perigee-altitude error: `2.50475e-9 km`.
- Largest apogee-altitude error: `2.94356e-7 km`.
- Largest vis-viva speed-extrema error: `8.66018e-12 km/s`.
- Largest eccentricity-recovery error: `6.66134e-16`.
- Largest one-period position-closure error: `3.62113e-6 km`.
- Largest relative specific-energy drift: `3.25423e-11`.
- Largest relative angular-momentum drift: `5.81483e-12`.

Every measured value satisfied its explicit tolerance. The authoritative per-test
evidence is `results/day03_verification.csv`.

## Physical interpretation

- Circular LEO has the shortest period and higher speed than the circular MEO and
  GEO cases because it lies deeper in Earth's potential well.
- The GPS-like MEO period is approximately 12 hours, consistent with its larger
  semimajor axis.
- The ideal GEO case has a period close to one sidereal day and is circular and
  equatorial; Earth-fixed longitude is not modeled yet.
- The moderate ellipse demonstrates the expected perigee/apogee speed difference.
- The high-eccentricity case has the widest altitude and speed range: it moves
  rapidly through perigee and slowly near apogee.
- The 98-degree case changes orbital-plane orientation without changing the
  circular-orbit speed relationship.

## Evidence files

- `results/day03_orbit_comparison.csv`
- `results/day03_verification.csv`
- `results/day03_simulations.mat`
- `figures/day03_multiple_orbits_3d.fig`
- `figures/day03_multiple_orbits_3d.png`

## Unresolved issues and next actions

- The Day 3 trajectories remain ideal two-body simulations; J2, drag, third-body
  effects, and maneuvers are not included.
- “Geostationary” has not yet been demonstrated in an Earth-fixed frame.
- Live CelesTrak retrieval and parsing from Day 2 remain incomplete.
- SGP4 propagation, real-satellite comparison, animation, relativity, dashboard,
  100+ simulations, and the final report/video remain future milestones.
- The combined plot spans GEO-scale distances, so the saved FIG should be used to
  zoom into LEO details when presenting the visualization interactively.
