# Day 4 Engineering Log

Date: 2026-10-18

## Objective

Convert the orbital simulator into a verified, reproducible computational tool by
measuring conservation, convergence, repeatability, performance, and systematic
simulation behavior.

## Progress

- [x] Inspected the Day 1–3 model, tests, results, and plots.
- [x] Task 1: implemented complete specific-energy histories and summary metrics.
- [x] Task 1: generated an engineering energy-conservation plot.
- [x] Task 1: added explicit analytical and bounded-drift checks.
- [ ] Task 2: angular-momentum vector and magnitude conservation.
- [ ] Task 3: systematic solver convergence study.
- [ ] Task 4: consolidated verification suite.
- [ ] Task 5: 100+ run simulation campaign.
- [ ] Task 6: performance and sensitivity analysis.

## Task 1 measured results

These results were measured by executing `run_day04_task1_energy.m` in MATLAB
R2026b on 2026-10-18. The authoritative full-precision evidence is
`results/day04_task1_energy_conservation.csv`; verification evidence is
`results/day04_task1_energy_verification.csv`.

| Scenario | Initial energy (km^2/s^2) | Final signed deviation (km^2/s^2) | Maximum absolute deviation (km^2/s^2) | Maximum relative drift |
|---|---:|---:|---:|---:|
| LEO 500 km | -28.975902 | 5.0697e-12 | 5.0697e-12 | 1.7496e-13 |
| GPS-like MEO | -7.503773 | 1.2941e-12 | 1.2941e-12 | 1.7246e-13 |
| Geostationary | -4.726786 | 8.2423e-13 | 8.2423e-13 | 1.7437e-13 |
| Elliptical e=0.30 | -20.283131 | 2.9303e-11 | 4.3627e-11 | 2.1509e-12 |
| High-e Molniya-like | -7.492490 | 4.7429e-11 | 2.4382e-10 | 3.2542e-11 |
| Inclined 98 deg | -27.012269 | 4.7109e-12 | 4.7109e-12 | 1.7440e-13 |

Task 1 checks passed: **3 of 3**. The maximum error between the calculated initial
energy and the independent `-mu/(2a)` expression was below `1e-11 km^2/s^2`; all
history values were finite; and every orbit remained below the `1e-9` relative
drift limit.

## Interpretation

Specific orbital energy should be constant for every trajectory because the Day 4
force model is conservative. Small bounded variations measure numerical behavior;
they do not quantify the physical-model error relative to a real spacecraft.

## Outstanding issues

- Add dimension-specific absolute solver tolerances before the convergence study.
- Complete angular-momentum vector analysis, not only magnitude drift.
- Deduplicate earlier tests when assembling the final 10+ test suite.
- Execute and time the 100+ run campaign before claiming portfolio metrics.
- Live data, SGP4, perturbations, relativity, and validation remain later work.
