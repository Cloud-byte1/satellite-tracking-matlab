# Near-Real-Time Satellite Tracking, Orbital Dynamics, and Relativistic Time Dilation in MATLAB

## Abstract

This project implements and verifies a MATLAB application for real-record satellite tracking, orbital-model comparison, and relativistic clock analysis. Six spacecraft spanning low, medium, and geosynchronous Earth orbit were ingested from CelesTrak general perturbations records. The Vallado/CelesTrak SGP4 implementation generated reference model histories, which were transformed from TEME into a documented J2000/FK5 realization and compared with a custom point-mass two-body model integrated by MATLAB `ode45`. Position differences were resolved into radial, along-track, and cross-track components over 1-, 6-, and 24-hour horizons. A weak-field clock model combined gravitational potential and special-relativistic velocity terms relative to an idealized stationary clock at the WGS-84 equatorial radius. The theoretical GPS case produced +45.660757 microseconds/day gravitational, -7.208677 microseconds/day kinematic, and +38.452079 microseconds/day net, within 0.1245% of the conventional +38.5 microseconds/day benchmark. Final verification completed 120/120 automated simulations and passed 17/17 consolidated checks. The largest observed two-body–SGP4 separation was 1,781.797863 km after 24 hours. That quantity is interpreted as model disagreement rather than validated tracking error because no independent truth ephemeris was used.

## 1. Executive summary and objectives

The engineering objective was to build a reproducible portfolio application that connects real orbital data to physics, numerical analysis, and an interactive display. The completed system retrieves or reuses cached CelesTrak records, validates their fields and provenance, propagates at least five named spacecraft with SGP4, performs an independent `ode45` propagation, decomposes the resulting position difference in RTN coordinates, computes relativistic timing effects, exports machine-readable results, and presents propagated states in a dashboard and MATLAB’s native `satelliteScenario` environment.

The final configuration tracks ISS (ZARYA), NAVSTAR 48, NAVSTAR 51, NOAA-20, Landsat 9, and GOES-16. These spacecraft provide LEO, MEO, and GEO regimes rather than a single favorable test orbit. The final analysis uses cached records from 18–19 October 2026 so that the acceptance run is reproducible. Those records must not be interpreted as current operational ephemerides after their documented element epochs.

The completed evidence package includes 8,646 SGP4/two-body time-series rows, 18 satellite/horizon summary cases, nine relativistic scenarios, 120 full-orbit numerical simulations, 17 final verification checks, six publication-oriented final figures, and CSV/MAT results. The dashboard is backed by the same propagated real-satellite arrays used for analysis.

## 2. Mathematical foundations

### 2.1 Two-body dynamics

The numerical model treats Earth and the spacecraft as a point-mass system:

\[
\ddot{\mathbf r}=-\mu\frac{\mathbf r}{\|\mathbf r\|^3},
\]

with position in kilometres, time in seconds, and the WGS-84 conventional gravitational parameter in km³/s². MATLAB `ode45` integrates the six-component Cartesian state. For a circular orbit of radius \(r\), independent benchmarks are

\[
v_c=\sqrt{\mu/r}, \qquad T=2\pi\sqrt{r^3/\mu}.
\]

For an ellipse with semimajor axis \(a\) and eccentricity \(e\), the expected apsides are \(r_p=a(1-e)\) and \(r_a=a(1+e)\). The specific mechanical energy and angular momentum,

\[
\epsilon=\frac{v^2}{2}-\frac{\mu}{r}, \qquad
\mathbf h=\mathbf r\times\mathbf v,
\]

are conserved by the ideal continuous two-body dynamics. Their numerical drift is therefore an effective implementation check, but it does not validate the model against the real orbit.

### 2.2 SGP4 and coordinate frames

SGP4 propagates mean orbital elements using the perturbation structure defined by its model and returns states in the True Equator, Mean Equinox frame. Direct subtraction from an arbitrary ECI state would mix frame effects with dynamics. The comparison pipeline therefore converts each SGP4 TEME history through the Vallado IAU-76/FK5 sequence using CelesTrak Earth-orientation data. The first converted SGP4 J2000/FK5 state initializes the two-body integration, so both histories begin at the same position and velocity.

