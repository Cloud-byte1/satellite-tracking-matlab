function outputs = run_day04_task1_energy(options)
%RUN_DAY04_TASK1_ENERGY Analyze and plot specific-energy conservation.
%   This Task 1 workflow reuses the verified six-scenario Day 3 propagation.

arguments
    options.GenerateFigure (1,1) logical = true
    options.ExportPng (1,1) logical = true
end

scriptDirectory = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDirectory);
addpath(projectRoot);
setupProject();
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'tests'));

day03 = run_day03_advanced_orbits( ...
    GenerateFigure=false, ExportPng=false);
records = repmat(struct('scenario', struct(), 'energy', struct()), ...
    numel(day03.runs), 1);
for index = 1:numel(day03.runs)
    records(index).scenario = day03.runs(index).scenario;
    records(index).energy = energyConservationAnalysis( ...
        day03.runs(index).solution);
end

constants = earthConstants();
verification = runDay04EnergyTests(records, constants);
summary = buildEnergySummary(records);

resultsDirectory = fullfile(projectRoot, 'results');
figuresDirectory = fullfile(projectRoot, 'figures');
writetable(summary, fullfile(resultsDirectory, ...
    'day04_task1_energy_conservation.csv'));
writetable(verification.results, fullfile(resultsDirectory, ...
    'day04_task1_energy_verification.csv'));
save(fullfile(resultsDirectory, 'day04_task1_energy_histories.mat'), ...
    'records', 'summary', 'verification');

figureHandle = gobjects(0);
if options.GenerateFigure
    figureHandle = plotEnergyConservation(records);
    savefig(figureHandle, fullfile(figuresDirectory, ...
        'day04_task1_energy_conservation.fig'));
    if options.ExportPng
        exportgraphics(figureHandle, fullfile(figuresDirectory, ...
            'day04_task1_energy_conservation.png'), 'Resolution', 220);
    end
end

fprintf('\nDAY 4 TASK 1: SPECIFIC ORBITAL ENERGY\n');
fprintf('Scenarios analyzed:  %d\n', numel(records));
fprintf('Verification checks: %d/%d passed\n', ...
    verification.passedTests, verification.totalTests);
disp(summary);

outputs = struct('records', records, 'summary', summary, ...
    'verification', verification, 'figure', figureHandle);
end

function summary = buildEnergySummary(records)
count = numel(records);
Scenario = strings(count,1);
InitialEnergyKm2PerSec2 = zeros(count,1);
FinalEnergyKm2PerSec2 = zeros(count,1);
FinalSignedDeviationKm2PerSec2 = zeros(count,1);
MaximumAbsoluteDeviationKm2PerSec2 = zeros(count,1);
MaximumRelativeDrift = zeros(count,1);
FinalRelativeDrift = zeros(count,1);

for index = 1:count
    energy = records(index).energy;
    Scenario(index) = records(index).scenario.name;
    InitialEnergyKm2PerSec2(index) = energy.initialEnergyKm2PerSec2;
    FinalEnergyKm2PerSec2(index) = energy.finalEnergyKm2PerSec2;
    FinalSignedDeviationKm2PerSec2(index) = ...
        energy.finalSignedDeviationKm2PerSec2;
    MaximumAbsoluteDeviationKm2PerSec2(index) = ...
        energy.maxAbsoluteDeviationKm2PerSec2;
    MaximumRelativeDrift(index) = energy.maxRelativeDrift;
    FinalRelativeDrift(index) = energy.finalRelativeDrift;
end

summary = table(Scenario, InitialEnergyKm2PerSec2, ...
    FinalEnergyKm2PerSec2, FinalSignedDeviationKm2PerSec2, ...
    MaximumAbsoluteDeviationKm2PerSec2, MaximumRelativeDrift, ...
    FinalRelativeDrift);
end
