# Day 1 Foundation Guide

## What the simulation solves

The satellite state is

```text
y = [x, y, z, vx, vy, vz]^T.
```

Newtonian gravity supplies the acceleration

```text
a = -(mu/r^3) r_vector,
```

which produces the six first-order equations required by MATLAB's ordinary
differential-equation solvers. See `assumptions.md` for the complete derivation.

For the 500 km circular case,

```text
r0 = R_E + 500 km
v0 = sqrt(mu/r0)
y0 = [r0, 0, 0, 0, v0, 0]^T.
```

Position and velocity are perpendicular. Their orientation places the orbit in the
ECI x-y plane, while their magnitudes make it circular.

## MATLAB functions and why they are used

- `ode45`: adaptive Dormand-Prince Runge-Kutta integration for smooth, non-stiff
  initial-value problems.
- `odeset`: specifies numerical error tolerances and the maximum internal step.
- `linspace`: creates requested output times spanning one analytical period.
- Anonymous function `@(t,y)`: supplies `mu` to the dynamics function while keeping
  the interface expected by `ode45`.
- `norm` and `vecnorm`: compute position, velocity, and error magnitudes.
- `cross`: calculates specific angular momentum from `r cross v`.
- `struct`: packages related outputs without depending on base-workspace variables.
- `table` and `writetable`: create auditable CSV summaries and test evidence.
- `save`: preserves the complete MATLAB state history and metadata in a MAT-file.
- `plot`, `plot3`, `surf`, and `sphere`: provide standard interactive 2D and 3D
  MATLAB visualization functions.

## Verification logic

Visual circularity is not sufficient evidence. The automated tests require:

| Check | Acceptance tolerance | Measured result |
|---|---:|---:|
| Initial speed vs. circular formula | <= 1e-12 km/s | 0 km/s |
| Requested period endpoint | <= 1e-10 s | 0 s |
| One-orbit position closure | <= 1e-4 km | 1.702793e-7 km |
| One-orbit velocity closure | <= 1e-7 km/s | 1.838379e-10 km/s |
| Relative energy drift | <= 1e-9 | 6.294391e-12 |
| Relative angular-momentum drift | <= 1e-9 | 3.147138e-12 |
| Position difference from tighter run | <= 1e-3 km | 1.682975e-7 km |

All seven checks passed in the recorded Day 1 execution.

The closure tests ask whether the numerical state returns to its initial value after
one analytical period. Conservation tests evaluate invariants of the ideal two-body
problem. The convergence test compares the production integration with a tighter
tolerance and smaller maximum step; it does not assume the production solution is
exact.

## Common mistakes and debugging strategy

1. **Unit mismatch:** `mu` in km^3/s^2 requires position in km and velocity in km/s.
   A metre-kilometre mismatch radically changes the orbit.
2. **Using altitude as orbital radius:** gravity uses distance from Earth's center,
   so calculate `r = R_E + h`.
3. **Incorrect exponent:** vector gravity is `-mu*rVector/norm(rVector)^3`, not
   `-mu*rVector/norm(rVector)^2`.
4. **Row/column mismatch:** the initial state must be a 6-by-1 column vector for the
   documented interface.
5. **Nonperpendicular circular initial conditions:** check `dot(r0,v0)` is zero.
6. **Loose tolerances:** a trajectory may look circular while energy and final-state
   errors are unacceptable. Inspect the CSV test evidence.
7. **Confusing output spacing with solver steps:** `ode45` takes adaptive internal
   steps and interpolates to requested output times.
8. **Depending on base-workspace variables:** functions receive every required input
   explicitly so tests remain reproducible.

## Independent engineering challenges

These are extensions, not claimed accomplishments:

1. Change the initial orbital plane to a 51.6-degree inclination without changing
   the circular speed. Verify that energy and angular momentum magnitude remain
   conserved.
2. Propagate for ten periods and quantify whether closure error grows linearly.
3. Repeat the production run with relative tolerances `1e-6`, `1e-8`, `1e-10`, and
   `1e-12`; plot final position error against tolerance on logarithmic axes.
4. Increase velocity by 2 percent and use the resulting radius history to explain
   why the trajectory becomes elliptical.

Each extension should become a new scripted scenario and should update metrics only
after its automated checks have actually run.

