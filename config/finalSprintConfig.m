function config = finalSprintConfig(projectRoot)
%FINALSPRINTCONFIG Reproducible settings for the Days 11-14 campaign.

arguments
    projectRoot (1,1) string
end

constants = earthConstants();
config = struct();
config.projectRoot = projectRoot;
config.muEarthKm3PerSec2 = constants.muEarth;
config.earthRadiusKm = constants.radiusEarth;
config.simulationAltitudesKm = [500 2000 10000 20200 35786];
config.simulationEccentricities = [0 0.005 0.010 0.015];
config.simulationInclinationsDeg = [0 28.5 51.6 63.4 90 98];
config.simulationSamplesPerOrbit = 181;
config.relativeTolerance = 1e-9;
config.absoluteTolerance = 1e-11;
config.maximumStepSeconds = 120;
config.maximumRelativeEnergyDrift = 1e-7;
config.maximumRelativeAngularMomentumDrift = 1e-7;
config.maximumApsisErrorKm = 0.25;
config.convergenceRelativeTolerances = [1e-6 1e-8 1e-10 1e-12];
config.convergenceReferenceTolerance = 1e-13;
config.convergenceDurationHours = 6;
config.convergenceMaximumStepSeconds = 60;
config.dashboardLatencySamples = 100;
config.day07ResultsFile = fullfile(projectRoot,"results", ...
    "day07_sgp4_two_body_comparison.mat");
config.day09ResultsFile = fullfile(projectRoot,"results", ...
    "day09_general_relativity.mat");
end
