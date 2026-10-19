function satrec = initializeSgp4FromOmm(record)
%INITIALIZESGP4FROMOMM Initialize Vallado SGP4 from one CelesTrak OMM row.
%   RECORD is a one-row table containing OMM-compatible CelesTrak CSV fields.
%   Angles and mean motion are converted to the units expected by SGP4.

arguments
    record (1,:) table
end

requiredFields = ["NORAD_CAT_ID", "EPOCH", "MEAN_MOTION", ...
    "ECCENTRICITY", "INCLINATION", "RA_OF_ASC_NODE", ...
    "ARG_OF_PERICENTER", "MEAN_ANOMALY", "BSTAR", ...
    "MEAN_MOTION_DOT", "MEAN_MOTION_DDOT"];
missingFields = setdiff(requiredFields, string(record.Properties.VariableNames));
if ~isempty(missingFields)
    error('initializeSgp4FromOmm:MissingFields', ...
        'OMM record is missing fields: %s.', ...
        strjoin(cellstr(missingFields), ', '));
end

epochUtc = record.EPOCH(1);
if ~isdatetime(epochUtc) || isnat(epochUtc)
    error('initializeSgp4FromOmm:InvalidEpoch', ...
        'EPOCH must be a valid UTC datetime.');
end
epochUtc.TimeZone = 'UTC';
epochSecond = second(epochUtc);
[julianDay, julianFraction] = jday(year(epochUtc), month(epochUtc), ...
    day(epochUtc), hour(epochUtc), minute(epochUtc), epochSecond);

xpdotp = 1440/(2*pi);
meanMotionRadPerMin = record.MEAN_MOTION(1)/xpdotp;
meanMotionDot = record.MEAN_MOTION_DOT(1)/(xpdotp*1440);
meanMotionDdot = record.MEAN_MOTION_DDOT(1)/(xpdotp*1440^2);

satrec = struct();
satrec.satnum = record.NORAD_CAT_ID(1);
satrec.jdsatepoch = julianDay;
satrec.jdsatepochf = julianFraction;
satrec.epochyr = mod(year(epochUtc), 100);
satrec.epochdays = day(epochUtc, 'dayofyear') + ...
    (hour(epochUtc)*3600 + minute(epochUtc)*60 + epochSecond)/86400;

whichConstants = 72;
operationMode = 'a';
epochDaysSince1950 = julianDay + julianFraction - 2433281.5;
satrec = sgp4init(whichConstants, operationMode, satrec, ...
    epochDaysSince1950, record.BSTAR(1), meanMotionDot, meanMotionDdot, ...
    record.ECCENTRICITY(1), deg2rad(record.ARG_OF_PERICENTER(1)), ...
    deg2rad(record.INCLINATION(1)), deg2rad(record.MEAN_ANOMALY(1)), ...
    meanMotionRadPerMin, deg2rad(record.RA_OF_ASC_NODE(1)));

if satrec.error ~= 0
    error('initializeSgp4FromOmm:InitializationFailed', ...
        'SGP4 initialization failed for catalog ID %d with code %d.', ...
        satrec.satnum, satrec.error);
end
end
