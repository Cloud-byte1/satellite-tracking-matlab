function simulation = propagateSgp4Catalog(catalog, retrievals, options)
%PROPAGATESGP4CATALOG Propagate cached real-satellite records in TEME.

arguments
    catalog (:,:) table
    retrievals (:,1) struct
    options.StartTimeUtc (1,1) datetime = max(catalog.RetrievalTimeUtc)
    options.DurationHours (1,1) double {mustBePositive, mustBeFinite} = 12
    options.StepSeconds (1,1) double {mustBePositive, mustBeFinite} = 120
end

if height(catalog) ~= numel(retrievals)
    error('propagateSgp4Catalog:CountMismatch', ...
        'Catalog rows and retrieval records must have equal counts.');
end
startTimeUtc = options.StartTimeUtc;
if isempty(startTimeUtc.TimeZone)
    error('propagateSgp4Catalog:StartTimeZoneRequired', ...
        'StartTimeUtc must have an explicit time zone.');
end
startTimeUtc.TimeZone = 'UTC';
elapsedSeconds = (0:options.StepSeconds:options.DurationHours*3600).';
if elapsedSeconds(end) < options.DurationHours*3600
    elapsedSeconds(end+1,1) = options.DurationHours*3600;
end
timeUtc = startTimeUtc + seconds(elapsedSeconds);

sampleCount = numel(timeUtc);
satelliteCount = height(catalog);
positionTemeKm = zeros(sampleCount,3,satelliteCount);
velocityTemeKmPerSec = zeros(sampleCount,3,satelliteCount);
sgp4ErrorCode = zeros(sampleCount,satelliteCount);

for satelliteIndex = 1:satelliteCount
    records = retrievals(satelliteIndex).Records;
    matching = records.NORAD_CAT_ID == catalog.NORADCatalogID(satelliteIndex);
    if sum(matching) ~= 1
        error('propagateSgp4Catalog:RecordMismatch', ...
            'Expected one source row for catalog ID %d.', ...
            catalog.NORADCatalogID(satelliteIndex));
    end
    record = records(matching,:);
    satrec = initializeSgp4FromOmm(record);
    minutesAtStart = minutes(startTimeUtc - record.EPOCH(1));
    for timeIndex = 1:sampleCount
        minutesSinceEpoch = minutesAtStart + elapsedSeconds(timeIndex)/60;
        [satrec, position, velocity] = sgp4(satrec, minutesSinceEpoch);
        sgp4ErrorCode(timeIndex,satelliteIndex) = satrec.error;
        if satrec.error ~= 0
            error('propagateSgp4Catalog:PropagationFailed', ...
                'SGP4 failed for catalog ID %d at %.3f min with code %d.', ...
                catalog.NORADCatalogID(satelliteIndex), ...
                minutesSinceEpoch, satrec.error);
        end
        positionTemeKm(timeIndex,:,satelliteIndex) = position;
        velocityTemeKmPerSec(timeIndex,:,satelliteIndex) = velocity;
    end
end

simulation = struct();
simulation.startTimeUtc = startTimeUtc;
simulation.timeUtc = timeUtc;
simulation.elapsedSeconds = elapsedSeconds;
simulation.durationHours = options.DurationHours;
simulation.stepSeconds = options.StepSeconds;
simulation.satelliteNames = catalog.SatelliteName;
simulation.catalogIds = catalog.NORADCatalogID;
simulation.elementEpochUtc = catalog.ElementEpochUtc;
simulation.positionTemeKm = positionTemeKm;
simulation.velocityTemeKmPerSec = velocityTemeKmPerSec;
simulation.sgp4ErrorCode = sgp4ErrorCode;
simulation.referenceFrame = "TEME";
simulation.propagator = "SGP4 (Vallado AIAA 2006-6753 MATLAB reference)";
end
