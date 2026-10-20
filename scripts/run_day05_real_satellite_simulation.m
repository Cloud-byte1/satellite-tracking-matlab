function outputs = run_day05_real_satellite_simulation(options)
%RUN_DAY05_REAL_SATELLITE_SIMULATION Propagate and view five real satellites.

arguments
    options.DurationHours (1,1) double {mustBePositive,mustBeFinite} = 12
    options.StepSeconds (1,1) double {mustBePositive,mustBeFinite} = 120
    options.ShowViewer (1,1) logical = true
    options.ExportFigure (1,1) logical = true
end

scriptDirectory = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDirectory);
addpath(projectRoot); setupProject(); addpath(fullfile(projectRoot,'tests'));
constants = earthConstants();
sourceFile = fullfile(projectRoot,'data','processed', ...
    'day05_satellite_catalog_latest.mat');
if ~isfile(sourceFile)
    error('run_day05_real_satellite_simulation:MissingCatalog', ...
        'Run run_day05_task3_catalog before this simulation.');
end
source = load(sourceFile,'catalog','retrievals');
valladoDirectory = fullfile(projectRoot,'third_party','vallado_sgp4');
referenceVerification = runSgp4ReferenceTest(valladoDirectory);

simulationTimer = tic;
simulation = propagateSgp4Catalog(source.catalog,source.retrievals, ...
    DurationHours=options.DurationHours,StepSeconds=options.StepSeconds);
runtimeSec = toc(simulationTimer);
simulationVerification = runRealSatelliteSimulationTests( ...
    simulation,constants.radiusEarth);
observationVerification = runSatelliteObservationTests( ...
    simulation,constants.radiusEarth);

resultsDirectory = fullfile(projectRoot,'results');
figuresDirectory = fullfile(projectRoot,'figures');
summary = buildSummary(simulation,constants.radiusEarth);
writetable(summary,fullfile(resultsDirectory, ...
    'day05_real_satellite_simulation_summary.csv'));
writetable(referenceVerification.results,fullfile(resultsDirectory, ...
    'day05_sgp4_reference_verification.csv'));
writetable(simulationVerification.results,fullfile(resultsDirectory, ...
    'day05_real_satellite_simulation_verification.csv'));
writetable(observationVerification.results,fullfile(resultsDirectory, ...
    'satellite_observation_verification.csv'));
save(fullfile(resultsDirectory,'day05_real_satellite_simulation.mat'), ...
    'simulation','summary','runtimeSec','referenceVerification', ...
    'simulationVerification','observationVerification');

figureHandle = gobjects(0);
if options.ShowViewer || options.ExportFigure
    figureHandle = createRealSatelliteViewer(simulation,constants.radiusEarth);
    if options.ExportFigure
        exportgraphics(figureHandle,fullfile(figuresDirectory, ...
            'day05_real_satellites_sgp4_teme.png'),'Resolution',220);
        savefig(figureHandle,fullfile(figuresDirectory, ...
            'day05_real_satellites_sgp4_teme.fig'));
    end
    if ~options.ShowViewer
        close(figureHandle);
        figureHandle = gobjects(0);
    end
end

fprintf('\nREAL-SATELLITE SGP4 SIMULATION\n');
fprintf('Satellites:             %d\n',numel(simulation.catalogIds));
fprintf('Common UTC duration:    %.2f h\n',simulation.durationHours);
fprintf('Samples per satellite:  %d\n',numel(simulation.timeUtc));
fprintf('SGP4 calls completed:   %d\n',numel(simulation.sgp4ErrorCode));
fprintf('Propagation runtime:    %.3f s\n',runtimeSec);
fprintf('Reference checks:       %d/%d passed\n', ...
    referenceVerification.passedTests,referenceVerification.totalTests);
fprintf('Simulation checks:      %d/%d passed\n', ...
    simulationVerification.passedTests,simulationVerification.totalTests);
fprintf('Observation checks:     %d/%d passed\n\n', ...
    observationVerification.passedTests,observationVerification.totalTests);
disp(summary);

outputs = struct('simulation',simulation,'summary',summary, ...
    'runtimeSec',runtimeSec,'referenceVerification',referenceVerification, ...
    'simulationVerification',simulationVerification, ...
    'observationVerification',observationVerification,'figure',figureHandle);
end

function summary = buildSummary(simulation,earthRadiusKm)
count = numel(simulation.catalogIds);
SatelliteName = simulation.satelliteNames;
NORADCatalogID = simulation.catalogIds;
MinimumAltitudeKm = zeros(count,1);
MaximumAltitudeKm = zeros(count,1);
MinimumSpeedKmPerSec = zeros(count,1);
MaximumSpeedKmPerSec = zeros(count,1);
for index = 1:count
    position = simulation.positionTemeKm(:,:,index);
    velocity = simulation.velocityTemeKmPerSec(:,:,index);
    altitude = vecnorm(position,2,2)-earthRadiusKm;
    speed = vecnorm(velocity,2,2);
    MinimumAltitudeKm(index) = min(altitude);
    MaximumAltitudeKm(index) = max(altitude);
    MinimumSpeedKmPerSec(index) = min(speed);
    MaximumSpeedKmPerSec(index) = max(speed);
end
summary = table(SatelliteName,NORADCatalogID,MinimumAltitudeKm, ...
    MaximumAltitudeKm,MinimumSpeedKmPerSec,MaximumSpeedKmPerSec);
end
