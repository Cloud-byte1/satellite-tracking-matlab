function report = runDay04EnergyTests(records, constants)
%RUNDAY04ENERGYTESTS Verify the Day 4 Task 1 energy calculations.

arguments
    records (:,1) struct
    constants (1,1) struct
end

count = numel(records);
initialAnalyticalErrors = zeros(count,1);
maximumRelativeDrifts = zeros(count,1);
finiteHistories = false(count,1);

for index = 1:count
    expectedEnergy = -constants.muEarth/(2*records(index).scenario.aKm);
    initialAnalyticalErrors(index) = abs( ...
        records(index).energy.initialEnergyKm2PerSec2 - expectedEnergy);
    maximumRelativeDrifts(index) = records(index).energy.maxRelativeDrift;
    finiteHistories(index) = all(isfinite( ...
        records(index).energy.specificEnergyKm2PerSec2));
end

testName = [ ...
    "Initial energy agrees with -mu/(2a)"; ...
    "Relative energy drift remains bounded"; ...
    "Every energy-history sample is finite"];
measuredValue = [max(initialAnalyticalErrors); max(maximumRelativeDrifts); ...
    double(all(finiteHistories))];
tolerance = [1e-11; 1e-9; 1];
comparison = ["<="; "<="; "=="];
unit = ["km^2/s^2"; "relative"; "logical"];
passed = [measuredValue(1) <= tolerance(1); ...
    measuredValue(2) <= tolerance(2); measuredValue(3) == tolerance(3)];

results = table(testName, measuredValue, comparison, tolerance, unit, passed, ...
    'VariableNames', {'Test','MeasuredValue','Comparison','Tolerance','Unit','Passed'});
report = struct('results', results, 'totalTests', height(results), ...
    'passedTests', sum(passed), 'allPassed', all(passed));

if ~report.allPassed
    failedNames = strjoin(cellstr(testName(~passed)), ', ');
    error('runDay04EnergyTests:VerificationFailure', ...
        'Day 4 Task 1 verification failed: %s', failedNames);
end
end
