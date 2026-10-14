# Near-Real-Time Satellite Tracking, Orbital Dynamics & Relativistic Time Dilation

MATLAB aerospace engineering portfolio project developed over 14 days.

## Current status

- Day 1 implementation is complete and executable with base MATLAB.
- Native 2D and 3D PNG exports were successfully verified in MATLAB R2026b on
  2026-10-14 in this clean-retry copy.
- Run `run_day01_circular_orbit` from the `scripts` directory after calling
  `setupProject`, or follow the quick-start command below.

## Requirements

- MATLAB (base MATLAB wherever practical)
- Optional toolboxes will be identified explicitly if introduced later

## Repository layout

| Path | Purpose |
|---|---|
| `src/dynamics` | Equations of motion and force models |
| `src/propagation` | Numerical propagators and propagation interfaces |
| `src/analysis` | Orbital quantities, error metrics, and comparisons |
| `src/visualization` | Reusable plotting functions |
| `src/io` | CelesTrak, TLE, configuration, and file I/O |
| `src/relativity` | Special- and general-relativistic timing models |
| `src/dashboard` | Near-real-time tracking dashboard code |
| `scripts` | Reproducible top-level workflows |
| `tests` | MATLAB verification and regression tests |
| `data/raw` | Unmodified external orbital data |
| `data/processed` | Parsed or transformed data |
| `config` | Constants and scenario configuration |
| `results` | Machine-readable numerical outputs |
| `figures` | Exported plots and graphics |
| `docs/logs` | Daily engineering logs |
| `docs/report` | Technical report source and supporting material |
| `docs/video` | Demonstration-video outline and assets |

## Reproducibility rule

Top-level scripts call reusable functions in `src`; source functions do not depend on interactive workspace variables. Generated results and figures are saved outside `src`.

## Day 1 quick start

From the repository root in MATLAB:

```matlab
setupProject;
addpath("scripts");
outputs = run_day01_circular_orbit();
```

The workflow writes two renderer-independent SVG plots to `figures`, CSV summaries
to `results`, and a MAT-file containing the complete simulation state. No optional
toolbox is required. To additionally request PNG exports through MATLAB's graphics
backend, run `run_day01_circular_orbit(GeneratePngFigures=true)`.

The physics derivation and teaching notes are in
`docs/report/day01-foundation-guide.md`; measured accomplishments are recorded in
`docs/logs/day01-engineering-log.md`.

