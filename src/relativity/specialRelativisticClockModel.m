function result = specialRelativisticClockModel(velocity,timestamps, ...
    speedOfLightKmPerSec,options)
%SPECIALRELATIVISTICCLOCKMODEL Integrate velocity-dependent proper time.
%   RESULT = SPECIALRELATIVISTICCLOCKMODEL(VELOCITY,TIMESTAMPS,C) accepts
%   either N-by-3 velocity vectors in km/s or N speed magnitudes in km/s.
%   TIMESTAMPS may contain elapsed numeric seconds, durations, or timezone-
%   aware datetimes. The returned difference is satellite proper time minus
%   coordinate time; it is negative for nonzero velocity.
%
%   The exact clock-rate difference uses the cancellation-resistant identity
%       sqrt(1-beta^2)-1 = -beta^2/(1+sqrt(1-beta^2)).

arguments
    velocity double {mustBeReal,mustBeFinite}
    timestamps
    speedOfLightKmPerSec (1,1) double {mustBePositive,mustBeFinite}
    options.CoordinateTimeConvention (1,1) string = ...
        "User-defined inertial coordinate time"
end

if isdatetime(timestamps)
    timestamps = timestamps(:);
    if isempty(timestamps.TimeZone)
        error('specialRelativisticClockModel:TimeZoneRequired', ...
            'Datetime timestamps must specify a time zone.');
    end
    elapsedSeconds = seconds(timestamps-timestamps(1));
elseif isduration(timestamps)
    elapsedSeconds = seconds(timestamps(:)-timestamps(1));
elseif isnumeric(timestamps)
    elapsedSeconds = double(timestamps(:)-timestamps(1));
else
    error('specialRelativisticClockModel:InvalidTimeType', ...
        'Timestamps must be numeric seconds, durations, or datetimes.');
end

sampleCount = numel(elapsedSeconds);
if sampleCount < 2 || any(~isfinite(elapsedSeconds)) || ...
        any(diff(elapsedSeconds)<=0)
    error('specialRelativisticClockModel:InvalidTimes', ...
        'At least two finite, strictly increasing timestamps are required.');
end

if size(velocity,1)==sampleCount && size(velocity,2)==3
    speedSquared = sum(velocity.^2,2);
    speedKmPerSec = sqrt(speedSquared);
elseif isvector(velocity) && numel(velocity)==sampleCount
    speedKmPerSec = velocity(:);
    if any(speedKmPerSec<0)
        error('specialRelativisticClockModel:NegativeSpeed', ...
            'Speed magnitudes cannot be negative.');
    end
    speedSquared = speedKmPerSec.^2;
else
    error('specialRelativisticClockModel:SizeMismatch', ...
        'Velocity must be N-by-3 vectors or N speed magnitudes.');
end

betaSquared = speedSquared/speedOfLightKmPerSec^2;
if any(betaSquared>=1)
    error('specialRelativisticClockModel:SubluminalRequired', ...
        'All speeds must be less than the speed of light.');
end

properTimeRate = sqrt(1-betaSquared);
lorentzFactor = 1./properTimeRate;
exactRateCorrection = -betaSquared./(1+properTimeRate);
approximateRateCorrection = -0.5*betaSquared;
accumulatedExactSeconds = cumtrapz(elapsedSeconds,exactRateCorrection);
accumulatedApproximateSeconds = cumtrapz( ...
    elapsedSeconds,approximateRateCorrection);
durationSeconds = elapsedSeconds(end)-elapsedSeconds(1);

result = struct();
result.elapsedSeconds = elapsedSeconds;
result.speedKmPerSec = speedKmPerSec;
result.betaSquared = betaSquared;
result.lorentzFactor = lorentzFactor;
result.properTimeRate = properTimeRate;
result.exactClockRateCorrection = exactRateCorrection;
result.approximateClockRateCorrection = approximateRateCorrection;
result.accumulatedExactSeconds = accumulatedExactSeconds;
result.accumulatedApproximateSeconds = accumulatedApproximateSeconds;
result.accumulatedExactNanoseconds = accumulatedExactSeconds*1e9;
result.accumulatedExactMicroseconds = accumulatedExactSeconds*1e6;
result.accumulatedApproximateMicroseconds = ...
    accumulatedApproximateSeconds*1e6;
result.instantaneousExactMicrosecondsPerDay = ...
    exactRateCorrection*86400*1e6;
result.instantaneousApproximateMicrosecondsPerDay = ...
    approximateRateCorrection*86400*1e6;
result.equivalentExactMicrosecondsPerDay = ...
    accumulatedExactSeconds(end)/durationSeconds*86400*1e6;
result.equivalentApproximateMicrosecondsPerDay = ...
    accumulatedApproximateSeconds(end)/durationSeconds*86400*1e6;
result.speedOfLightKmPerSec = speedOfLightKmPerSec;
result.coordinateTimeConvention = options.CoordinateTimeConvention;
result.signConvention = "satellite proper time minus coordinate time";
end
