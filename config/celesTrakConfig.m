function config = celesTrakConfig()
%CELESTRAKCONFIG Define the authoritative Day 2 orbital-data source.
%   CSV uses the CCSDS OMM field names published by CelesTrak and avoids the
%   five-digit catalog-number limitation of the legacy TLE representation.

config = struct();
config.baseUrl = "https://celestrak.org/NORAD/elements/gp.php";
config.primaryFormat = "CSV";
config.referenceFrame = "TEME";
config.timeSystem = "UTC";
config.meanElementTheory = "SGP4";
config.gpsGroup = "gps-ops";
config.issCatalogNumber = 25544;
config.minimumExpectedGpsRecords = 20;
config.maxAcceptedElementAgeDays = 7;
end

