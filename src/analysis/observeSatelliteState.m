function observation = observeSatelliteState(simulation,satelliteIndex,frameIndex,earthRadiusKm)
%OBSERVESATELLITESTATE Return one frame of a propagated satellite history.
%   The returned position and velocity remain in the simulation's TEME frame.
%   This function does not reinterpret TEME coordinates as latitude/longitude.

arguments
    simulation (1,1) struct
    satelliteIndex (1,1) double {mustBeInteger,mustBePositive}
    frameIndex (1,1) double {mustBeInteger,mustBePositive}
    earthRadiusKm (1,1) double {mustBePositive,mustBeFinite}
end

satelliteCount = numel(simulation.catalogIds);
sampleCount = numel(simulation.timeUtc);
if satelliteIndex > satelliteCount
    error('observeSatelliteState:SatelliteIndexOutOfRange', ...
        'satelliteIndex must be between 1 and %d.',satelliteCount);
end
if frameIndex > sampleCount
    error('observeSatelliteState:FrameIndexOutOfRange', ...
        'frameIndex must be between 1 and %d.',sampleCount);
end

positionKm = reshape(simulation.positionTemeKm(frameIndex,:,satelliteIndex),1,3);
velocityKmPerSec = reshape( ...
    simulation.velocityTemeKmPerSec(frameIndex,:,satelliteIndex),1,3);
radiusKm = norm(positionKm);

observation = struct();
observation.satelliteIndex = satelliteIndex;
observation.frameIndex = frameIndex;
observation.name = string(simulation.satelliteNames(satelliteIndex));
observation.catalogId = simulation.catalogIds(satelliteIndex);
observation.timeUtc = simulation.timeUtc(frameIndex);
observation.referenceFrame = "TEME";
observation.positionKm = positionKm;
observation.velocityKmPerSec = velocityKmPerSec;
observation.radiusKm = radiusKm;
observation.altitudeKm = radiusKm-earthRadiusKm;
observation.speedKmPerSec = norm(velocityKmPerSec);
end