The position difference is defined as two-body minus SGP4. At every sample, it is projected onto the SGP4 local orbital basis: radial \(\hat R\), along-track \(\hat T\), and cross-track \(\hat N\). RTN reconstruction closed within 9.444e-13 km and the maximum frame-rotation orthogonality error was 5.088e-16 in the final checks.

### 2.3 Relativistic clock model

The timing sign convention is satellite proper time minus reference-clock proper time. The reference is an idealized stationary clock at the WGS-84 equatorial radius in a spherical, nonrotating Earth model. The leading weak-field gravitational rate difference is

\[
\Delta\dot\tau_g=\frac{\mu}{c^2}\left(\frac{1}{R_E}-\frac{1}{r}\right),
\]

and the leading kinematic term is

\[
\Delta\dot\tau_k\approx-\frac{v^2}{2c^2}.
\]

The implementation also evaluates a cancellation-resistant exact special-relativistic rate. Rates are integrated with respect to elapsed coordinate time and reported in microseconds per day. For a theoretical circular GPS orbit at 20,200 km altitude, the model produced +45.660757 microseconds/day gravitational and -7.208677 microseconds/day kinematic, yielding +38.452079 microseconds/day net. The 0.047921 microseconds/day absolute difference from +38.5 corresponds to 0.1245%. The familiar benchmark is meaningful only with its reference-clock convention stated; it is not a universal clock offset independent of coordinate system and geoid definition.

## 3. Application architecture and data flow

Configuration functions centralize constants, orbit catalogs, time horizons, solver tolerances, and file locations. Source code is divided into dynamics, propagation, frame conversion, analysis, relativity, dashboard, input/output, and visualization modules. Top-level scripts reproduce each engineering stage and write results outside the source tree.

The retrieval layer forms validated HTTPS CelesTrak queries, parses typed OMM-compatible CSV or TLE data, records retrieval time separately from element epoch, and writes provenance-bearing cache files. A fresh cache avoids an unnecessary request. If a request fails, a valid stale cache can be used with its source labeled. Malformed responses are rejected. Six Day 5 offline retrieval tests passed, including network-failure fallback.

The Day 7 pipeline propagates six records for 24 hours at 60-second output spacing. SGP4 produces TEME histories; the frame layer converts them to J2000/FK5; `ode45` starts from the converted initial state; and analysis builds Cartesian, magnitude, and RTN differences. The dashboard reads these exact stored histories and the Day 9 timing summary. Satellite and horizon controls select actual propagated samples for display. A separate button launches MATLAB’s native five-satellite `satelliteScenario` viewer from cached TLEs when Satellite Communications Toolbox is installed.

## 4. Verification methodology

The final deterministic campaign covers five semimajor-axis regimes, four eccentricities, and six inclinations for 120 cases. Every case spans one analytical Kepler period with 181 output samples. A run passes when the state remains finite, relative energy and angular-momentum drift remain below 1e-7, and numerical perigee and apogee agree with analytical values within 0.25 km. All 120 runs passed in 44.109 seconds of summed propagation time. The maximum relative energy drift was 6.0711e-10 and maximum relative angular-momentum drift was 3.0380e-10. Maximum perigee and apogee errors were only a few micrometres expressed in kilometres.

The consolidated 17-check suite covers circular velocity, period closure, energy conservation, angular momentum conservation, elliptical apsides, solver convergence, initial-state consistency, Vallado SGP4 reference cases, frame rotation, RTN reconstruction, special relativity, gravitational relativity, combined GPS timing, catalog parsing, dashboard integrity, and campaign count. All 17 passed with no failures or skips.

A six-hour tolerance study compared four `ode45` solutions with a tighter reference. Final position differences decreased from 1.573448 m at relative tolerance 1e-6 to 0.0001157 m at 1e-12. This establishes numerical convergence of the implemented two-body integration. It does not establish the real-world accuracy of the two-body force model.

## 5. Engineering results

The global maximum two-body–SGP4 position separation over all saved samples was 1,781.797863 km, and the global RMS separation was 575.823254 km. The largest case was Landsat 9 at 24 hours, with 1,765.071 km maximum absolute along-track separation, 240.977 km radial, and a smaller cross-track contribution. The maximum separation across the six spacecraft was 95.91 km at one hour, 466.12 km at six hours, and 1,781.80 km at 24 hours. Mean case RMS separation also grew from 16.31 km at one hour to 100.78 km at six hours and 404.87 km at 24 hours.

