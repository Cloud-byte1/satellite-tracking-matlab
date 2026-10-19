function result = fetchCelesTrakTleCatalog(targets, options)
%FETCHCELESTRAKTLECATALOG Retrieve validated TLEs for satelliteScenario.
%   The existing project keeps OMM/CSV as its analysis source of record. This
%   adapter retrieves the equivalent CelesTrak TLE representation because the
%   native satelliteScenario SGP4 importer accepts TLE or CCSDS OMM files.

arguments
    targets (:,:) table
    options.CacheDirectory (1,1) string = ""
    options.OutputFile (1,1) string = ""
    options.ForceRefresh (1,1) logical = false
    options.AllowStaleOnFailure (1,1) logical = true
    options.FetchFunction (1,1) function_handle = @webread
    options.NowUtc (1,1) datetime = datetime('now','TimeZone','UTC')
end

requiredFields = ["CatalogNumber","ExpectedNamePattern"];
missingFields = setdiff(requiredFields,string(targets.Properties.VariableNames));
if ~isempty(missingFields)
    error('fetchCelesTrakTleCatalog:MissingTargetFields', ...
        'Target table is missing fields: %s.',strjoin(cellstr(missingFields),', '));
end
if isempty(options.NowUtc.TimeZone)
    error('fetchCelesTrakTleCatalog:TimeZoneRequired', ...
        'NowUtc must include an explicit time zone.');
end
options.NowUtc.TimeZone = 'UTC';

functionDirectory = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(functionDirectory));
if strlength(options.CacheDirectory) == 0
    cacheDirectory = fullfile(projectRoot,'data','raw');
else
    cacheDirectory = char(options.CacheDirectory);
end
if strlength(options.OutputFile) == 0
    outputFile = fullfile(projectRoot,'data','processed', ...
        'day05_satellite_scenario_latest.tle');
else
    outputFile = char(options.OutputFile);
end
if ~exist(cacheDirectory,'dir')
    mkdir(cacheDirectory);
end
outputDirectory = fileparts(outputFile);
if ~exist(outputDirectory,'dir')
    mkdir(outputDirectory);
end

config = day05TrackingConfig();
count = height(targets);
combinedLines = strings(0,1);
SatelliteName = strings(count,1);
NORADCatalogID = double(targets.CatalogNumber);
RetrievalTimeUtc = NaT(count,1,'TimeZone','UTC');
Source = strings(count,1);
SourceUrl = strings(count,1);
RawFileName = strings(count,1);

for index = 1:count
    catalogId = targets.CatalogNumber(index);
    indexFile = fullfile(cacheDirectory, ...
        sprintf('latest_TLE_CATNR_%d.mat',catalogId));
    cache = readCache(indexFile,cacheDirectory,catalogId, ...
        targets.ExpectedNamePattern(index));
    useFreshCache = false;
    if cache.available && ~options.ForceRefresh
        cacheAgeHours = hours(options.NowUtc-cache.metadata.RetrievedAtUtc);
        useFreshCache = cacheAgeHours >= 0 && ...
            cacheAgeHours < config.cacheRefreshHours;
    end

    if useFreshCache
        lines = cache.lines;
        metadata = cache.metadata;
        metadata.Source = "cache";
    else
        url = string(config.baseUrl) + "?CATNR=" + string(catalogId) + ...
            "&FORMAT=TLE";
        webOptions = weboptions('ContentType','text', ...
            'Timeout',config.requestTimeoutSec,'UserAgent',config.userAgent);
        try
            rawText = string(options.FetchFunction(char(url),webOptions));
            lines = validateTle(rawText,catalogId, ...
                targets.ExpectedNamePattern(index));
            timestamp = string(options.NowUtc,"yyyyMMdd'T'HHmmss'Z'");
            rawFileName = sprintf('celestrak_CATNR_%d_%s.tle', ...
                catalogId,char(timestamp));
            writeLines(fullfile(cacheDirectory,rawFileName),lines);
            metadata = struct('RetrievedAtUtc',options.NowUtc, ...
                'Source',"network",'Url',url, ...
                'RawFileName',string(rawFileName));
            save(indexFile,'metadata');
        catch exception
            if ~(options.AllowStaleOnFailure && cache.available)
                wrapped = MException( ...
                    'fetchCelesTrakTleCatalog:RetrievalFailed', ...
                    'TLE retrieval failed for CATNR=%d: %s', ...
                    catalogId,exception.message);
                wrapped = addCause(wrapped,exception);
                throw(wrapped)
            end
            warning('fetchCelesTrakTleCatalog:UsingStaleCache', ...
                'CelesTrak request failed; using cached TLE for %d. Cause: %s', ...
                catalogId,exception.message);
            lines = cache.lines;
            metadata = cache.metadata;
            metadata.Source = "stale-cache";
        end
    end

    combinedLines = [combinedLines; lines]; %#ok<AGROW>
    SatelliteName(index) = strtrim(lines(1));
    RetrievalTimeUtc(index) = metadata.RetrievedAtUtc;
    Source(index) = metadata.Source;
    SourceUrl(index) = metadata.Url;
    RawFileName(index) = metadata.RawFileName;
