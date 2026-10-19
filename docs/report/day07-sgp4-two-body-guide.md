# Day 7 — SGP4 Versus Newtonian Two-Body Prediction

## Purpose and interpretation

This experiment compares two predictions initialized from the same Cartesian
state. The difference is **model disagreement**, not independently measured
tracking error. Establishing absolute accuracy would require an external precise
ephemeris, tracking observations, or another suitable truth source.

## Why the models differ

The custom two-body model integrates

\[
\ddot{\mathbf r}=-\mu\frac{\mathbf r}{\lVert\mathbf r\rVert^3}
\]

with `ode45`. It includes only point-mass Earth gravity. SGP4 is an analytical
general-perturbations model designed for GP/TLE mean elements. It contains the
effects represented by its theory, including secular and periodic effects from
Earth oblateness and a simplified drag model. It does not constitute a complete
high-fidelity force model: third-body gravity, solar radiation pressure, detailed
atmospheric density, maneuvers, and element-estimation uncertainty are not
independently modeled here.

Consequently, the observed difference can contain multiple coupled causes:

- omitted nonspherical Earth gravity in the two-body model;
- simplified drag and GP mean-element behavior in SGP4;
- different sensitivity by altitude, inclination, and eccentricity;
- uncertainty and age of the distributed element set;
- numerical error in `ode45` (bounded here with tight tolerances);
- residual uncertainty in time and coordinate transformations.

The experiment does not isolate any one physical effect, so the curves must not
be attributed exclusively to drag or J2.

## Common initial state and frame

Each CelesTrak OMM record is initialized directly in the tested Vallado SGP4
implementation. SGP4 is evaluated at the common UTC start time to obtain TEME
position and velocity. TEME is not equated with J2000, GCRF, or Earth-fixed
coordinates.

The state is converted with Vallado's IAU-76/FK5 transformation:

1. UTC is converted to TT using `TT = UTC + (TAI-UTC) + 32.184 s`.
2. `TAI-UTC`, `dPsi`, and `dEpsilon` come from the downloaded CelesTrak EOP file.
3. The IAU-1980 nutation series and IAU-76 precession model rotate TEME into a
   J2000/FK5 mean-equator/equinox inertial realization.
4. The converted SGP4 state at the first sample initializes `ode45` exactly.
5. Every later SGP4 state is independently converted at the same UTC timestamp.

This is explicitly labeled **J2000/FK5 ECI**, not exact modern GCRF/ICRF. The
legacy transformation is internally consistent with the Vallado SGP4 reference
software and is appropriate for this model-disagreement study. Higher-accuracy
work should use current IAU 2006/2000A reductions and validated Earth-orientation
software.

Both models use the WGS-72 central gravitational parameter,
`398600.8 km^3/s^2`, so an avoidable constant mismatch does not dominate the
comparison. The numerical integration uses relative tolerance `1e-11`, absolute
tolerance `1e-12`, and maximum internal step 60 s.

## Difference and RTN definitions

The signed Cartesian difference is

\[
\Delta\mathbf r=\mathbf r_{two-body}-\mathbf r_{SGP4}.
\]

The SGP4 state defines the reference RTN basis:

\[
\hat{\mathbf R}=\frac{\mathbf r}{\lVert\mathbf r\rVert},\qquad
\hat{\mathbf N}=\frac{\mathbf r\times\mathbf v}
{\lVert\mathbf r\times\mathbf v\rVert},\qquad
\hat{\mathbf T}=\hat{\mathbf N}\times\hat{\mathbf R}.
\]

The components are dot products of `Delta r` with `R`, `T`, and `N`. Positive
radial is outward, positive along-track follows `T`, and positive cross-track
follows orbital angular momentum. Reconstruction and orthogonality are tested
numerically.

## Reproducible workflow

```matlab
setupProject;
addpath("scripts");
outputs = run_day07_sgp4_two_body_comparison();
```

Use `ForceRefresh=true` only when new CelesTrak records are required. The default
cache behavior avoids unnecessary provider requests.

## Engineering interpretation

The completed run shows substantially faster disagreement growth for the selected
LEO spacecraft than for the GPS and GEO examples. Along-track growth dominates
several 24-hour cases, which is consistent with phase error accumulating when
perturbations change mean motion and orbital-plane behavior. Cross-track
oscillations are also prominent for some inclined LEO trajectories. These trends
are useful for choosing refresh cadence and warning users when a simplified model
is being displayed, but they are not accuracy rankings without external truth.

Detailed measured results are recorded in
`docs/logs/day07-engineering-log.md` and the CSV files in `results`.
