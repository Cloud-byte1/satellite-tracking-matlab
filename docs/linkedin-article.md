# I Built a Satellite Tracker in MATLAB. Its Most Useful Output Was a 1,781 km Disagreement.

*Real CelesTrak data, SGP4, an independent `ode45` propagator, relativistic clock models, 120 automated simulations, and a desktop app. Here's what I built and what it actually proves.*

---

GPS satellite clocks run faster than clocks on the ground by roughly 38 microseconds a day. If nobody corrected for that, GPS positions would drift by about 10 km a day. Most engineers have heard this. I wanted to calculate it myself, starting from real orbital data and checking every step.

That turned into a 14-day MATLAB project. It takes real satellite records, propagates them with two very different models, compares the results in a consistent reference frame, applies special and general relativity, and shows everything in one desktop application.

## What the system does

**1. Ingests real orbital data.**
The pipeline sends validated HTTPS queries to CelesTrak and parses OMM-compatible CSV and TLE records. It stores the *retrieval time* separately from the *element epoch*, because they are different things and mixing them up is a quiet source of error. Responses are cached with provenance. If the network fails, a valid stale cache is used and labeled as stale. Malformed data is rejected.

**2. Tracks six real spacecraft in three orbital regimes:**
- ISS (ZARYA), in LEO
- NOAA-20 and Landsat 9, Earth-observation satellites in LEO
- NAVSTAR 48 and NAVSTAR 51, GPS satellites in MEO
- GOES-16, in GEO

I picked a mix of regimes on purpose. A model that only works on one convenient orbit hasn't really been tested.

**3. Propagates each satellite with two independent models.**
- **SGP4** (the Vallado/CelesTrak reference implementation): the standard model for general-perturbations elements. It outputs states in the TEME frame.
- **A custom two-body propagator** that integrates r̈ = −μr/|r|³ with MATLAB's `ode45`.

**4. Puts both models in the same reference frame.**
You can't subtract a TEME state from an arbitrary ECI state and call the result "error," because frame differences get mixed in with dynamics. Every SGP4 history is converted to J2000/FK5 through the IAU-76/FK5 sequence using CelesTrak Earth-orientation data. The first converted SGP4 state then seeds the two-body integration, so both trajectories start from the same position and velocity.

**5. Breaks the difference into RTN components.**
Radial, along-track, and cross-track. RTN reconstruction closes to 9.4×10⁻¹³ km, and the worst frame-rotation orthogonality error is 5.1×10⁻¹⁶.

**6. Models relativistic clock drift.**
The model combines the weak-field gravitational term, μ/c²·(1/R_E − 1/r), with the special-relativistic velocity term, −v²/2c². The velocity term uses a form that resists cancellation error. The reference is an idealized stationary clock at the WGS-84 equatorial radius.

**7. Shows it all in one application.**
**Satellite Observer** includes:
- a **LIVE NOW** mode that gives SGP4-estimated latitude, longitude, altitude, speed, and data age, updated every five seconds
- MATLAB's native `satelliteScenario` 3-D globe embedded in the app, with all six satellites and their ground tracks moving from current UTC
- 1-, 6-, and 24-hour predictions, RTN plots, timing results, exports, and the verification report

On Windows it opens with a one-click launcher.

## The results

| Metric | Result |
|---|---:|
| Real satellites analyzed | 6 |
| Satellite/horizon comparison cases | 18 |
| Automated simulations passed | **120 / 120** |
| Final verification checks passed | **17 / 17** |
| Max relative energy drift | 6.07 × 10⁻¹⁰ |
| Max relative angular-momentum drift | 3.04 × 10⁻¹⁰ |
| Tightest 6-hour solver convergence difference | 0.0001157 m |
| GPS net relativistic correction | **+38.452 µs/day** |
| Difference from the +38.5 µs/day benchmark | **0.1245%** |
| Dashboard update latency (mean of 100) | 0.884 ms |
| Max 24-hour two-body vs. SGP4 separation | **1,781.8 km** |

### The relativity result

For a theoretical circular GPS orbit at 20,200 km altitude:
- Gravitational effect: **+45.661 µs/day.** Weaker gravity makes the clock run faster.
- Kinematic effect: **−7.209 µs/day.** Orbital speed makes the clock run slower.
- **Net: +38.452 µs/day**, within 0.125% of the textbook +38.5 figure.