The growth is physically expected because the two-body model omits atmospheric drag, Earth oblateness, higher geopotential terms, lunisolar perturbations, solar radiation pressure, and any maneuver representation included indirectly in updated mean elements. LEO along-track phase is especially sensitive to small mean-motion differences. The comparison demonstrates why force-model fidelity and element updating matter; it does not determine which instantaneous trajectory is closer to truth.

Relativistic timing varies strongly by regime. ISS produced approximately -24.48 microseconds/day net in this reference convention because its large kinematic loss dominates the small gravitational gain. The two real GPS spacecraft produced about +38.44 microseconds/day. GOES-16 produced about +46.45 microseconds/day because the gravitational advantage increases and the orbital speed decreases with altitude. Under the stated circular, spherical assumptions, net drift crosses zero at 3,189.069 km altitude.

The dashboard controller returned propagated position updates in a mean 0.884 ms over 100 selections. A cold hidden-UI startup, including MAT-file loading, graphics construction, and initial plotting, measured 20.166 seconds on the acceptance machine. The latter includes MATLAB graphics startup overhead and should not be generalized to other hardware or an already-warm MATLAB session.

## 6. Figures and engineering interpretation

1. `final_01_3d_trajectories.png` shows 24-hour SGP4 trajectories for all six records. The mixed LEO/MEO/GEO geometry verifies that the analysis is not restricted to one regime.
2. `final_02_sgp4_two_body_separation.png` shows horizon-dependent model divergence. The plot communicates accumulated force-model and SGP4 mean-element effects, not truth error.
3. `final_03_rtn_components.png` resolves the difference by orbital direction and exposes the dominant along-track behavior in LEO.
4. `final_04_solver_convergence.png` demonstrates numerical convergence against a tighter `ode45` solution.
5. `final_05_energy_conservation.png` shows representative invariant drift for the point-mass model.
6. `final_06_relativistic_clock_drift.png` separates gravitational, kinematic, and net contributions across circular-orbit altitude.

## 7. Limitations and uncertainty

The cached data are intentionally fixed for reproducibility and are not current tracking products. SGP4 output is not a precision truth ephemeris. The conversion path is documented but does not implement a complete IAU 2006/2000A reference-system reduction. The two-body comparison excludes important perturbations by design. No covariance propagation, measurement update, maneuver detection, or orbit determination is included.

The timing model is first-order and idealized. It excludes Earth rotation at the reference clock, geopotential harmonics, tides, third bodies, signal propagation, ionosphere and troposphere, satellite clock telemetry, and operational GPS system time. Reported microseconds-per-day results are theoretical rates under the stated convention, not corrections uploaded to a navigation satellite.

Automated hidden-UI startup and dashboard data integrity were verified. Interactive close behavior and behavior on a MATLAB installation lacking Satellite Communications Toolbox were not manually tested during the headless acceptance run. These items remain explicitly marked NOT TESTED rather than inferred.

## 8. Conclusions and future work

The project meets its central portfolio objectives: real orbital data, validated SGP4 execution, independent numerical propagation, frame-consistent comparison, RTN diagnostics, special and gravitational relativity, more than 100 automated runs, more than 10 final checks, exported results, and an interactive dashboard. The verification evidence supports implementation correctness within the tested scope. It does not overstate numerical convergence or model agreement as operational tracking accuracy.

The strongest future extensions are ingestion of current records on demand with explicit age alarms; comparison against independently sourced precision ephemerides; higher-fidelity force models including J2, drag, and third bodies; covariance and uncertainty propagation; ground-station visibility and link analysis; and packaging the programmatic dashboard as an App Designer application after manual cross-platform UI testing.

## References

1. Vallado, D. A., *Fundamentals of Astrodynamics and Applications*, Microcosm Press.
2. Vallado, D. A., Crawford, P., Hujsak, R., and Kelso, T. S., “Revisiting Spacetrack Report #3,” AIAA 2006-6753.
3. CelesTrak, General Perturbations data and SGP4 reference implementation.
4. MathWorks, MATLAB `ode45`, `satelliteScenario`, and Satellite Communications Toolbox documentation.
5. Ashby, N., “Relativity in the Global Positioning System,” *Living Reviews in Relativity*.
