# Vallado TEME-to-J2000/FK5 frame routines

This folder contains the minimal unmodified MATLAB subset required from the
official CelesTrak `fundamentals-of-astrodynamics` repository:

- `teme2eci.m`
- `precess.m`
- `nutation.m`
- `fundarg.m`
- `iau80in.m`
- `sethelp.m`
- `nut80.dat`

Source: <https://github.com/CelesTrak/fundamentals-of-astrodynamics>

Downloaded: 2026-10-19. Upstream commit is recorded in the Day 7 engineering
log. The upstream `LICENSE` file is included unchanged. These routines implement
the IAU-76/FK5 and IAU-1980 transformation used to put SGP4 TEME states and the
two-body solution in a common J2000/FK5 inertial realization.
