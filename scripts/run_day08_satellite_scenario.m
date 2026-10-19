function outputs = run_day08_satellite_scenario(options)
%RUN_DAY08_SATELLITE_SCENARIO Animate the complete Day 8 analysis.
%   Opens MATLAB's native 3-D globe with the exact six real-satellite and
%   three theoretical ephemerides used by the special-relativistic clock
%   analysis. Playback starts automatically by default.

arguments
    options.ShowViewer (1,1) logical = true
    options.ShowGroundTracks (1,1) logical = true
    options.ShowVisibilityControls (1,1) logical = true
    options.AutoPlay (1,1) logical = true
    options.PlaybackSpeedMultiplier (1,1) double {mustBePositive,mustBeFinite} = 900
end

scriptDirectory = fileparts(mfilename('fullpath'));
projectRoot = string(fileparts(scriptDirectory));
addpath(projectRoot); setupProject(); addpath(fullfile(projectRoot,'tests'));
day08File = fullfile(projectRoot,'results','day08_special_relativity.mat');
day07File = fullfile(projectRoot,'results','day07_sgp4_two_body_comparison.mat');
if ~isfile(day08File) || ~isfile(day07File)
    error('runDay08SatelliteScenario:MissingResults', ...
        'Run Day 7 and Day 8 before opening the Day 8 native viewer.');
end

day08 = load(day08File,'analysis','config');
day07 = load(day07File,'comparison');
[scenario,satellites] = createDay08SatelliteScenario( ...
    day08.analysis,day07.comparison.startTimeUtc, ...
    StepSeconds=day08.config.stepSeconds);
verification = runDay08SatelliteScenarioTests( ...
    scenario,satellites,day08.analysis);

summary = day08.analysis.summary(:,{'ScenarioName','Source','Regime', ...
    'MeanAltitudeKm','MeanSpeedKmPerSec', ...
    'IntegratedDrift24HoursMicroseconds'});
resultsDirectory = fullfile(projectRoot,'results');
writetable(summary,fullfile(resultsDirectory, ...
    'day08_satellite_scenario_catalog.csv'));
writetable(verification.results,fullfile(resultsDirectory, ...
    'day08_satellite_scenario_verification.csv'));

viewer = [];
controls = [];
if options.ShowViewer
    viewer = satelliteScenarioViewer(scenario);
    if options.ShowGroundTracks
        for index = 1:numel(satellites)
            show(satellites(index).GroundTrack,viewer);
        end
    end
    if options.ShowVisibilityControls
        controls = createDay08VisibilityControls(viewer,satellites, ...
            day08.analysis,ShowGroundTracks=options.ShowGroundTracks);
    end
    if options.AutoPlay
        play(scenario,Viewer=viewer, ...
            PlaybackSpeedMultiplier=options.PlaybackSpeedMultiplier);
    end
end

fprintf('\nDAY 8 NATIVE SATELLITESCENARIO\n');
fprintf('Moving scenarios:          %d (%d real, %d theoretical)\n', ...
    day08.analysis.scenarioCount,day08.analysis.realSatelliteCount, ...
    day08.analysis.scenarioCount-day08.analysis.realSatelliteCount);
fprintf('Timeline:                  24 hours at %.0f-second samples\n', ...
    scenario.SampleTime);
fprintf('Trajectory source:         Saved Day 8 J2000/FK5 ephemerides\n');
fprintf('Playback:                  %dx real time\n', ...
    options.PlaybackSpeedMultiplier);
fprintf('Verification checks:       %d/%d passed\n\n', ...
    verification.passedTests,verification.totalTests);
disp(summary(:,{'ScenarioName','Source', ...
    'IntegratedDrift24HoursMicroseconds'}));

outputs = struct('scenario',scenario,'satellites',satellites, ...
    'viewer',viewer,'controls',controls,'analysis',day08.analysis,'summary',summary, ...
    'verification',verification);
end
