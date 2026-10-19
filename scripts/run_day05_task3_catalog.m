function outputs = run_day05_task3_catalog(options)
%RUN_DAY05_TASK3_CATALOG Retrieve and verify the five-satellite Day 5 dataset.

arguments
    options.ForceRefresh (1,1) logical = false
end

scriptDirectory = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDirectory);
addpath(projectRoot);
setupProject();
addpath(fullfile(projectRoot, 'tests'));

targets = day05SatelliteCatalog();
cacheDirectory = fullfile(projectRoot, 'data', 'raw');
[catalog, retrievals] = retrieveTrackedSatelliteCatalog(targets, ...
    CacheDirectory=cacheDirectory, ForceRefresh=options.ForceRefresh);
verification = runDay05Task3Tests(catalog, targets);

resultsDirectory = fullfile(projectRoot, 'results');
processedDirectory = fullfile(projectRoot, 'data', 'processed');
writetable(catalog, fullfile(resultsDirectory, ...
    'day05_task3_satellite_catalog.csv'));
writetable(verification.results, fullfile(resultsDirectory, ...
    'day05_task3_verification.csv'));
writetable(catalog, fullfile(processedDirectory, ...
    'day05_satellite_catalog_latest.csv'));
save(fullfile(processedDirectory, 'day05_satellite_catalog_latest.mat'), ...
    'catalog', 'targets', 'retrievals', 'verification');

networkResponses = sum(catalog.RetrievalSource == "network");
cacheResponses = sum(contains(catalog.RetrievalSource, "cache"));
fprintf('\nDAY 5 TASK 3: FIVE-SATELLITE CATALOG\n');
fprintf('Records assembled:    %d\n', height(catalog));
fprintf('Network responses:    %d\n', networkResponses);
fprintf('Cache responses:      %d\n', cacheResponses);
fprintf('Mission groups:       %d\n', numel(unique(catalog.Constellation)));
fprintf('Verification checks:  %d/%d passed\n\n', ...
    verification.passedTests, verification.totalTests);
disp(catalog(:, {'SatelliteName','NORADCatalogID','Constellation', ...
    'ElementEpochUtc','InclinationDeg','Eccentricity', ...
    'ApproximatePeriodMinutes','ElementAgeHours','RetrievalSource'}));

outputs = struct('catalog', catalog, 'targets', targets, ...
    'retrievals', retrievals, 'verification', verification);
end
