# Vallado SGP4 Reference Implementation

This directory contains the unmodified MATLAB portion of the reference package
distributed with:

David A. Vallado, Paul Crawford, Richard Hujsak, and T. S. Kelso,
“Revisiting Spacetrack Report #3,” AIAA 2006-6753.

Source: <https://celestrak.org/publications/AIAA/2006-6753/>

Downloaded: 2026-10-18 (America/New_York) / 2026-10-19 UTC.

CelesTrak's accompanying FAQ states that the code has no license restriction and
requests attribution and a link to the source page. The project-specific adapter,
tests, and visualization live outside this directory.

The SGP4 output is Cartesian position and velocity in the True Equator, Mean
Equinox (TEME) frame. It is not ECEF and must not be labeled as geodetic position.
