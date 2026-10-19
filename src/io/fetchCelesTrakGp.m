function result = fetchCelesTrakGp(queryName, queryValue, options)
%FETCHCELESTRAKGP Retrieve validated CelesTrak GP CSV with local caching.
%   RESULT = FETCHCELESTRAKGP(NAME, VALUE) queries the official CelesTrak GP
%   endpoint. NAME is CATNR or GROUP. The function returns a table in
%   RESULT.Records and provenance in RESULT.Metadata.
%
%   A successful network response is preserved as a timestamped raw CSV. A
%   per-query metadata MAT-file identifies the newest cache entry. Fresh cache is
%   reused for two hours by default. If a request fails and any valid cache exists,
%   the function returns that cache with Source="stale-cache" and records the
%   network error. Element epochs remain in Records.EPOCH; retrieval time remains
%   separately in Metadata.RetrievedAtUtc.

arguments
    queryName (1,1) string {mustBeMember(queryName, ["CATNR", "GROUP"])}
    queryValue (1,1) string
    options.CacheDirectory (1,1) string = ""
    options.ForceRefresh (1,1) logical = false
    options.AllowStaleOnFailure (1,1) logical = true
    options.FetchFunction (1,1) function_handle = @webread
    options.NowUtc (1,1) datetime = datetime('now', 'TimeZone', 'UTC')
end

if strlength(strtrim(queryValue)) == 0
    error('fetchCelesTrakGp:EmptyQueryValue', ...
        'The CelesTrak query value cannot be empty.');
end
if isempty(options.NowUtc.TimeZone)
    error('fetchCelesTrakGp:NowMustHaveTimeZone', ...
        'NowUtc must include an explicit time zone.');
end

config = day05TrackingConfig();
if strlength(options.CacheDirectory) == 0
    functionDirectory = fileparts(mfilename('fullpath'));
    projectRoot = fileparts(fileparts(functionDirectory));
    cacheDirectory = fullfile(projectRoot, 'data', 'raw');
else
    cacheDirectory = char(options.CacheDirectory);
end
if ~exist(cacheDirectory, 'dir')
    mkdir(cacheDirectory);
end

safeKey = regexprep(char(queryName + "_" + queryValue), '[^A-Za-z0-9_-]', '_');
indexFile = fullfile(cacheDirectory, "latest_" + safeKey + ".mat");
cache = readCacheIndex(indexFile, cacheDirectory);

if ~options.ForceRefresh && cache.available
    cacheAgeHours = hours(options.NowUtc - cache.metadata.RetrievedAtUtc);
    if cacheAgeHours >= 0 && cacheAgeHours < config.cacheRefreshHours
        result = resultFromCache(cache, "cache", cacheAgeHours, "", config);
        return
    end
end

url = buildCelesTrakGpUrl(queryName, queryValue, config.format, config.baseUrl);
webOptions = weboptions('ContentType', 'text', ...
    'Timeout', config.requestTimeoutSec, 'UserAgent', config.userAgent);

requestTimer = tic;
try
    rawText = string(options.FetchFunction(char(url), webOptions));
    requestDurationSec = toc(requestTimer);
    records = validateResponse(rawText, config.requiredFields);
    if queryName == "CATNR"
        requestedCatalogId = str2double(queryValue);
        if ~isfinite(requestedCatalogId) || requestedCatalogId < 1 || ...
                fix(requestedCatalogId) ~= requestedCatalogId
            error('fetchCelesTrakGp:InvalidCatalogId', ...
                'CATNR queryValue must be a positive integer.');
        end
        if any(records.NORAD_CAT_ID ~= requestedCatalogId)
            error('fetchCelesTrakGp:CatalogMismatch', ...
                'The response contains a catalog ID different from CATNR=%s.', ...
                queryValue);
        end
    end

    timestamp = string(options.NowUtc, "yyyyMMdd'T'HHmmss'Z'");
    rawFileName = "celestrak_" + safeKey + "_" + timestamp + ".csv";
    rawFile = fullfile(cacheDirectory, rawFileName);
    writeTextFile(rawFile, rawText);

    metadata = buildMetadata(queryName, queryValue, url, rawFileName, ...
        options.NowUtc, requestDurationSec, height(records), "network", "", records);
    save(indexFile, 'metadata', 'records');
    result = struct('Records', records, 'Metadata', metadata, ...
        'RawText', rawText);
