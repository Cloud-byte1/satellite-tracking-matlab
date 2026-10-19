function elements = stateToOrbitalElements(positionEciKm, velocityEciKmPerSec, mu)
%STATETOORBITALELEMENTS Recover classical elements from an ECI state.
%   Angles are returned in degrees on [0,360), except inclination on [0,180].
%   Circular/equatorial singularities use conventional zero angles; nonsingular
%   Day 3 verification cases are used when comparing all six angles.

arguments
    positionEciKm (3,1) double {mustBeFinite}
    velocityEciKmPerSec (3,1) double {mustBeFinite}
    mu (1,1) double {mustBePositive, mustBeFinite}
end

radius = norm(positionEciKm);
speed = norm(velocityEciKmPerSec);
if radius == 0
    error('stateToOrbitalElements:ZeroRadius', ...
        'Orbital elements are undefined at zero geocentric radius.');
end

angularMomentum = cross(positionEciKm, velocityEciKmPerSec);
h = norm(angularMomentum);
if h == 0
    error('stateToOrbitalElements:RadialState', ...
        'Classical orbital elements are undefined for a radial state.');
end

nodeVector = cross([0; 0; 1], angularMomentum);
nodeMagnitude = norm(nodeVector);
eccentricityVector = cross(velocityEciKmPerSec, angularMomentum)/mu ...
    - positionEciKm/radius;
eccentricity = norm(eccentricityVector);
specificEnergy = 0.5*speed^2 - mu/radius;
if specificEnergy >= 0
    error('stateToOrbitalElements:NonEllipticState', ...
        'The supplied state is not a bound elliptic orbit.');
end

elements = struct();
elements.aKm = -mu/(2*specificEnergy);
elements.e = eccentricity;
elements.iDeg = acosd(clamp(angularMomentum(3)/h));

singularityTolerance = 1e-12;
if nodeMagnitude > singularityTolerance
    elements.raanDeg = wrap360(atan2d(nodeVector(2), nodeVector(1)));
else
    elements.raanDeg = 0;
end

if eccentricity > singularityTolerance && nodeMagnitude > singularityTolerance
    sinArgument = dot(cross(nodeVector, eccentricityVector), angularMomentum) ...
        /(nodeMagnitude*eccentricity*h);
    cosArgument = dot(nodeVector, eccentricityVector) ...
        /(nodeMagnitude*eccentricity);
    elements.argPeriapsisDeg = wrap360(atan2d(sinArgument, cosArgument));
elseif eccentricity > singularityTolerance
    elements.argPeriapsisDeg = wrap360(atan2d( ...
        eccentricityVector(2), eccentricityVector(1)));
else
    elements.argPeriapsisDeg = 0;
end

if eccentricity > singularityTolerance
    sinAnomaly = dot(cross(eccentricityVector, positionEciKm), angularMomentum) ...
        /(eccentricity*radius*h);
    cosAnomaly = dot(eccentricityVector, positionEciKm)/(eccentricity*radius);
    elements.trueAnomalyDeg = wrap360(atan2d(sinAnomaly, cosAnomaly));
elseif nodeMagnitude > singularityTolerance
    sinArgumentLatitude = dot(cross(nodeVector, positionEciKm), angularMomentum) ...
        /(nodeMagnitude*radius*h);
    cosArgumentLatitude = dot(nodeVector, positionEciKm)/(nodeMagnitude*radius);
    elements.trueAnomalyDeg = wrap360( ...
        atan2d(sinArgumentLatitude, cosArgumentLatitude));
else
    elements.trueAnomalyDeg = wrap360( ...
        atan2d(positionEciKm(2), positionEciKm(1)));
end

elements.specificEnergyKm2PerSec2 = specificEnergy;
elements.specificAngularMomentumKm2PerSec = h;
elements.eccentricityVector = eccentricityVector;
end

function value = clamp(value)
value = min(1, max(-1, value));
end

function angle = wrap360(angle)
angle = mod(angle, 360);
if abs(angle - 360) < 1e-12 || abs(angle) < 1e-12
    angle = 0;
end
end
