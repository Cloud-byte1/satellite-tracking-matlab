function stateDerivative = twoBodyEOM(time, state, mu)
%TWOBODYEOM Newtonian point-mass equations of orbital motion.
%   DSTATE = TWOBODYEOM(T, STATE, MU) accepts the six-element Cartesian
%   state STATE = [x; y; z; vx; vy; vz] and returns its time derivative.
%
%   Position is in km, velocity in km/s, and MU in km^3/s^2. The output is
%   therefore [km/s; km/s^2]. Time is unused because this model is autonomous.

arguments
    time (1,1) double {mustBeFinite} %#ok<INUSA>
    state (6,1) double {mustBeFinite}
    mu (1,1) double {mustBePositive, mustBeFinite}
end

position = state(1:3);
velocity = state(4:6);
radius = norm(position);

if radius == 0
    error('twoBodyEOM:ZeroRadius', ...
        'The two-body acceleration is undefined at zero radius.');
end

acceleration = -(mu / radius^3) * position;
stateDerivative = [velocity; acceleration];
end

