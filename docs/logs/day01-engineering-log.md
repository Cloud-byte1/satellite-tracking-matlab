# Day 1 Engineering Log

Date: 2026-10-14

## Objective

Establish the Newtonian two-body model, implement and verify a reusable MATLAB `ode45` propagator, and simulate a 500 km circular Earth orbit.

## Completed work

- [x] Established professional MATLAB project structure.
- [x] Defined constants and modeling assumptions.
- [x] Derived the six-state two-body equations.
- [x] Implemented reusable `ode45` propagation functions.
- [x] Simulated the 500 km circular orbit.
- [x] Generated 2D and 3D trajectory figures.
- [x] Calculated circular velocity, period, and specific orbital energy.
- [x] Completed seven numerical verification checks.

## Quantitative results

Results below were measured by executing `run_day01_circular_orbit.m` with MATLAB
R2026b on 2026-10-14. The evidence files are `results/day01_summary.csv`,
`results/day01_verification.csv`, and `results/day01_simulation.mat`.

| Metric | Value | Units | Evidence |
|---|---:|---|---|
| Physical scenarios completed | 1 | scenario | 500 km circular orbit |
| Numerical propagations completed | 2 | runs | Production and tighter-reference runs |
| Verification tests passed | 7 of 7 | tests | `day01_verification.csv` |
| Circular velocity | 7.612608173 | km/s | Analytical circular-orbit calculation |
| Orbital period | 5676.978029 | s | Analytical circular-orbit calculation |
| Orbital period | 94.616300 | min | Analytical circular-orbit calculation |
| Specific orbital energy | -28.975901600 | km^2/s^2 | Analytical and numerical calculation |
| Maximum relative energy drift | 6.294391e-12 | dimensionless | Propagated state history |
| Maximum relative angular-momentum drift | 3.147138e-12 | dimensionless | Propagated state history |
| Maximum radius deviation | 5.590846e-08 | km | Propagated state history |
| One-orbit position closure error | 1.702793e-07 | km | Final state minus initial state |
| Numerical convergence position error | 1.682975e-07 | km | Production vs. tighter run |

## Assumptions and conventions

The authoritative assumptions and derivation are recorded in
`docs/report/assumptions.md`. The model uses an ECI frame, kilometre-second units,
WGS 84 `mu` and equatorial radius values, and point-mass Earth gravity only.

## Remaining issues / next action

- Native MATLAB PNG export was retried successfully at 11:00 on 2026-10-14 after
  restarting with a single licensed MATLAB desktop. Both the 2D and 3D PNG files
  were written by MATLAB and visually inspected. The earlier licensing error
  `-15.3` is resolved for this run.
- Day 2 should introduce reusable scenario definitions and begin acquisition and
  parsing of current CelesTrak orbital elements.
- Perturbations, SGP4, real-satellite tracking, and relativistic timing have not yet
  been implemented and must not be described as completed.


