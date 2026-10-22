function config = day09RelativityConfig(projectRoot)
%DAY09RELATIVITYCONFIG Reproducible settings for gravitational timing.

arguments
    projectRoot (1,1) string
end

constants = earthConstants();
config = struct();
config.muEarthKm3PerSec2 = constants.muEarth;
config.earthRadiusKm = constants.radiusEarth;
config.speedOfLightKmPerSec = 299792.458;
config.secondsPerDay = constants.secondsPerDay;
config.durationSeconds = constants.secondsPerDay;
config.gpsAltitudeKm = 20200;
config.circularLeoAltitudeKm = 500;
config.ellipticalPerigeeAltitudeKm = 500;
config.ellipticalApogeeAltitudeKm = 20200;
config.ellipticalInclinationDeg = 28.5;
config.altitudePlotRangeKm = [0 50000];
config.altitudePlotSamples = 1201;
config.ellipticalVerificationSamples = 4001;
config.referenceClockConvention = ...
    "Idealized stationary clock at the WGS 84 equatorial reference radius";
config.coordinateTimeConvention = ...
    "Weak-field geocentric coordinate time in a spherical nonrotating Earth model";
config.referenceFrame = ...
    "J2000/FK5 ECI via Vallado IAU-76/FK5 TEME conversion";
config.day08ResultsFile = fullfile(projectRoot,"results", ...
    "day08_special_relativity.mat");
config.relativeTolerance = 1e-11;
config.absoluteTolerance = 1e-12;
config.maximumStepSeconds = 60;
end
