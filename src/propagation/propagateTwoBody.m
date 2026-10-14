function solution = propagateTwoBody(initialState, outputTimes, mu, options)
%PROPAGATETWOBODY Propagate a Cartesian orbit with MATLAB ode45.
%   SOLUTION = PROPAGATETWOBODY(STATE0, TIMES, MU) numerically integrates the
%   Newtonian two-body equations at the requested output times.
%
%   Name-value options:
%     RelativeTolerance  Relative local-error tolerance (default 1e-11)
%     AbsoluteTolerance  Absolute local-error tolerance (default 1e-12)
%     MaximumStep        Maximum internal step in seconds (default Inf)

arguments
    initialState (6,1) double {mustBeFinite}
    outputTimes (:,1) double {mustBeFinite, mustBeNonnegative}
    mu (1,1) double {mustBePositive, mustBeFinite}
    options.RelativeTolerance (1,1) double {mustBePositive} = 1e-11
    options.AbsoluteTolerance (1,1) double {mustBePositive} = 1e-12
    options.MaximumStep (1,1) double {mustBePositive} = Inf
end

if numel(outputTimes) < 2 || any(diff(outputTimes) <= 0)
    error('propagateTwoBody:InvalidTimes', ...
        'outputTimes must contain at least two strictly increasing values.');
end

solverOptions = odeset( ...
    'RelTol', options.RelativeTolerance, ...
    'AbsTol', options.AbsoluteTolerance, ...
    'MaxStep', options.MaximumStep);

[time, state] = ode45(@(t, y) twoBodyEOM(t, y, mu), ...
    outputTimes, initialState, solverOptions);

solution = struct();
solution.time = time;
solution.state = state;
solution.position = state(:, 1:3);
solution.velocity = state(:, 4:6);
solution.mu = mu;
solution.solver = 'ode45';
solution.relativeTolerance = options.RelativeTolerance;
solution.absoluteTolerance = options.AbsoluteTolerance;
solution.maximumStep = options.MaximumStep;
end

