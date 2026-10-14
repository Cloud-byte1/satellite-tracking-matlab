function constants = earthConstants()
%EARTHCONSTANTS Return Earth constants used by the Day 1 model.
%   Values use a consistent kilometre-second unit system.
%
%   Source conventions:
%     muEarth       WGS 84 conventional gravitational parameter
%     radiusEarth   WGS 84 equatorial radius

constants = struct();
constants.muEarth = 398600.4418;      % km^3/s^2
constants.radiusEarth = 6378.137;     % km
constants.secondsPerDay = 86400;      % s/day
constants.unitSystem = 'km-s';
constants.referenceFrame = 'Earth-centered inertial (ECI)';
end

