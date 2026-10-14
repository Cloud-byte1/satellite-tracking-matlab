function outputs = run_day02_task1_setup()
%RUN_DAY02_TASK1_SETUP Establish and verify the Day 2 data contract.

scriptDirectory = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDirectory);
addpath(projectRoot)
setupProject();
addpath(fullfile(projectRoot, 'tests'));

config = celesTrakConfig();
catalog = day02SatelliteCatalog();
verification = runDay02Task1Tests(catalog, config);

resultsDirectory = fullfile(projectRoot, 'results');
writetable(catalog, fullfile(resultsDirectory, 'day02_satellite_catalog.csv'));
writetable(verification.results, ...
    fullfile(resultsDirectory, 'day02_task1_verification.csv'));

fprintf('\nDAY 2 TASK 1: DATA CONTRACT AND SATELLITE CATALOG\n');
fprintf('Configured satellites: %d (%d ISS + %d GPS)\n', ...
    height(catalog), sum(catalog.Role == "ISS"), sum(catalog.Role == "GPS"));
fprintf('Authoritative format:  %s\n', config.primaryFormat);
fprintf('ISS query:             %s\n', verification.issUrl);
fprintf('GPS query:             %s\n', verification.gpsUrl);
fprintf('Verification tests:    %d/%d passed\n\n', ...
    verification.passedTests, verification.totalTests);

outputs = struct('config', config, 'catalog', catalog, ...
    'verification', verification);
end