catch exception
    requestDurationSec = toc(requestTimer);
    if options.AllowStaleOnFailure && cache.available
        cacheAgeHours = hours(options.NowUtc - cache.metadata.RetrievedAtUtc);
        warning('fetchCelesTrakGp:UsingStaleCache', ...
            'CelesTrak request failed; using cached data. Cause: %s', ...
            exception.message);
        result = resultFromCache(cache, "stale-cache", cacheAgeHours, ...
            exception.message, config);
        result.Metadata.FailedRequestDurationSec = requestDurationSec;
    else
        wrapped = MException('fetchCelesTrakGp:RetrievalFailed', ...
            'CelesTrak retrieval failed for %s=%s: %s', ...
            queryName, queryValue, exception.message);
        wrapped = addCause(wrapped, exception);
        throw(wrapped)
    end
end
end

function cache = readCacheIndex(indexFile, cacheDirectory)
cache = struct('available', false, 'metadata', struct(), 'rawFile', "", ...
    'records', table());
if ~isfile(indexFile)
    return
end
loaded = load(indexFile, 'metadata');
storedVariables = who('-file', indexFile);
if any(strcmp(storedVariables, 'records'))
    storedRecords = load(indexFile, 'records');
    loaded.records = storedRecords.records;
end
if ~isfield(loaded, 'metadata') || ~isfield(loaded.metadata, 'RawFileName') || ...
        ~isfield(loaded.metadata, 'RetrievedAtUtc')
    return
end
rawFile = fullfile(cacheDirectory, loaded.metadata.RawFileName);
if ~isfile(rawFile)
    return
end
cache.available = true;
cache.metadata = loaded.metadata;
cache.rawFile = string(rawFile);
if isfield(loaded, 'records') && istable(loaded.records)
    cache.records = loaded.records;
end
end

function result = resultFromCache(cache, source, cacheAgeHours, networkError, config)
rawText = string(fileread(cache.rawFile));
if istable(cache.records) && height(cache.records) > 0
    records = cache.records;
else
    records = validateResponse(rawText, config.requiredFields);
end
metadata = cache.metadata;
metadata.Source = source;
metadata.CacheAgeHours = cacheAgeHours;
metadata.NetworkError = string(networkError);
result = struct('Records', records, 'Metadata', metadata, 'RawText', rawText);
end

function records = validateResponse(rawText, requiredFields)
if strlength(strtrim(rawText)) == 0
    error('fetchCelesTrakGp:EmptyResponse', ...
        'CelesTrak returned an empty response.');
end
leadingText = lower(strtrim(extractBefore(rawText + newline, newline)));
if startsWith(leadingText, "<html") || startsWith(leadingText, "<!doctype")
    error('fetchCelesTrakGp:HtmlResponse', ...
        'Expected CSV but received an HTML response.');
end

temporaryFile = string(tempname) + ".csv";
cleanup = onCleanup(@() deleteIfPresent(temporaryFile));
writeTextFile(temporaryFile, rawText);
try
    records = readtable(temporaryFile, 'TextType', 'string', ...
        'VariableNamingRule', 'preserve');
catch exception
    error('fetchCelesTrakGp:MalformedCsv', ...
        'The response could not be parsed as CSV: %s', exception.message);
end
if height(records) == 0
    error('fetchCelesTrakGp:NoRecords', ...
        'The response contained no orbital records.');
end

