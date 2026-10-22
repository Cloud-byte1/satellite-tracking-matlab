# Day 9 — Gravitational Time Dilation and Combined Satellite Clock Model

## 1. Physical interpretation

The equivalence principle states that a sufficiently small freely falling
laboratory is locally indistinguishable from an inertial laboratory without
gravity. A clock held at rest in a gravitational field is not freely falling,
and its accumulated proper time depends on gravitational potential. In the
weak field around Earth, the Newtonian potential is

\[
\Phi(r)=-\frac{GM}{r}=-\frac{\mu}{r}.
\]

Proper time, \(\tau\), is the time measured by a clock moving along its own
worldline. Coordinate time, \(t\), is the time coordinate selected for the
model. For a slowly moving clock in a weak, static gravitational field,

\[
\frac{d\tau}{dt}\approx 1+\frac{\Phi(r)}{c^2}-\frac{v^2}{2c^2}.
\]

The potential term is less negative at higher altitude, so a satellite clock
runs faster gravitationally than an otherwise stationary surface clock. The
velocity term is negative, so orbital motion makes the satellite clock run
slower. These effects are physically distinct and add at leading order.

Assumptions are \(|\Phi|/c^2\ll1\), \(v/c\ll1\), a spherical nonrotating
Earth, a static monopole potential, and terms only through order \(c^{-2}\).
Earth rotation, geopotential harmonics, tides, third bodies, signal-path
effects, and operational GPS time realization are excluded.

## 2. Reference-clock convention and gravitational derivation

This project defines the reference as an idealized stationary clock at the
WGS 84 equatorial radius, \(R_E=6378.137\) km. Comparing a satellite at radius
\(r\) with that clock gives

\[
\left(\frac{d\tau}{dt}\right)_{sat}
-\left(\frac{d\tau}{dt}\right)_{ref}
\approx \frac{\Phi(r)-\Phi(R_E)}{c^2}
=\frac{\mu}{c^2}\left(\frac{1}{R_E}-\frac{1}{r}\right).
\]

For \(r>R_E\), the expression is positive. The implementation evaluates the
equivalent, cancellation-resistant form

\[
\frac{\mu}{c^2}\frac{r-R_E}{R_Er}.
\]

The time-varying correction is integrated with `cumtrapz`, so the same
function accepts circular, elliptical, SGP4, or `ode45` trajectories. Outputs
are provided in seconds, nanoseconds, microseconds, and equivalent
microseconds per day.

## 3. GPS circular-orbit benchmark

For a 20,200 km altitude circular orbit,

- orbital radius: 26,578.137 km;
- circular speed: approximately 3.873 km/s;
- orbital period: approximately 11.978 hours;
- gravitational contribution: **+45.660757 microseconds/day**;
- kinematic contribution: **−7.208677 microseconds/day**;
- combined contribution: **+38.452079 microseconds/day**.

The difference from the familiar +38.5 microseconds/day benchmark is
0.047921 microseconds/day. This is close by design but is not a claim that the
spherical-Earth model reproduces every operational GPS correction. GPS system
time is tied to a rotating Earth geopotential reference and uses additional
relativistic and engineering corrections.

## 4. Circular-orbit crossover result

For a circular orbit, \(v^2=\mu/r\). The net leading-order satellite-minus-
stationary-surface rate is

\[
\frac{\mu}{c^2}\left(\frac{1}{R_E}-\frac{1}{r}\right)
-\frac{\mu}{2rc^2}.
\]

Setting this to zero gives

\[
r=\frac{3}{2}R_E,\qquad h=r-R_E=\frac{1}{2}R_E.
\]

Using the configured equatorial radius, the crossover altitude is
**3189.0685 km**. Circular orbits below it have negative net drift under this
reference convention; circular orbits above it have positive net drift. This
is not automatically the operational GPS reference-time crossover because
the reference clock here is idealized and stationary.

## 5. Orbital-regime and elliptical behavior

The analysis applies the same model to six real SGP4 histories and three
theoretical trajectories. LEO cases such as the ISS have a small positive
gravitational contribution and a larger negative kinematic contribution. GPS
and GEO cases have a large positive gravitational advantage and lower orbital
speed, producing positive net drift.

The 500 x 20,200 km elliptical case varies continuously. Near perigee its
potential is deeper and its speed is highest, making the net instantaneous
rate negative. Near apogee the gravitational advantage is large and the
speed penalty is small, making the net rate positive. A separate 4,001-sample
one-orbit integration agrees with the analytical orbit-average result to
1.762e-16 s absolute error.

For a bound Kepler orbit, the time averages \(\langle1/r\rangle=1/a\) and
\(\langle v^2\rangle=\mu/a\) provide the analytical verification value.

## 6. Software architecture and use

The reusable pipeline is:

`CelesTrak → SGP4/J2000 states → gravitational model + SR model → combined model → tables and figures`

Core files:

- `src/relativity/gravitationalTimeDilationModel.m`
- `src/relativity/combinedRelativisticClockModel.m`
- `src/relativity/analyzeDay09ClockScenarios.m`
- `tests/runDay09RelativityTests.m`
- `src/visualization/plotDay09RelativityFigures.m`
- `scripts/run_day09_general_relativity.m`

Run from the repository root:

```matlab
setupProject;
addpath("scripts");
outputs = run_day09_general_relativity();
```

The saved real-satellite results are theoretical predictions derived from
propagated positions and velocities. They are not direct observations of
onboard satellite clocks.
