# Day 8 — Special-Relativistic Satellite Clock Modeling

## Scope and coordinate convention

Day 8 calculates only the velocity-dependent special-relativistic contribution
to satellite proper time. It does not model gravitational time dilation, an
Earth-surface reference clock, synchronization, signal propagation, or an
observed onboard clock bias.

The sign convention is

> satellite proper time minus elapsed coordinate time.

Coordinate time is represented by elapsed SI-like seconds along the saved Day 7
trajectory, whose UTC timestamps are used to label the samples. Velocity is
measured in the Day 7 J2000/FK5 geocentric inertial realization obtained from
the Vallado TEME transformation. Over the 24-hour Earth-orbit analysis this is a
documented engineering approximation, not a complete relativistic reference
system such as GCRS/TCG.

## Proper time and the Lorentz factor

Coordinate time labels events in the selected inertial coordinate system.
Proper time is the reading of an ideal clock following the satellite. For
instantaneous speed `v`,

```text
gamma = 1/sqrt(1 - v^2/c^2)
d_tau = dt/gamma = dt sqrt(1 - v^2/c^2).
```

The satellite therefore accumulates less proper time than coordinate time when
`v > 0`. For Earth-orbiting speeds, `v/c` is small and the leading expansion is

```text
d_tau/dt approximately 1 - v^2/(2 c^2).
```

The corresponding kinematic clock-rate correction is negative:

```text
d(tau-t)/dt approximately -v^2/(2 c^2).
```

For a changing orbital speed the correction is integrated along the trajectory:

```text
Delta(tau-t) = integral [sqrt(1-v(t)^2/c^2)-1] dt.
```

Although an orbit is accelerated, this differential expression can be applied
locally along its worldline. A satellite-to-ground-clock comparison would also
require the ground clock's rotational velocity, gravitational potentials, and a
consistent relativistic coordinate-time definition.

## Numerically stable exact expression

Direct subtraction of `sqrt(1-beta^2)-1` loses precision when `beta^2` is very
small. The implementation uses the algebraically equivalent form

```text
exact rate = -beta^2/(1 + sqrt(1-beta^2)),
beta^2 = v^2/c^2.
```

The leading approximation is

```text
approximate rate = -beta^2/2.
```

Both are dimensionless seconds of clock difference per coordinate second.
`cumtrapz` integrates each sampled rate. The speed of light is
`299792.458 km/s`, matching the trajectory velocity unit without conversion.

Conversions used by the software are

```text
nanoseconds = seconds x 1e9
microseconds = seconds x 1e6
microseconds/day = dimensionless rate x 86400 x 1e6.
```

For a varying speed, the integrated daily-equivalent rate is the final integrated
correction divided by the elapsed number of days. It is not the same quantity as
extrapolating one instantaneous speed for an entire day.

## GPS benchmark

The theoretical benchmark uses a WGS-84 equatorial radius of `6378.137 km`, an
altitude of `20200 km`, and `mu = 398600.4418 km^3/s^2`. For a circular orbit,

```text
r = R_E + h
v = sqrt(mu/r)
T = 2 pi sqrt(r^3/mu).
```

The calculated radius is `26578.137 km`, speed is `3.8726 km/s`, and period is
`11.978 h`. Exact 24-hour integration gives `-7.208677 microseconds/day`, only
`0.008677 microseconds/day` from the requested `-7.2` benchmark.

This is not the total GPS correction. The positive gravitational contribution is
larger in magnitude; combining the kinematic and gravitational terms produces
the familiar net result near `+38.5 microseconds/day`. Day 9 will introduce the
gravitational term with an explicit reference potential.

## Real and theoretical results

Six real SGP4 histories and three theoretical scenarios were integrated. Values
below are satellite proper time minus coordinate time over the actual 24-hour
analysis interval.

