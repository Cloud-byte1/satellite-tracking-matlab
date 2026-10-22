function result = combinedRelativisticClockModel(positionOrRadius,velocity, ...
    timestamps,muKm3PerSec2,referenceRadiusKm,speedOfLightKmPerSec,options)
%COMBINEDRELATIVISTICCLOCKMODEL Combine leading gravitational and SR terms.
%   The default reference is an idealized stationary surface clock. This is
%   a weak-field spherical-Earth model, not the complete operational GPS
%   coordinate-time realization.

arguments
    positionOrRadius double {mustBeReal,mustBeFinite}
    velocity double {mustBeReal,mustBeFinite}
    timestamps
    muKm3PerSec2 (1,1) double {mustBePositive,mustBeFinite}
    referenceRadiusKm (1,1) double {mustBePositive,mustBeFinite}
    speedOfLightKmPerSec (1,1) double {mustBePositive,mustBeFinite}
    options.ReferenceClockConvention (1,1) string = ...
        "Stationary clock at the specified reference radius"
    options.CoordinateTimeConvention (1,1) string = ...
        "User-defined weak-field coordinate time"
end

gravitational = gravitationalTimeDilationModel(positionOrRadius,timestamps, ...
    muKm3PerSec2,referenceRadiusKm,speedOfLightKmPerSec, ...
    ReferenceClockConvention=options.ReferenceClockConvention, ...
    CoordinateTimeConvention=options.CoordinateTimeConvention);
kinematic = specialRelativisticClockModel(velocity,timestamps, ...
    speedOfLightKmPerSec, ...
    CoordinateTimeConvention=options.CoordinateTimeConvention);
if numel(gravitational.elapsedSeconds)~=numel(kinematic.elapsedSeconds)
    error('combinedRelativisticClockModel:SampleCountMismatch', ...
        'Gravitational and kinematic histories must have equal lengths.');
end

elapsedSeconds = gravitational.elapsedSeconds;
netExactRate = gravitational.clockRateCorrection+ ...
    kinematic.exactClockRateCorrection;
netApproximateRate = gravitational.clockRateCorrection+ ...
    kinematic.approximateClockRateCorrection;
accumulatedNetExactSeconds = cumtrapz(elapsedSeconds,netExactRate);
accumulatedNetApproximateSeconds = cumtrapz( ...
    elapsedSeconds,netApproximateRate);
durationSeconds = elapsedSeconds(end);

result = struct();
result.elapsedSeconds = elapsedSeconds;
result.radiusKm = gravitational.radiusKm;
result.speedKmPerSec = kinematic.speedKmPerSec;
result.gravitational = gravitational;
result.kinematic = kinematic;
result.netExactClockRateCorrection = netExactRate;
result.netApproximateClockRateCorrection = netApproximateRate;
result.accumulatedNetExactSeconds = accumulatedNetExactSeconds;
result.accumulatedNetApproximateSeconds = accumulatedNetApproximateSeconds;
result.accumulatedNetExactMicroseconds = accumulatedNetExactSeconds*1e6;
result.accumulatedNetApproximateMicroseconds = ...
    accumulatedNetApproximateSeconds*1e6;
result.instantaneousNetExactMicrosecondsPerDay = ...
    netExactRate*86400*1e6;
result.instantaneousNetApproximateMicrosecondsPerDay = ...
    netApproximateRate*86400*1e6;
result.equivalentNetExactMicrosecondsPerDay = ...
    accumulatedNetExactSeconds(end)/durationSeconds*86400*1e6;
result.equivalentNetApproximateMicrosecondsPerDay = ...
    accumulatedNetApproximateSeconds(end)/durationSeconds*86400*1e6;
result.referenceClockConvention = options.ReferenceClockConvention;
result.coordinateTimeConvention = options.CoordinateTimeConvention;
result.modelScope = ...
    "Leading weak-field monopole gravity plus special relativity; " + ...
    "Earth rotation, geopotential harmonics, tides, and operational GPS " + ...
    "time realization are excluded";
end