end

writeLines(outputFile,combinedLines);
RetrievalTimeUtc.Format = 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''';
catalog = table(SatelliteName,NORADCatalogID,RetrievalTimeUtc,Source, ...
    SourceUrl,RawFileName);
result = struct('File',string(outputFile),'Catalog',catalog, ...
    'RetrievedAtUtc',options.NowUtc,'RecordCount',count);
end

function cache = readCache(indexFile,cacheDirectory,catalogId,namePattern)
cache = struct('available',false,'metadata',struct(),'lines',strings(0,1));
if ~isfile(indexFile)
    return
end
loaded = load(indexFile,'metadata');
if ~isfield(loaded,'metadata') || ...
        ~all(isfield(loaded.metadata,{'RetrievedAtUtc','RawFileName','Url'}))
    return
end
rawFile = fullfile(cacheDirectory,loaded.metadata.RawFileName);
if ~isfile(rawFile)
    return
end
try
    lines = validateTle(string(fileread(rawFile)),catalogId,namePattern);
catch
    return
end
cache.available = true;
cache.metadata = loaded.metadata;
cache.lines = lines;
end

function lines = validateTle(rawText,catalogId,namePattern)
rawText = replace(rawText,char(13),"");
lines = splitlines(rawText);
lines = strip(lines,'right');
lines = lines(strlength(strtrim(lines)) > 0);
if numel(lines) ~= 3
    error('fetchCelesTrakTleCatalog:InvalidLineCount', ...
        'Expected a name and two TLE lines for catalog ID %d.',catalogId);
end
line1 = char(lines(2));
line2 = char(lines(3));
if numel(line1) ~= 69 || numel(line2) ~= 69 || ...
        line1(1) ~= '1' || line2(1) ~= '2'
    error('fetchCelesTrakTleCatalog:InvalidFormat', ...
        'CelesTrak returned malformed TLE lines for catalog ID %d.',catalogId);
end
line1Id = str2double(strtrim(line1(3:7)));
line2Id = str2double(strtrim(line2(3:7)));
if line1Id ~= catalogId || line2Id ~= catalogId
    error('fetchCelesTrakTleCatalog:CatalogMismatch', ...
        'TLE catalog identifiers do not match requested ID %d.',catalogId);
end
if isempty(regexpi(char(lines(1)),char(namePattern),'once'))
    error('fetchCelesTrakTleCatalog:NameMismatch', ...
        'TLE name "%s" does not match the expected spacecraft.',lines(1));
end
if tleChecksum(line1) ~= str2double(line1(69)) || ...
        tleChecksum(line2) ~= str2double(line2(69))
    error('fetchCelesTrakTleCatalog:ChecksumFailure', ...
        'TLE checksum failed for catalog ID %d.',catalogId);
end
end

function value = tleChecksum(line)
value = 0;
for index = 1:68
    character = line(index);
    if character >= '0' && character <= '9'
        value = value + double(character-'0');
    elseif character == '-'
        value = value + 1;
    end
end
value = mod(value,10);
end

function writeLines(fileName,lines)
fileId = fopen(fileName,'w','n','UTF-8');
if fileId < 0
    error('fetchCelesTrakTleCatalog:FileOpenFailed', ...
        'Could not open %s for writing.',fileName);
end
cleanup = onCleanup(@() fclose(fileId));
for index = 1:numel(lines)
    fprintf(fileId,'%s\n',char(lines(index)));
end
end