| Scenario | Mean speed (km/s) | Period (h) | SR drift (microseconds/day) |
|---|---:|---:|---:|
| ISS | 7.6579 | 1.5516 | -28.188 |
| NAVSTAR 48 | 3.8738 | 11.967 | -7.2135 |
| NAVSTAR 51 | 3.8736 | 11.968 | -7.2132 |
| NOAA-20 | 7.4349 | 1.6883 | -26.570 |
| Landsat 9 | 7.4998 | 1.6436 | -27.036 |
| GOES-16 | 3.0747 | 23.936 | -4.5442 |
| Theoretical 500 km circular LEO | 7.6126 | 1.5769 | -27.855 |
| Theoretical GPS circular orbit | 3.8726 | 11.978 | -7.2087 |
| Theoretical 500 x 20,200 km ellipse | 4.4455 mean | 5.9811 | -11.555 |

The real-satellite values are model predictions based on SGP4 state vectors. They
must not be represented as measurements of onboard clocks.

## Elliptical orbit

The elliptical demonstration uses a 500 km perigee and 20,200 km apogee. Its
speed follows the vis-viva equation

```text
v^2 = mu (2/r - 1/a).
```

The speed is `9.5956 km/s` at perigee and `2.4832 km/s` at apogee. Kepler's
second law requires the spacecraft to move fastest near perigee, so the
instantaneous kinematic clock correction is most negative there. Its perigee
instantaneous equivalent reaches `-44.2574 microseconds/day`.

For a Kepler ellipse, the orbit-averaged identity `<v^2> = mu/a` gives the
leading-order analytical correction

```text
Delta(tau-t) approximately -mu T/(2 a c^2).
```

The independently sampled numerical integral over one complete period agrees
with this result to a relative error of `2.83e-11`, corresponding to an absolute
error of `8.09e-17 s`.

## Pipeline integration

The implemented data path is

```text
CelesTrak record
    -> Vallado SGP4 TEME position and velocity
    -> TEME-to-J2000/FK5 transformation
    -> stable special-relativistic clock-rate model
    -> numerical proper-time integration
    -> CSV, MAT, figures, and verification results.
```

Saved Day 7 states are reused, avoiding redundant retrieval, frame conversion,
and propagation. The time-series calculation is vectorized, scenario arrays are
preallocated, and only the elliptical theoretical orbit requires a new `ode45`
integration.

## Verification and performance

The run passed 15 independent checks covering zero velocity, monotonic speed
behavior, unit conversion, exact/approximate agreement, the GPS benchmark,
constant-speed integration, elliptical dynamics, analytical orbit averaging,
reproducibility, frame documentation, timestamp spacing, and finite signs.

The maximum accumulated exact-versus-approximate difference was `0.004598 ps`.
Core analysis runtime was `6.398 s`; `timeit` measured the reusable clock function
at `1.525 ms` for a 1,441-sample trajectory. MATLAB profiling information is
stored in `results/day08_special_relativity.mat` for later optimization work.

## Engineering interpretation

- Satellite clocks experience kinematic time dilation because their worldlines
  contain spatial motion relative to the selected coordinate frame.
- The leading correction scales with `-v^2`, so faster LEO spacecraft have a
  larger negative correction than GPS or GEO spacecraft.
- GPS's special-relativistic contribution is negative because orbital motion
  makes satellite proper time accumulate more slowly.
- Eccentricity makes speed and instantaneous clock rate vary around the orbit;
  the correction is strongest near perigee and weakest near apogee.
- Special relativity alone cannot predict GPS clock behavior because gravity,
  Earth rotation, reference-time definitions, and signal processing also matter.
- Modeling each contribution separately makes precision-navigation error budgets
  traceable and connects Lorentz-factor physics directly to aerospace systems.

## Reproduction

From the repository root:

```matlab
setupProject;
addpath("scripts");
outputs = run_day08_special_relativity();
```

Set `ShowFigures=false` for unattended execution. Day 8 uses the saved Day 7 MAT
file and does not download new orbital records.
