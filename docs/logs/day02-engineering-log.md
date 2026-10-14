# Day 2 Engineering Log

Date: 2026-10-14

## Objective

Build a respectful, reproducible CelesTrak ingestion pipeline for current orbital
elements and establish the first five-satellite tracking catalog.

## Day 2 roadmap

1. Define the orbital-data contract and five-satellite catalog.
2. Implement HTTP retrieval with timestamps, caching, and clear failure handling.
3. Parse and validate CCSDS OMM-compatible CSV fields.
4. Filter the GPS Operational group to the selected spacecraft.
5. Calculate element age and reject stale or incomplete records.
6. Save raw and processed snapshots without overwriting historical evidence.
7. Add automated tests and document measured results.

## Completed work

- [x] Selected OMM-compatible CSV as the authoritative ingestion format.
- [x] Configured the official CelesTrak GP endpoint.
- [x] Defined a five-satellite catalog containing the ISS and four GPS satellites.
- [ ] Retrieved a live CelesTrak snapshot.
- [ ] Parsed and validated the live records.
- [ ] Saved timestamped raw and processed data.

## Engineering rationale

CelesTrak documents that the legacy TLE representation cannot support catalog
numbers above 99999. Since the catalog exceeded five digits in 2026, CSV is used as
the primary source format. The pipeline still records SGP4 mean-element fields and
can add legacy TLE retrieval for compatible satellites during later SGP4 validation.

## Quantitative results

- Configured catalog size: 5 satellites (1 ISS and 4 GPS spacecraft).
- Task 1 verification: 6 of 6 automated checks passed in MATLAB.
- Live CelesTrak retrievals completed: 0.
- Satellite propagation/tracking runs completed on Day 2: 0.

These figures distinguish configuration tests from actual tracking performance; no
live data acquisition or satellite tracking run is claimed yet.

## Next action

Implement Task 2: a cached MATLAB `webread` client that retrieves exactly one ISS
query and one GPS Operational group query while respecting CelesTrak resources.

