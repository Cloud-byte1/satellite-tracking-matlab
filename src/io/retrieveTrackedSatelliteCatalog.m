function [catalog, retrievals] = retrieveTrackedSatelliteCatalog(targets, options)
%RETRIEVETRACKEDSATELLITECATALOG Retrieve and assemble selected GP records.
%   Each target is queried by stable NORAD catalog number. The returned table
%   preserves the element epoch and retrieval timestamp as separate UTC values.

arguments
    targets (:,:) table
    options.CacheDirectory (1,1) string = ""
    options.ForceRefresh (1,1) logical = false
end

requiredTargetFields = ["MissionRole", "Constellation", "CatalogNumber", ...
    "ExpectedNamePattern"];
missingTargetFields = setdiff(requiredTargetFields, ...
    string(targets.Properties.VariableNames));
if ~isempty(missingTargetFields)
    error('retrieveTrackedSatelliteCatalog:MissingTargetFields', ...
        'Target table is missing fields: %s.', ...
        strjoin(cellstr(missingTargetFields), ', '));
end
if numel(unique(targets.CatalogNumber)) ~= height(targets)
    error('retrieveTrackedSatelliteCatalog:DuplicateTargets', ...
        'Target catalog numbers must be unique.');
end

count = height(targets);
retrievals = repmat(struct('Records', table(), 'Metadata', struct(), ...
    'RawText', ""), count, 1);

SatelliteName = strings(count,1);
NORADCatalogID = zeros(count,1);
MissionRole = string(targets.MissionRole);
Constellation = string(targets.Constellation);
ElementEpochUtc = NaT(count,1,'TimeZone','UTC');
InclinationDeg = zeros(count,1);
Eccentricity = zeros(count,1);
MeanMotionRevPerDay = zeros(count,1);
ApproximatePeriodMinutes = zeros(count,1);
RetrievalTimeUtc = NaT(count,1,'TimeZone','UTC');
ElementAgeHours = zeros(count,1);
RetrievalSource = strings(count,1);
RawFileName = strings(count,1);

for index = 1:count
    fetchArguments = { ...
        'ForceRefresh', options.ForceRefresh};
    if strlength(options.CacheDirectory) > 0
        fetchArguments = [fetchArguments, ...
            {'CacheDirectory', options.CacheDirectory}]; %#ok<AGROW>
    end
    fetched = fetchCelesTrakGp("CATNR", string(targets.CatalogNumber(index)), ...
        fetchArguments{:});
    records = fetched.Records;
    matchingRows = records.NORAD_CAT_ID == targets.CatalogNumber(index);
    if sum(matchingRows) ~= 1
        error('retrieveTrackedSatelliteCatalog:RecordCountMismatch', ...
            'Expected exactly one record for catalog ID %d; received %d.', ...
            targets.CatalogNumber(index), sum(matchingRows));
    end
    record = records(matchingRows,:);
    actualName = string(record.OBJECT_NAME(1));
    if isempty(regexpi(actualName, targets.ExpectedNamePattern(index), 'once'))
        error('retrieveTrackedSatelliteCatalog:NameMismatch', ...
            'Catalog ID %d returned unexpected name "%s".', ...
            targets.CatalogNumber(index), actualName);
    end

    retrievals(index) = fetched;
    SatelliteName(index) = actualName;
    NORADCatalogID(index) = record.NORAD_CAT_ID(1);
    ElementEpochUtc(index) = record.EPOCH(1);
    InclinationDeg(index) = record.INCLINATION(1);
    Eccentricity(index) = record.ECCENTRICITY(1);
    MeanMotionRevPerDay(index) = record.MEAN_MOTION(1);
    ApproximatePeriodMinutes(index) = 1440/record.MEAN_MOTION(1);
    RetrievalTimeUtc(index) = fetched.Metadata.RetrievedAtUtc;
    ElementAgeHours(index) = hours( ...
        RetrievalTimeUtc(index) - ElementEpochUtc(index));
    RetrievalSource(index) = fetched.Metadata.Source;
    RawFileName(index) = fetched.Metadata.RawFileName;
end

ElementEpochUtc.Format = 'yyyy-MM-dd''T''HH:mm:ss.SSSSSS''Z''';
RetrievalTimeUtc.Format = 'yyyy-MM-dd''T''HH:mm:ss.SSSSSS''Z''';
catalog = table(SatelliteName, NORADCatalogID, MissionRole, Constellation, ...
    ElementEpochUtc, InclinationDeg, Eccentricity, MeanMotionRevPerDay, ...
    ApproximatePeriodMinutes, RetrievalTimeUtc, ElementAgeHours, ...
    RetrievalSource, RawFileName);
end