missingFields = setdiff(requiredFields, string(records.Properties.VariableNames));
if ~isempty(missingFields)
    error('fetchCelesTrakGp:MissingFields', ...
        'The response is missing required fields: %s.', ...
        strjoin(cellstr(missingFields), ', '));
end

records.NORAD_CAT_ID = numericColumn(records.NORAD_CAT_ID, 'NORAD_CAT_ID');
records.INCLINATION = numericColumn(records.INCLINATION, 'INCLINATION');
records.ECCENTRICITY = numericColumn(records.ECCENTRICITY, 'ECCENTRICITY');
records.MEAN_MOTION = numericColumn(records.MEAN_MOTION, 'MEAN_MOTION');
records.EPOCH = utcDatetimeColumn(records.EPOCH);

if any(records.NORAD_CAT_ID < 1 | fix(records.NORAD_CAT_ID) ~= records.NORAD_CAT_ID)
    error('fetchCelesTrakGp:InvalidCatalogId', ...
        'NORAD_CAT_ID values must be positive integers.');
end
if any(records.INCLINATION < 0 | records.INCLINATION > 180)
    error('fetchCelesTrakGp:InvalidInclination', ...
        'INCLINATION values must lie in [0, 180] degrees.');
end
if any(records.ECCENTRICITY < 0 | records.ECCENTRICITY >= 1)
    error('fetchCelesTrakGp:InvalidEccentricity', ...
        'ECCENTRICITY values must lie in [0, 1).');
end
if any(records.MEAN_MOTION <= 0)
    error('fetchCelesTrakGp:InvalidMeanMotion', ...
        'MEAN_MOTION values must be positive.');
end
end

function values = numericColumn(values, fieldName)
if ~isnumeric(values)
    values = str2double(string(values));
end
values = double(values);
if any(~isfinite(values))
    error('fetchCelesTrakGp:InvalidNumericField', ...
        '%s contains missing or nonnumeric values.', fieldName);
end
end

function values = utcDatetimeColumn(values)
if isdatetime(values)
    values.TimeZone = 'UTC';
else
    textValues = string(values);
    try
        values = datetime(textValues, ...
            'InputFormat', "yyyy-MM-dd'T'HH:mm:ss.SSSSSS", 'TimeZone', 'UTC');
    catch
        try
            values = datetime(textValues, ...
                'InputFormat', "yyyy-MM-dd'T'HH:mm:ss.SSS", 'TimeZone', 'UTC');
        catch exception
            error('fetchCelesTrakGp:InvalidEpoch', ...
                'EPOCH values are not valid UTC timestamps: %s', exception.message);
        end
    end
end
if any(isnat(values))
    error('fetchCelesTrakGp:InvalidEpoch', ...
        'EPOCH contains missing or invalid timestamps.');
end
end

function metadata = buildMetadata(queryName, queryValue, url, rawFileName, ...
    retrievedAtUtc, requestDurationSec, recordCount, source, networkError, records)
metadata = struct();
metadata.QueryName = queryName;
metadata.QueryValue = queryValue;
metadata.Url = url;
metadata.Format = "CSV";
metadata.Source = source;
metadata.RetrievedAtUtc = retrievedAtUtc;
metadata.RequestDurationSec = requestDurationSec;
metadata.RecordCount = recordCount;
metadata.RawFileName = rawFileName;
metadata.ElementEpochMinimumUtc = min(records.EPOCH);
metadata.ElementEpochMaximumUtc = max(records.EPOCH);
metadata.CacheAgeHours = 0;
metadata.NetworkError = string(networkError);
end

function writeTextFile(fileName, content)
fileId = fopen(fileName, 'w', 'n', 'UTF-8');
if fileId < 0
    error('fetchCelesTrakGp:FileOpenFailed', ...
        'Could not open %s for writing.', fileName);
end
cleanup = onCleanup(@() fclose(fileId));
fprintf(fileId, '%s', content);
end

function deleteIfPresent(fileName)
if isfile(fileName)
    delete(fileName);
end
end
