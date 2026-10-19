function outputs = run_day03_advanced_orbits(options)
%RUN_DAY03_ADVANCED_ORBITS Propagate, analyze, plot, and verify six orbits.
%   OUTPUTS = RUN_DAY03_ADVANCED_ORBITS() uses base MATLAB only and writes
%   auditable CSV/MAT results plus a professional 3D comparison figure.

arguments
    options.GenerateFigure (1,1) logical = true
    options.ExportPng (1,1) logical = true
    options.SamplesPerOrbit (1,1) double {mustBeInteger, mustBeGreaterThanOrEqual(options.SamplesPerOrbit, 361)} = 721
end

scriptDirectory = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDirectory);
addpath(projectRoot);
setupProject();
addpath(fullfile(projectRoot, 'tests'));

constants = earthConstants();
scenarios = day03OrbitScenarios(constants.radiusEarth);
runs = repmat(struct('scenario', struct(), 'initialState', zeros(6,1), ...
    'solution', struct(), 'analysis', struct()), numel(scenarios), 1);

for index = 1:numel(scenarios)
    scenario = scenarios(index);
    [position, velocity] = orbitalElementsToState(scenario, constants.muEarth);
    initialState = [position; velocity];
    periodSec = 2*pi*sqrt(scenario.aKm^3/constants.muEarth);
    outputTimes = linspace(0, periodSec, options.SamplesPerOrbit).';
    solution = propagateTwoBody(initialState, outputTimes, constants.muEarth, ...
        RelativeTolerance=1e-11, AbsoluteTolerance=1e-12, ...
        MaximumStep=periodSec/720);
    runs(index).scenario = scenario;
    runs(index).initialState = initialState;
    runs(index).solution = solution;
    runs(index).analysis = analyzeEllipticOrbit( ...
        scenario, solution, constants.radiusEarth);
end

verification = runDay03Tests(runs, constants);
comparison = buildComparisonTable(runs);

resultsDirectory = fullfile(projectRoot, 'results');
figuresDirectory = fullfile(projectRoot, 'figures');
if ~exist(resultsDirectory, 'dir'); mkdir(resultsDirectory); end
if ~exist(figuresDirectory, 'dir'); mkdir(figuresDirectory); end

writetable(comparison, fullfile(resultsDirectory, 'day03_orbit_comparison.csv'));
writetable(verification.results, ...
    fullfile(resultsDirectory, 'day03_verification.csv'));
save(fullfile(resultsDirectory, 'day03_simulations.mat'), ...
    'runs', 'comparison', 'verification', 'constants');

figureHandle = gobjects(0);
if options.GenerateFigure
    figureHandle = plotMultipleOrbits3D(runs, constants.radiusEarth);
    savefig(figureHandle, fullfile(figuresDirectory, 'day03_multiple_orbits_3d.fig'));
    if options.ExportPng
        exportgraphics(figureHandle, ...
            fullfile(figuresDirectory, 'day03_multiple_orbits_3d.png'), ...
            'Resolution', 220);
    end
end

fprintf('\nDAY 3: ADVANCED ORBITAL DYNAMICS\n');
fprintf('Scenarios propagated: %d\n', numel(runs));
fprintf('Verification tests:   %d/%d passed\n', ...
    verification.passedTests, verification.totalTests);
disp(comparison(:, {'Scenario','PeriodMinutes','PerigeeAltitudeKm', ...
    'ApogeeAltitudeKm','MinimumSpeedKmPerSec','MaximumSpeedKmPerSec'}));

outputs = struct('runs', runs, 'comparison', comparison, ...
    'verification', verification, 'figure', figureHandle);
end

function comparison = buildComparisonTable(runs)
count = numel(runs);
Scenario = strings(count,1);
Category = strings(count,1);
SemimajorAxisKm = zeros(count,1);
EccentricitySpecified = zeros(count,1);
InclinationDeg = zeros(count,1);
PeriodMinutes = zeros(count,1);
PerigeeAltitudeKm = zeros(count,1);
ApogeeAltitudeKm = zeros(count,1);
MinimumSpeedKmPerSec = zeros(count,1);
MaximumSpeedKmPerSec = zeros(count,1);
SpecificEnergyKm2PerSec2 = zeros(count,1);
SpecificAngularMomentumKm2PerSec = zeros(count,1);
EccentricityFromState = zeros(count,1);

for index = 1:count
    scenario = runs(index).scenario;
    analysis = runs(index).analysis;
    Scenario(index) = scenario.name;
    Category(index) = scenario.category;
    SemimajorAxisKm(index) = scenario.aKm;
    EccentricitySpecified(index) = scenario.e;
    InclinationDeg(index) = scenario.iDeg;
    PeriodMinutes(index) = analysis.periodSec/60;
    PerigeeAltitudeKm(index) = analysis.perigeeAltitudeKm;
    ApogeeAltitudeKm(index) = analysis.apogeeAltitudeKm;
    MinimumSpeedKmPerSec(index) = analysis.minimumSpeedKmPerSec;
    MaximumSpeedKmPerSec(index) = analysis.maximumSpeedKmPerSec;
    SpecificEnergyKm2PerSec2(index) = analysis.specificEnergyKm2PerSec2;
    SpecificAngularMomentumKm2PerSec(index) = ...
        analysis.specificAngularMomentumKm2PerSec;
    EccentricityFromState(index) = analysis.eccentricityFromState;
end

comparison = table(Scenario, Category, SemimajorAxisKm, ...
    EccentricitySpecified, InclinationDeg, PeriodMinutes, ...
    PerigeeAltitudeKm, ApogeeAltitudeKm, MinimumSpeedKmPerSec, ...
    MaximumSpeedKmPerSec, SpecificEnergyKm2PerSec2, ...
    SpecificAngularMomentumKm2PerSec, EccentricityFromState);
end
