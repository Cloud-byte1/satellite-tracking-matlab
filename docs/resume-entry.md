# Resume entry

- Developed a MATLAB satellite-tracking dashboard for 6 real ISS, GPS, Earth-observation, and GEO spacecraft using CelesTrak records, Vallado SGP4, J2000/FK5 frame conversion, and interactive 1/6/24-hour state prediction.
- Implemented an independent `ode45` two-body propagator and RTN comparison pipeline; quantified up to 1,781.798 km of 24-hour model separation while explicitly distinguishing model disagreement from validated ephemeris error.
- Built a 120-case automated orbital simulation campaign and 17-check acceptance suite with 120/120 runs and 17/17 checks passing; measured maximum relative energy and angular-momentum drift of 6.07e-10 and 3.04e-10.
- Modeled weak-field gravitational and special-relativistic clock effects, reproducing a +38.452 microseconds/day GPS net correction within 0.125% of the +38.5 microseconds/day theoretical benchmark.
