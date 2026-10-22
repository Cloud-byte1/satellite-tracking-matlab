function result = gravitationalTimeDilationModel(positionOrRadius,timestamps, ...
    muKm3PerSec2,referenceRadiusKm,speedOfLightKmPerSec,options)
%GRAVITATIONALTIMEDILATIONMODEL Integrate weak-field gravitational drift.
%   POSITIONORRADIUS is either N-by-3 position vectors in km or N orbital
%   radii in km. The correction is satellite proper time minus the proper
%   time of an idealized stationary clock at REFERENCE RADIUS:
%
%       deltaRate = mu/c^2 * (1/Rref - 1/r)
%
%   The algebraically equivalent form (r-Rref)/(Rref*r) is evaluated to
%   avoid subtracting two nearly equal gravitational potentials.

arguments
    positionOrRadius double {mustBeReal,mustBeFinite}
    timestamps
    muKm3PerSec2 (1,1) double {mustBePositive,mustBeFinite}
    referenceRadiusKm (1,1) double {mustBePositive,mustBeFinite}
    speedOfLightKmPerSec (1,1) double {mustBePositive,mustBeFinite}
    options.ReferenceClockConvention (1,1) string = ...
        "Stationary clock at the specified reference radius"
    options.CoordinateTimeConvention (1,1) string = ...
        "User-defined weak-field coordinate time"
end

[elapsedSeconds,timeType] = normalizeTimes(timestamps);
sampleCount = numel(elapsedSeconds);
if size(positionOrRadius,1)==sampleCount && size(positionOrRadius,2)==3
    radiusKm = vecnorm(positionOrRadius,2,2);
elseif isvector(positionOrRadius) && numel(positionOrRadius)==sampleCount
    radiusKm = positionOrRadius(:);
else
    error('gravitationalTimeDilationModel:SizeMismatch', ...
        'Input must be N-by-3 positions or N orbital radii.');
end
if any(radiusKm<=0)
    error('gravitationalTimeDilationModel:PositiveRadiusRequired', ...
        'Every orbital radius must be positive.');
end

potentialKm2PerSec2 = -muKm3PerSec2./radiusKm;
referencePotentialKm2PerSec2 = -muKm3PerSec2/referenceRadiusKm;
rateCorrection = (muKm3PerSec2/speedOfLightKmPerSec^2).* ...
    ((radiusKm-referenceRadiusKm)./(referenceRadiusKm.*radiusKm));
accumulatedSeconds = cumtrapz(elapsedSeconds,rateCorrection);
durationSeconds = elapsedSeconds(end);

result = struct();
result.elapsedSeconds = elapsedSeconds;
result.radiusKm = radiusKm;
result.altitudeAboveReferenceKm = radiusKm-referenceRadiusKm;
result.potentialKm2PerSec2 = potentialKm2PerSec2;
result.referencePotentialKm2PerSec2 = referencePotentialKm2PerSec2;
result.potentialDifferenceKm2PerSec2 = ...
    potentialKm2PerSec2-referencePotentialKm2PerSec2;
result.clockRateCorrection = rateCorrection;
result.accumulatedSeconds = accumulatedSeconds;
result.accumulatedNanoseconds = accumulatedSeconds*1e9;
result.accumulatedMicroseconds = accumulatedSeconds*1e6;
result.instantaneousMicrosecondsPerDay = rateCorrection*86400*1e6;
result.equivalentMicrosecondsPerDay = ...
    accumulatedSeconds(end)/durationSeconds*86400*1e6;
result.muKm3PerSec2 = muKm3PerSec2;
result.referenceRadiusKm = referenceRadiusKm;
result.speedOfLightKmPerSec = speedOfLightKmPerSec;
result.referenceClockConvention = options.ReferenceClockConvention;
result.coordinateTimeConvention = options.CoordinateTimeConvention;
result.inputTimeType = timeType;
result.signConvention = ...
    "satellite proper time minus stationary reference-clock proper time";
end

function [elapsedSeconds,timeType] = normalizeTimes(timestamps)
if isdatetime(timestamps)
    timestamps = timestamps(:);
    if isempty(timestamps.TimeZone)
        error('gravitationalTimeDilationModel:TimeZoneRequired', ...
            'Datetime timestamps must specify a time zone.');
    end
    elapsedSeconds = seconds(timestamps-timestamps(1));
    timeType = "datetime";
elseif isduration(timestamps)
    elapsedSeconds = seconds(timestamps(:)-timestamps(1));
    timeType = "duration";
elseif isnumeric(timestamps)
    elapsedSeconds = double(timestamps(:)-timestamps(1));
    timeType = "numeric seconds";
else
    error('gravitationalTimeDilationModel:InvalidTimeType', ...
        'Timestamps must be numeric seconds, durations, or datetimes.');
end
if numel(elapsedSeconds)<2 || any(~isfinite(elapsedSeconds)) || ...
        any(diff(elapsedSeconds)<=0)
    error('gravitationalTimeDilationModel:InvalidTimes', ...
        'At least two finite, strictly increasing timestamps are required.');
end
end
