function analytical = circularOrbitAnalytical(mu, orbitalRadius)
%CIRCULARORBITANALYTICAL Calculate exact circular-orbit quantities.
%   MU is in km^3/s^2 and ORBITALRADIUS is in km.

arguments
    mu (1,1) double {mustBePositive, mustBeFinite}
    orbitalRadius (1,1) double {mustBePositive, mustBeFinite}
end

analytical = struct();
analytical.radius = orbitalRadius;
analytical.speed = sqrt(mu / orbitalRadius);
analytical.period = 2*pi*sqrt(orbitalRadius^3 / mu);
analytical.specificEnergy = -mu / (2*orbitalRadius);
analytical.specificAngularMomentum = sqrt(mu*orbitalRadius);
end

