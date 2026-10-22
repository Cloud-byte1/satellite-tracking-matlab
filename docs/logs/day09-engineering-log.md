# Day 9 Engineering Log

## Scope completed

Day 9 adds a reusable weak-field gravitational clock model, combines it with
the verified Day 8 kinematic model, applies the result to saved real and
theoretical trajectories, derives the circular-orbit zero-drift altitude, and
evaluates a time-varying elliptical orbit.

## Actual measured results

| Metric | Result |
|---|---:|
| Real satellites analyzed | 6 |
| Total timing scenarios | 9 |
| Timing samples exported | 12,969 |
| GPS gravitational correction | +45.660757 μs/day |
| GPS kinematic correction | −7.208677 μs/day |
| GPS net correction | +38.452079 μs/day |
| Difference from +38.5 μs/day | 0.047921 μs/day |
| Idealized crossover altitude | 3189.0685 km |
| Verification checks passed | 18/18 |
| Engineering figures generated | 4 PNG + 4 FIG |
| Elliptical integration error | 1.762e-16 s |
| Core analysis runtime, saved metrics run | 1.919 s |

The runtime measures the analysis and verification stage, not MATLAB startup
or graphics export. It is a reproducible desktop measurement, not an
operational performance qualification.

## Scenario results

| Scenario | GR (μs/day) | SR (μs/day) | Net (μs/day) |
|---|---:|---:|---:|
| ISS (ZARYA) | +3.708 | −28.188 | −24.480 |
| NAVSTAR 48 | +45.651 | −7.214 | +38.438 |
| NAVSTAR 51 | +45.652 | −7.213 | +38.439 |
| NOAA 20 | +6.906 | −26.570 | −19.664 |
| Landsat 9 | +5.972 | −27.036 | −21.064 |
| GOES 16 | +50.990 | −4.544 | +46.446 |
| Theoretical 500 km circular LEO | +4.367 | −27.855 | −23.488 |
| Theoretical GPS circular orbit | +45.661 | −7.209 | +38.452 |
| Theoretical 500 x 20,200 km ellipse | +37.070 | −11.555 | +25.514 |

## Verification evidence

The automated suite checks zero gravitational potential difference, sign and
altitude monotonicity, negative kinematic drift, the three GPS benchmarks,
analytical versus numerical integration, unit conversion, the circular
crossover and sign change, elliptical orbit averaging, reproducibility,
finite histories, datetime support, scenario counts, and reference-clock
documentation. All 18 checks passed.

Machine-readable evidence is stored in:

- `results/day09_verification.csv`
- `results/day09_relativistic_timing_summary.csv`
- `results/day09_relativistic_timing_timeseries.csv`
- `results/day09_portfolio_metrics.csv`
- `results/day09_general_relativity.mat`

## Limitations

The reference clock is stationary at the WGS 84 equatorial radius. The model
uses a spherical, nonrotating Earth monopole and leading terms through
order c⁻². It excludes Earth rotation, the full geopotential, tides, third
bodies, signal propagation, clock hardware behavior, and the operational GPS
time convention. Results are calculated predictions, not onboard-clock
measurements or operational GPS validation.
