function outputs = run_day05_task2_retrieval(options)
%RUN_DAY05_TASK2_RETRIEVAL Verify retrieval logic and fetch one live ISS record.

arguments
    options.ForceRefresh (1,1) logical = false
end

scriptDirectory = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDirectory);
addpath(projectRoot);
setupProject();
addpath(fullfile(projectRoot, 'tests'));

offlineVerification = runDay05Task2Tests();
cacheDirectory = fullfile(projectRoot, 'data', 'raw');
live = fetchCelesTrakGp("CATNR", "25544", ...
    CacheDirectory=cacheDirectory, ForceRefresh=options.ForceRefresh);

records = live.Records;
retrievedAt = live.Metadata.RetrievedAtUtc;
elementAgesHours = hours(retrievedAt - records.EPOCH);
summary = table( ...
    live.Metadata.Source, live.Metadata.QueryName, live.Metadata.QueryValue, ...
    live.Metadata.RecordCount, live.Metadata.RequestDurationSec, retrievedAt, ...
    min(records.EPOCH), max(records.EPOCH), min(elementAgesHours), ...
    max(elementAgesHours), string(live.Metadata.RawFileName), ...
    'VariableNames', {'Source','QueryName','QueryValue','RecordCount', ...
    'RequestDurationSec','RetrievedAtUtc','MinimumElementEpochUtc', ...
    'MaximumElementEpochUtc','MinimumElementAgeHours', ...
    'MaximumElementAgeHours','RawFileName'});

resultsDirectory = fullfile(projectRoot, 'results');
writetable(summary, fullfile(resultsDirectory, ...
    'day05_task2_retrieval_summary.csv'));
writetable(offlineVerification.results, fullfile(resultsDirectory, ...
    'day05_task2_offline_verification.csv'));
save(fullfile(resultsDirectory, 'day05_task2_live_response.mat'), ...
    'live', 'summary', 'offlineVerification');

fprintf('\nDAY 5 TASK 2: CELESTRAK RETRIEVAL AND CACHE\n');
fprintf('Offline checks:       %d/%d passed\n', ...
    offlineVerification.passedTests, offlineVerification.totalTests);
fprintf('Response source:      %s\n', live.Metadata.Source);
fprintf('Records returned:     %d\n', height(records));
fprintf('Network duration:     %.3f s (original retrieval)\n', ...
    live.Metadata.RequestDurationSec);
fprintf('Retrieved at UTC:     %s\n', string(retrievedAt));
fprintf('Element epoch UTC:    %s\n', string(records.EPOCH(1)));
fprintf('Element age:          %.3f h\n\n', elementAgesHours(1));

outputs = struct('live', live, 'summary', summary, ...
    'offlineVerification', offlineVerification);
end
