function outputs = run_day07_sgp4_two_body_comparison(options)
%RUN_DAY07_SGP4_TWO_BODY_COMPARISON Execute the complete Day 7 workflow.

arguments
    options.ForceRefresh (1,1) logical = false
    options.ExportFigures (1,1) logical = true
    options.ShowFigures (1,1) logical = true
end

scriptDirectory = fileparts(mfilename('fullpath'));
projectRoot = string(fileparts(scriptDirectory));
addpath(projectRoot); setupProject(); addpath(fullfile(projectRoot,'tests'));
config = day07ComparisonConfig(projectRoot);
targets = day07SatelliteCatalog();
[catalog,retrievals] = retrieveTrackedSatelliteCatalog(targets, ...
    CacheDirectory=fullfile(projectRoot,'data','raw'), ...
    ForceRefresh=options.ForceRefresh);
[matched,location] = ismember(catalog.NORADCatalogID,targets.CatalogNumber);
if ~all(matched)
    error('runDay07:CatalogMapping','A retrieved catalog ID is not configured.');
end
catalog.Regime = targets.Regime(location);

referenceVerification = runSgp4ReferenceTest( ...
    fullfile(projectRoot,'third_party','vallado_sgp4'));
eop = loadCelesTrakEop(config.eopFile);
runTimer = tic;
comparison = compareSgp4WithTwoBody(catalog,retrievals,eop,config);
metrics = buildDay07Metrics(comparison,catalog,config.horizonsHours, ...
    config.earthRadiusKm);
timeSeries = buildDay07TimeSeries(comparison,catalog);
verification = runDay07ComparisonTests(comparison,metrics,catalog);
runtimeSeconds = toc(runTimer);

resultsDirectory = fullfile(projectRoot,'results');
figuresDirectory = fullfile(projectRoot,'figures');
writetable(metrics,fullfile(resultsDirectory,'day07_sgp4_two_body_metrics.csv'));
writetable(timeSeries,fullfile(resultsDirectory,'day07_sgp4_two_body_timeseries.csv'));
writetable(verification.results,fullfile(resultsDirectory,'day07_verification.csv'));
writetable(catalog,fullfile(resultsDirectory,'day07_satellite_catalog.csv'));
save(fullfile(resultsDirectory,'day07_sgp4_two_body_comparison.mat'), ...
    'comparison','metrics','timeSeries','verification', ...
    'referenceVerification','catalog','targets','config','runtimeSeconds');

figureHandles = gobjects(0);
if options.ExportFigures || options.ShowFigures
    figureHandles = plotDay07ComparisonFigures(comparison,catalog,metrics, ...
        config.earthRadiusKm);
    if options.ExportFigures
        baseNames = ["day07_trajectory_comparison", ...
            "day07_position_separation","day07_rtn_components", ...
            "day07_regime_comparison"];
        for index = 1:numel(figureHandles)
            exportgraphics(figureHandles(index), ...
                fullfile(figuresDirectory,baseNames(index)+".png"), ...
                'Resolution',200);
            savefig(figureHandles(index), ...
                fullfile(figuresDirectory,baseNames(index)+".fig"));
        end
    end
    if ~options.ShowFigures
        close(figureHandles); figureHandles = gobjects(0);
    end
end

fprintf('\nDAY 7: SGP4 VERSUS TWO-BODY MODEL COMPARISON\n');
fprintf('Satellites:             %d\n',height(catalog));
fprintf('Orbital regimes:        %d\n',numel(unique(catalog.Regime)));
fprintf('Horizon cases:          %d\n',height(metrics));
fprintf('Trajectory samples:     %d\n',height(timeSeries));
fprintf('Reference checks:       %d/%d passed\n', ...
    referenceVerification.passedTests,referenceVerification.totalTests);
fprintf('Day 7 checks:           %d/%d passed\n', ...
    verification.passedTests,verification.totalTests);
fprintf('Analysis runtime:       %.3f s\n',runtimeSeconds);
[maximumSeparation,row] = max(metrics.MaximumPositionSeparationKm);
fprintf('Largest separation:     %.3f km (%s, %.0f h case)\n\n', ...
    maximumSeparation,metrics.SatelliteName(row),metrics.HorizonHours(row));
disp(metrics(:,{'SatelliteName','Regime','HorizonHours', ...
    'FinalPositionSeparationKm','MaximumPositionSeparationKm', ...
    'RmsPositionSeparationKm','FinalVelocityDifferenceKmPerSec'}));

outputs = struct('comparison',comparison,'metrics',metrics, ...
    'timeSeries',timeSeries,'verification',verification, ...
    'referenceVerification',referenceVerification,'catalog',catalog, ...
    'config',config,'runtimeSeconds',runtimeSeconds,'figures',figureHandles);
end
