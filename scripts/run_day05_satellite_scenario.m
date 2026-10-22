function outputs = run_day05_satellite_scenario(options)
%RUN_DAY05_SATELLITE_SCENARIO Native real-satellite 3-D simulation.
%   Downloads or reuses validated CelesTrak TLEs, constructs a MATLAB
%   satelliteScenario using native SGP4, and optionally opens the interactive
%   globe. Drag to rotate, scroll to zoom, and use the viewer timeline controls.

arguments
    options.StartTimeUtc (1,1) datetime = datetime('now','TimeZone','UTC')
    options.DurationHours (1,1) double {mustBePositive,mustBeFinite} = 12
    options.StepSeconds (1,1) double {mustBePositive,mustBeFinite} = 60
    options.ForceRefresh (1,1) logical = false
    options.ShowViewer (1,1) logical = true
    options.ShowGroundTracks (1,1) logical = true
    options.ShowObservationPanel (1,1) logical = true
    options.AutoPlay (1,1) logical = false
    options.PlaybackSpeedMultiplier (1,1) double {mustBePositive,mustBeFinite} = 300
end

scriptDirectory = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDirectory);
addpath(projectRoot); setupProject(); addpath(fullfile(projectRoot,'tests'));

% Satellite Observer uses the complete six-spacecraft engineering catalog so
% the moving globe and the analysis views always show the same fleet.
targets = day07SatelliteCatalog();
tleResult = fetchCelesTrakTleCatalog(targets, ...
    CacheDirectory=fullfile(projectRoot,'data','raw'), ...
    OutputFile=fullfile(projectRoot,'data','processed', ...
        'day05_satellite_scenario_latest.tle'), ...
    ForceRefresh=options.ForceRefresh);
[scenario,satellites] = createNativeSatelliteScenario(tleResult.File, ...
    StartTimeUtc=options.StartTimeUtc, ...
    DurationHours=options.DurationHours,StepSeconds=options.StepSeconds);
verification = runSatelliteScenarioTests(scenario,satellites, ...
    tleResult.Catalog,height(targets));

[initialPositionMeters,initialVelocityMetersPerSecond] = ...
    states(satellites,scenario.StartTime);
runConfiguration = struct('StartTimeUtc',scenario.StartTime, ...
    'StopTimeUtc',scenario.StopTime,'SampleTimeSeconds',scenario.SampleTime, ...
    'DurationHours',options.DurationHours,'TleFile',tleResult.File);
resultsDirectory = fullfile(projectRoot,'results');
writetable(tleResult.Catalog,fullfile(resultsDirectory, ...
    'day05_satellite_scenario_catalog.csv'));
writetable(verification.results,fullfile(resultsDirectory, ...
    'day05_satellite_scenario_verification.csv'));
save(fullfile(resultsDirectory,'day05_satellite_scenario_initial_state.mat'), ...
    'runConfiguration','initialPositionMeters', ...
    'initialVelocityMetersPerSecond','verification');

viewer = [];
observationPanel = [];
if options.ShowViewer
    viewer = satelliteScenarioViewer(scenario);
    if options.ShowGroundTracks
        for index = 1:numel(satellites)
            show(satellites(index).GroundTrack,viewer);
        end
    end
    if options.ShowObservationPanel
        constants = earthConstants();
        observationPanel = createSatelliteObservationPanel( ...
            scenario,satellites,EarthRadiusKm=constants.radiusEarth);
    end
    if options.AutoPlay
        play(scenario,Viewer=viewer, ...
            PlaybackSpeedMultiplier=options.PlaybackSpeedMultiplier);
    end
end

fprintf('\nNATIVE SATELLITESCENARIO SIMULATION\n');
fprintf('Satellites:              %d\n',numel(satellites));
fprintf('Propagators:             SGP4/SDP4 (MATLAB native)\n');
fprintf('Start UTC:               %s\n', ...
    string(scenario.StartTime,"yyyy-MM-dd HH:mm:ss 'UTC'"));
fprintf('Duration:                %.2f h\n',options.DurationHours);
fprintf('Sample time:             %.1f s\n',scenario.SampleTime);
fprintf('TLE sources:             %d network, %d cache\n', ...
    sum(tleResult.Catalog.Source == "network"), ...
    sum(contains(tleResult.Catalog.Source,"cache")));
fprintf('Verification checks:     %d/%d passed\n\n', ...
    verification.passedTests,verification.totalTests);
disp(tleResult.Catalog(:,{'SatelliteName','NORADCatalogID', ...
    'RetrievalTimeUtc','Source'}));

outputs = struct('scenario',scenario,'satellites',satellites, ...
    'viewer',viewer,'tle',tleResult,'verification',verification, ...
    'configuration',runConfiguration,'observationPanel',observationPanel);
end
