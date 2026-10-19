# Day 4 Numerical Verification Guide

## Readiness assessment

The Day 1–3 propagator is ready for systematic numerical verification. The
two-body acceleration, kilometre-second units, state ordering, `ode45` output,
orbital-element conversions, and prior comparisons are internally consistent.
Day 3 passed 12 of 12 checks in MATLAB R2026b.

Two capabilities must be added during Day 4:

1. `propagateTwoBody` currently accepts one scalar absolute tolerance. Task 3
   should add a six-component tolerance vector so position and velocity states can
   use dimensionally appropriate thresholds.
2. `orbitDiagnostics` calculates energy and angular-momentum magnitudes, but it
   does not report complete deviation histories, angular-momentum vector errors,
   or runtime. Tasks 1–3 will add these without breaking the existing interface.

## Day 4 roadmap

| Task | Deliverable | Estimated focused-work time | Status |
|---:|---|---:|---|
| 1 | Energy analysis, plot, CSV, and checks | 45–60 min | Complete |
| 2 | Angular-momentum vector/magnitude analysis and plot | 45–60 min | Pending |
| 3 | Four-level tolerance convergence study with runtime | 60–90 min | Pending |
| 4 | Consolidated suite of 10+ distinct physics tests | 60 min | Pending |
| 5 | Systematic 100+ run simulation campaign | 75–120 min | Pending |
| 6 | Performance/sensitivity figures and final log | 60–90 min | Pending |

## Task 1: conservation of specific orbital energy

For a satellite of mass `m`, total Newtonian mechanical energy is kinetic plus
gravitational potential energy:

```text
E = (1/2) m v^2 - mu m/r.
```

Dividing by `m` gives the specific orbital energy:

```text
epsilon = v^2/2 - mu/r.
```

Its units in this project are `km^2/s^2`. For a bound two-body ellipse it is also

```text
epsilon = -mu/(2a).
```

Because the ideal force is conservative and time-independent, `epsilon` must be
constant. A numerical solution will show small nonzero differences caused by
finite-precision arithmetic, adaptive step selection, local truncation error, and
interpolation onto the requested output times.

`energyConservationAnalysis` retains the complete energy and drift histories and
reports initial energy, final energy, signed final difference, maximum absolute
difference, maximum relative drift, and final relative drift. The plot uses a
logarithmic vertical axis because the errors span orders of magnitude and zero
deviation is displayed at machine epsilon.

Energy conservation is a verification diagnostic, not validation against reality.
A numerically perfect two-body trajectory can still disagree with a real satellite
because J2, atmospheric drag, third-body gravity, solar pressure, maneuvers, and
measurement uncertainty are absent.