The other regimes were more interesting:
- **ISS: about −24.5 µs/day.** In low orbit the speed term wins, so the ISS clock runs *slow* compared with the ground reference.
- **GOES-16: about +46.5 µs/day.** In GEO the gravity term dominates.
- **Crossover: 3,189 km altitude.** Under these assumptions, that is where the two effects cancel exactly.

The 38.5 µs/day number only means something once you state the reference-clock convention. It is not a universal constant, and the project documents that convention explicitly.

### The 1,781 km result, and why I won't call it "error"

After 24 hours, the two-body model and SGP4 were up to **1,781.8 km apart** (Landsat 9). Mean RMS separation grew from 16 km at 1 hour to 101 km at 6 hours to 405 km at 24 hours. Most of the gap is along-track, about 1,765 km for Landsat 9.

That growth is expected. A point-mass model ignores Earth's oblateness (J2), atmospheric drag, third-body gravity, and solar radiation pressure. For LEO satellites, a tiny error in mean motion turns into a large along-track phase drift.

The temptation is to label this number "tracking error." **It isn't.** I had no independent precision ephemeris as ground truth, so the honest label is *model disagreement*. The number shows why force-model fidelity matters. It doesn't tell you which trajectory is closer to reality. I'd rather report one carefully labeled number than three impressive ones I can't defend.

## How I verified it

- **120-case simulation campaign:** 5 semimajor axes × 4 eccentricities × 6 inclinations, one full Kepler period each. Every run had to keep energy and angular-momentum drift below 10⁻⁷ and match analytical perigee and apogee within 0.25 km. All 120 passed.
- **17-check acceptance suite:** circular velocity, period closure, energy and angular-momentum conservation, elliptical apsides, solver convergence, initial-state consistency, Vallado SGP4 reference cases, frame rotation, RTN reconstruction, special relativity, gravitational relativity, combined GPS timing, catalog parsing, dashboard integrity, and campaign count. All 17 passed with zero failures or skips.
- **Tolerance study:** the 6-hour position difference against a tighter reference shrank from 1.57 m at RelTol 1e-6 to 0.12 mm at 1e-12.
- **Results that would have been easy to hide:** the cold UI startup took 20 seconds, and two interactive behaviors weren't covered by the headless acceptance run. Both are marked **NOT TESTED** in the report instead of being assumed to work.

## Lessons I'm taking forward

1. **Frames come first.** A comparison is only as good as the frame conversion behind it. Most "model error" in amateur work is actually frame error.
2. **Epoch is not retrieval time.** Orbital data starts aging at its epoch, not when you download it.
3. **Convergence is not accuracy.** My integrator converges to sub-millimeter precision on a model that is off by about 1,800 km. Both statements are true.
4. **A benchmark needs its convention.** "+38.5 µs/day" isn't meaningful until you say what clock it's measured against.
5. **Write down what you didn't test.** Stating your limitations makes the claims you do make easier to trust.

## What's next

- Comparing against independent precision ephemerides, which turns "disagreement" into actual error
- Higher-fidelity forces: J2, drag, and third bodies
- Covariance and uncertainty propagation
- Ground-station visibility and link-budget analysis
- Cross-platform UI testing and App Designer packaging

## Tech stack

MATLAB R2026b · Satellite Communications Toolbox (`satelliteScenario`) · Vallado/CelesTrak SGP4 · `ode45` · IAU-76/FK5 frame reduction · CelesTrak GP/OMM and EOP data · CSV/MAT/PNG/FIG exports · 7-page technical report

The code, figures, daily engineering logs, and full technical report are on GitHub: **github.com/cloud-byte1/satellite-tracking-matlab**

If you work in astrodynamics, GNSS, or space situational awareness, I'd welcome a critique, especially on the frame-reduction choices and the clock reference convention.

---

*References: Vallado, Fundamentals of Astrodynamics and Applications; Vallado, Crawford, Hujsak & Kelso, "Revisiting Spacetrack Report #3" (AIAA 2006-6753); Ashby, "Relativity in the Global Positioning System," Living Reviews in Relativity; CelesTrak; MathWorks documentation.*

#Aerospace #AerospaceEngineering #Astrodynamics #MATLAB #OrbitalMechanics #SatelliteTracking #GPS #Relativity #SpaceTech #SpaceSituationalAwareness #Engineering #Simulation
