function config = day07ComparisonConfig(projectRoot)
%DAY07COMPARISONCONFIG Reproducible settings for the Day 7 analysis.

arguments
    projectRoot (1,1) string
end

config = struct();
config.horizonsHours = [1 6 24];
config.durationHours = 24;
config.stepSeconds = 60;
config.relativeTolerance = 1e-11;
config.absoluteTolerance = 1e-12;
config.maximumStepSeconds = 60;
config.sgp4GravityModel = "WGS-72";
config.twoBodyMuKm3PerSec2 = 398600.8;
config.earthRadiusKm = 6378.135;
config.referenceFrame = "J2000/FK5 ECI via Vallado IAU-76/FK5 TEME conversion";
config.eopFile = fullfile(projectRoot,"data","raw","EOP-Last5Years.csv");
config.frameLibraryDirectory = fullfile(projectRoot,"third_party","vallado_frames");
end
