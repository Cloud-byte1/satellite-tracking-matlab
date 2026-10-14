function outputs = run_day01_circular_orbit(options)
%RUN_DAY01_CIRCULAR_ORBIT Execute and verify the complete Day 1 simulation.
%   This function requires base MATLAB only. It saves machine-readable results,
%   verification results, and two figures in the repository output folders.

arguments
    options.GenerateFigures (1,1) logical = true
    options.GeneratePngFigures (1,1) logical = false
end

scriptDirectory = fileparts(mfilename('fullpath'));
projectRoot = fileparts(scriptDirectory);
addpath(projectRoot)
setupProject();
addpath(fullfile(projectRoot, 'tests'));

constants = earthConstants();
altitudeKm = 500.0;
orbitalRadiusKm = constants.radiusEarth + altitudeKm;
analytical = circularOrbitAnalytical(constants.muEarth, orbitalRadiusKm);

% Choose an equatorial circular orbit. Position and velocity are perpendicular,
% and the velocity magnitude is exactly the circular-orbit analytical value.
initialState = [orbitalRadiusKm; 0; 0; 0; analytical.speed; 0];
outputTimes = linspace(0, analytical.period, 1001).';

solution = propagateTwoBody(initialState, outputTimes, constants.muEarth, ...
    RelativeTolerance=1e-11, AbsoluteTolerance=1e-12, ...
    MaximumStep=analytical.period/200);
diagnostics = orbitDiagnostics(solution);
verification = runDay01Tests(solution, analytical, diagnostics);

figuresDirectory = fullfile(projectRoot, 'figures');
resultsDirectory = fullfile(projectRoot, 'results');

if options.GenerateFigures
    writeOrbitSvg2D(solution.position, constants.radiusEarth, ...
        fullfile(figuresDirectory, 'day01_orbit_2d.svg'));
    writeOrbitSvg3D(solution.position, constants.radiusEarth, ...
        fullfile(figuresDirectory, 'day01_orbit_3d.svg'));
end

% Optional raster export uses MATLAB's graphics backend. Vector SVG output above
% is the reliable default for headless and automated execution environments.
if options.GeneratePngFigures
    previousVisibility = get(groot, 'defaultFigureVisible');
    visibilityCleanup = onCleanup(@() set(groot, ...
        'defaultFigureVisible', previousVisibility));
    set(groot, 'defaultFigureVisible', 'off');

    figure2D = plotOrbit2D(solution.position, constants.radiusEarth);
    print(figure2D, fullfile(figuresDirectory, 'day01_orbit_2d.png'), ...
        '-dpng', '-r200');
    close(figure2D)
    figure3D = plotOrbit3D(solution.position, constants.radiusEarth);
    print(figure3D, fullfile(figuresDirectory, 'day01_orbit_3d.png'), ...
        '-dpng', '-r200');
    close(figure3D)
end

summary = table(altitudeKm, orbitalRadiusKm, analytical.speed, ...
    analytical.period, analytical.period/60, analytical.specificEnergy, ...
    diagnostics.maxRelativeEnergyDrift, ...
    diagnostics.maxRelativeAngularMomentumDrift, ...
    diagnostics.maxRadiusDeviationKm, verification.positionClosureErrorKm, ...
    verification.convergencePositionErrorKm, verification.passedTests, ...
    verification.totalTests, ...
    'VariableNames', {'AltitudeKm', 'OrbitalRadiusKm', ...
    'CircularSpeedKmPerSec', 'OrbitalPeriodSec', 'OrbitalPeriodMin', ...
    'SpecificEnergyKm2PerSec2', 'MaxRelativeEnergyDrift', ...
    'MaxRelativeAngularMomentumDrift', 'MaxRadiusDeviationKm', ...
    'PositionClosureErrorKm', 'ConvergencePositionErrorKm', ...
    'TestsPassed', 'TestsRun'});

writetable(summary, fullfile(resultsDirectory, 'day01_summary.csv'));
writetable(verification.results, ...
    fullfile(resultsDirectory, 'day01_verification.csv'));
save(fullfile(resultsDirectory, 'day01_simulation.mat'), ...
    'constants', 'altitudeKm', 'initialState', 'analytical', ...
    'solution', 'diagnostics', 'verification', 'summary');

fprintf('\nDAY 1: 500 km CIRCULAR ORBIT\n');
fprintf('Circular velocity:          %.9f km/s\n', analytical.speed);
fprintf('Orbital period:             %.6f s (%.6f min)\n', ...
    analytical.period, analytical.period/60);
fprintf('Specific orbital energy:    %.9f km^2/s^2\n', ...
    analytical.specificEnergy);
fprintf('Maximum relative E drift:   %.3e\n', ...
    diagnostics.maxRelativeEnergyDrift);
fprintf('Position closure error:     %.3e km\n', ...
    verification.positionClosureErrorKm);
fprintf('Convergence position error: %.3e km\n', ...
    verification.convergencePositionErrorKm);
fprintf('Verification tests:         %d/%d passed\n\n', ...
    verification.passedTests, verification.totalTests);

outputs = struct('summary', summary, 'solution', solution, ...
    'diagnostics', diagnostics, 'verification', verification);
end

