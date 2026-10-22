# 2–3 minute project demonstration plan

## 0:00–0:20 — Mission and architecture

“This MATLAB application ingests real CelesTrak orbital records, propagates six spacecraft with SGP4, initializes an independent `ode45` two-body model from the same state, and quantifies their divergence in a consistent J2000/FK5 frame.” Show the repository layout and point to the cache provenance fields.

## 0:20–0:55 — Real satellite tracking

Run `SatelliteTrackingDashboard`. Select ISS, NAVSTAR 48, and GOES-16. Change the horizon between 1, 6, and 24 hours. Point out the propagated UTC state, J2000 position/velocity, and that the plotted tracks come directly from the saved real-record SGP4 histories. Use **Open 3-D globe** to show the native `satelliteScenario` viewer if the toolbox is available.

## 0:55–1:30 — Propagator comparison

Show `final_02_sgp4_two_body_separation.png` and `final_03_rtn_components.png`. Explain that the largest 24-hour separation was 1,781.798 km and was dominated by LEO along-track divergence. State explicitly: “This is disagreement between models of different fidelity, not independently validated tracking error.”

## 1:30–2:00 — Verification

Open `final_verification_summary.csv` and `final_simulation_campaign.csv`. Highlight 120/120 full-orbit simulations, 17/17 consolidated checks, maximum relative energy drift of 6.0711e-10, maximum relative angular-momentum drift of 3.0380e-10, and the 0.0001157 m tight-tolerance convergence difference.

## 2:00–2:30 — Relativistic timing

Show `final_06_relativistic_clock_drift.png`. Explain the reference convention: satellite proper time minus an idealized stationary clock at the WGS-84 equatorial radius. The theoretical GPS orbit produced +45.660757 microseconds/day gravitational, -7.208677 microseconds/day kinematic, and +38.452079 microseconds/day net.

## 2:30–2:50 — Close

“The project demonstrates data ingestion, coordinate-frame discipline, SGP4 and numerical propagation, RTN analysis, relativistic timing, automated verification, and an interactive engineering dashboard. The exported evidence is reproducible; the documented limitations separate numerical correctness from real-world accuracy.”
