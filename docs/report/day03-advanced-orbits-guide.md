# Day 3 Advanced-Orbits Guide

## Starting point and scope

The existing Day 1 implementation already supplied a verified kilometre-second
two-body model and reusable `ode45` propagator. Day 2 Task 1 supplied a CelesTrak
configuration and five-satellite catalog, but it did not yet retrieve or propagate
live data. Day 3 therefore extends the verified ideal two-body framework; it does
not claim SGP4 or real-satellite tracking.

## Roadmap and estimated focused-work time

| Sequence | Task | Estimated time |
|---:|---|---:|
| 1 | Define six physically distinct scenarios | 30 min |
| 2 | Implement and explain COE-to-ECI conversion | 60 min |
| 3 | Propagate and analyze every scenario | 60 min |
| 4 | Build and inspect the multi-orbit 3D figure | 45 min |
| 5 | Implement verification and regression checks | 45 min |
| 6 | Record results, limitations, and usage | 30 min |

## Task 1: what changes an orbit

The six scenarios are defined in `config/day03OrbitScenarios.m`.

- **Altitude and semimajor axis:** A larger semimajor axis increases orbital size
  and period. Kepler's third law gives `T = 2*pi*sqrt(a^3/mu)`, so period grows as
  `a^(3/2)`.
- **Eccentricity:** `e = 0` is circular. As `e` grows, the perigee and apogee
  radii separate according to `r_p = a(1-e)` and `r_a = a(1+e)`.
- **Inclination:** Inclination rotates the orbital plane relative to Earth's
  equatorial plane. It changes orientation, not ideal two-body energy or period.
- **Velocity:** The vis-viva equation, `v^2 = mu*(2/r - 1/a)`, shows that a
  satellite in an ellipse is fastest at perigee and slowest at apogee.
- **RAAN and argument of periapsis:** These rotate the orbital plane and ellipse
  in inertial space. They do not change orbit size, shape, energy, or period.

The scenarios include a 500 km LEO, GPS-like MEO, circular geostationary orbit,
moderate ellipse, high-eccentricity Molniya-like geometry, and a 98-degree circular
inclined orbit. The term “geostationary” here describes ideal circular equatorial
two-body geometry; Earth-fixed stationarity requires an ECI-to-ECEF transformation
and Earth rotation, which are outside the Day 3 model.

## Task 2: the six classical orbital elements

| Element | Symbol | Physical meaning |
|---|---|---|
| Semimajor axis | `a` | Orbit size and energy |
| Eccentricity | `e` | Shape: circular at zero, increasingly elliptical toward one |
| Inclination | `i` | Tilt of the orbital plane from Earth's equator |
| Right ascension of ascending node | `Omega` | Inertial direction of the ascending-node line |
| Argument of periapsis | `omega` | Periapsis direction measured in the orbital plane |
| True anomaly | `nu` | Satellite position measured from periapsis |

The reusable `orbitalElementsToState` function first calculates the semilatus
rectum and the perifocal-frame state:

```text
p = a(1-e^2)
r_PQW = p/(1 + e*cos(nu)) [cos(nu), sin(nu), 0]^T
v_PQW = sqrt(mu/p) [-sin(nu), e + cos(nu), 0]^T
```

It then rotates both vectors into ECI coordinates:

```text
r_ECI = R3(Omega) R1(i) R3(omega) r_PQW
v_ECI = R3(Omega) R1(i) R3(omega) v_PQW
```

Inputs use kilometres, seconds, and degrees. Validation rejects missing fields,
nonfinite values, nonpositive semimajor axes, non-elliptic eccentricities, and
inclinations outside 0–180 degrees. The inverse `stateToOrbitalElements` routine
recovers elements and explicitly handles circular/equatorial angle singularities
with conventional zero-angle choices.

## Task 3: 3D visualization

`plotMultipleOrbits3D` draws a spherical Earth, all six ECI trajectories, initial
satellite markers, and velocity-direction arrows. Equal axis scaling prevents
geometric distortion. The title identifies the common idealized initial epoch,
and each path spans exactly one orbit period. Colors are fixed by configuration so
the same scenario remains recognizable across runs.

The large GEO and Molniya-like extents necessarily make LEO paths appear close to
Earth in the combined view. The saved MATLAB FIG remains interactive for zooming
and rotation, while the PNG provides a reproducible portfolio image.

## Task 4: orbital analysis

For an elliptic orbit, the analytical quantities are:

```text
T       = 2*pi*sqrt(a^3/mu)
r_p     = a(1-e)
r_a     = a(1+e)
epsilon = -mu/(2a)
h       = sqrt(mu*a*(1-e^2))
v       = sqrt(mu*(2/r - 1/a))
```

`analyzeEllipticOrbit` computes these values, extracts numerical extrema from the
propagated history, calculates energy and angular-momentum drift, measures
one-period closure, and recovers eccentricity from the initial Cartesian state.
The comparison table is written to `results/day03_orbit_comparison.csv`.

## Task 5: engineering verification

`runDay03Tests` records 12 checks in `results/day03_verification.csv`. The most
important tolerance choices are:

- `1e-4 km` for perigee/apogee agreement: 0.1 mm is far below the fidelity of the
  point-mass model while remaining comfortably above floating-point noise.
- `1e-7 km/s` for vis-viva extrema: 0.1 mm/s is stringent for this educational
  numerical propagation.
- `1e-2 km` for one-period closure: a 10 m bound across all six cases, including
  the high-eccentricity orbit where integration is most demanding.
- `1e-9` relative drift for energy and angular momentum: strict enough to detect
  solver degradation while consistent with the selected `ode45` tolerances.
- `1e-12` eccentricity error for state recovery: this is an algebraic conversion
  at the initial state rather than a long-duration propagation metric.

The complete measured values belong in the engineering log and CSV evidence, not
in this explanatory guide.

## Run and inspect incrementally

For teaching or debugging, execute in this order:

```matlab
setupProject
constants = earthConstants();
scenarios = day03OrbitScenarios(constants.radiusEarth);
[r0, v0] = orbitalElementsToState(scenarios(1), constants.muEarth);
period = 2*pi*sqrt(scenarios(1).aKm^3/constants.muEarth);
solution = propagateTwoBody([r0; v0], linspace(0,period,721).', ...
    constants.muEarth, MaximumStep=period/720);
diagnostics = orbitDiagnostics(solution)
```

After inspecting one case, run the complete reproducible workflow with
`run_day03_advanced_orbits`.
