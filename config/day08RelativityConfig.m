function config = day08RelativityConfig(projectRoot)
%DAY08RELATIVITYCONFIG Reproducible settings for the Day 8 clock analysis.

arguments
    projectRoot (1,1) string
end

constants = earthConstants();
config = struct();
config.speedOfLightKmPerSec = 299792.458;
config.muEarthKm3PerSec2 = constants.muEarth;
config.earthRadiusKm = constants.radiusEarth;
config.secondsPerDay = constants.secondsPerDay;
config.durationSeconds = constants.secondsPerDay;
config.stepSeconds = 60;
config.circularLeoAltitudeKm = 500;
config.gpsAltitudeKm = 20200;
config.ellipticalPerigeeAltitudeKm = 500;
config.ellipticalApogeeAltitudeKm = 20200;
config.ellipticalInclinationDeg = 28.5;
config.coordinateTimeConvention = ...
    "Elapsed coordinate seconds in a J2000/FK5 geocentric inertial approximation";
config.referenceFrame = ...
    "J2000/FK5 ECI via Vallado IAU-76/FK5 TEME conversion";
config.day07ResultsFile = fullfile(projectRoot,"results", ...
    "day07_sgp4_two_body_comparison.mat");
config.relativeTolerance = 1e-11;
config.absoluteTolerance = 1e-12;
config.maximumStepSeconds = 60;
config.ellipticalVerificationSamples = 4001;
end
