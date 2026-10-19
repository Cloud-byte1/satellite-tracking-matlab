function [positionEciKm, velocityEciKmPerSec] = orbitalElementsToState(elements, mu)
%ORBITALELEMENTSTOSTATE Convert classical orbital elements to an ECI state.
%   [R,V] = ORBITALELEMENTSTOSTATE(ELEMENTS,MU) accepts a scalar structure
%   with fields aKm, e, iDeg, raanDeg, argPeriapsisDeg, and trueAnomalyDeg.
%   R is returned in km and V in km/s. MU must be in km^3/s^2.
%
%   The conversion first constructs the state in the perifocal (PQW) frame,
%   then applies R3(RAAN)*R1(inclination)*R3(argument of periapsis).

arguments
    elements (1,1) struct
    mu (1,1) double {mustBePositive, mustBeFinite}
end

requiredFields = ["aKm", "e", "iDeg", "raanDeg", ...
    "argPeriapsisDeg", "trueAnomalyDeg"];
for fieldName = requiredFields
    if ~isfield(elements, fieldName)
        error('orbitalElementsToState:MissingField', ...
            'Required element field "%s" is missing.', fieldName);
    end
    value = elements.(fieldName);
    if ~(isnumeric(value) && isreal(value) && isscalar(value) && isfinite(value))
        error('orbitalElementsToState:InvalidField', ...
            'Element field "%s" must be a finite real scalar.', fieldName);
    end
end

if elements.aKm <= 0
    error('orbitalElementsToState:InvalidSemimajorAxis', ...
        'aKm must be positive for an elliptic orbit.');
end
if elements.e < 0 || elements.e >= 1
    error('orbitalElementsToState:InvalidEccentricity', ...
        'This function requires 0 <= e < 1 for an elliptic orbit.');
end
if elements.iDeg < 0 || elements.iDeg > 180
    error('orbitalElementsToState:InvalidInclination', ...
        'iDeg must lie in the closed interval [0, 180].');
end

inclination = deg2rad(elements.iDeg);
raan = deg2rad(elements.raanDeg);
argumentOfPeriapsis = deg2rad(elements.argPeriapsisDeg);
trueAnomaly = deg2rad(elements.trueAnomalyDeg);

parameterKm = elements.aKm*(1 - elements.e^2);
radiusKm = parameterKm/(1 + elements.e*cos(trueAnomaly));
positionPqw = radiusKm*[cos(trueAnomaly); sin(trueAnomaly); 0];
velocityPqw = sqrt(mu/parameterKm)* ...
    [-sin(trueAnomaly); elements.e + cos(trueAnomaly); 0];

rotation = rotationZ(raan)*rotationX(inclination)*rotationZ(argumentOfPeriapsis);
positionEciKm = rotation*positionPqw;
velocityEciKmPerSec = rotation*velocityPqw;
end

function matrix = rotationZ(angle)
matrix = [cos(angle), -sin(angle), 0; ...
          sin(angle),  cos(angle), 0; ...
                   0,           0, 1];
end

function matrix = rotationX(angle)
matrix = [1,          0,           0; ...
          0, cos(angle), -sin(angle); ...
          0, sin(angle),  cos(angle)];
end
