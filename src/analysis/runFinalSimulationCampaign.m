function [runs,summary,representative] = runFinalSimulationCampaign(config)
%RUNFINALSIMULATIONCAMPAIGN Execute 120 deterministic two-body simulations.
%   The campaign spans five energy regimes, four eccentricities, and six
%   inclinations. A run passes only when ode45 returns finite states and
%   conserves the two-body invariants and analytical apsides within the
%   recorded tolerances.

altitudes = config.simulationAltitudesKm;
eccentricities = config.simulationEccentricities;
inclinations = config.simulationInclinationsDeg;
runCount = numel(altitudes)*numel(eccentricities)*numel(inclinations);

RunID = (1:runCount).';
SemimajorAxisKm = zeros(runCount,1);
Eccentricity = zeros(runCount,1);
InclinationDeg = zeros(runCount,1);
PeriodSeconds = zeros(runCount,1);
MaximumRelativeEnergyDrift = zeros(runCount,1);
MaximumRelativeAngularMomentumDrift = zeros(runCount,1);
PerigeeErrorKm = zeros(runCount,1);
ApogeeErrorKm = zeros(runCount,1);
FinalPositionClosureErrorKm = zeros(runCount,1);
RuntimeSeconds = zeros(runCount,1);
Passed = false(runCount,1);

representative = struct();
row = 0;
for altitude = altitudes
    for eccentricity = eccentricities
        for inclination = inclinations
            row = row+1;
            semimajorAxis = config.earthRadiusKm+altitude;
            elements = struct('aKm',semimajorAxis,'e',eccentricity, ...
                'iDeg',inclination,'raanDeg',mod(37*row,360), ...
                'argPeriapsisDeg',mod(19*row,360),'trueAnomalyDeg',0);
            [position0,velocity0] = orbitalElementsToState( ...
                elements,config.muEarthKm3PerSec2);
            period = 2*pi*sqrt(semimajorAxis^3/ ...
                config.muEarthKm3PerSec2);
            outputTimes = linspace(0,period, ...
                config.simulationSamplesPerOrbit).';
            timer = tic;
            solution = propagateTwoBody([position0;velocity0],outputTimes, ...
                config.muEarthKm3PerSec2, ...
                RelativeTolerance=config.relativeTolerance, ...
                AbsoluteTolerance=config.absoluteTolerance, ...
                MaximumStep=config.maximumStepSeconds);
            RuntimeSeconds(row) = toc(timer);
            diagnostics = orbitDiagnostics(solution);
            radius = diagnostics.radius;
            expectedPerigee = semimajorAxis*(1-eccentricity);
            expectedApogee = semimajorAxis*(1+eccentricity);
            perigeeError = abs(min(radius)-expectedPerigee);
            apogeeError = abs(max(radius)-expectedApogee);
            closureError = norm(solution.position(end,:)-solution.position(1,:));

            SemimajorAxisKm(row) = semimajorAxis;
            Eccentricity(row) = eccentricity;
            InclinationDeg(row) = inclination;
            PeriodSeconds(row) = period;
            MaximumRelativeEnergyDrift(row) = ...
                diagnostics.maxRelativeEnergyDrift;
            MaximumRelativeAngularMomentumDrift(row) = ...
                diagnostics.maxRelativeAngularMomentumDrift;
            PerigeeErrorKm(row) = perigeeError;
            ApogeeErrorKm(row) = apogeeError;
            FinalPositionClosureErrorKm(row) = closureError;
            Passed(row) = all(isfinite(solution.state),'all') && ...
                diagnostics.maxRelativeEnergyDrift <= ...
                    config.maximumRelativeEnergyDrift && ...
                diagnostics.maxRelativeAngularMomentumDrift <= ...
                    config.maximumRelativeAngularMomentumDrift && ...
                perigeeError <= config.maximumApsisErrorKm && ...
                apogeeError <= config.maximumApsisErrorKm;

            if row==1
                representative = struct('solution',solution, ...
                    'diagnostics',diagnostics,'elements',elements, ...
                    'periodSeconds',period);
            end
        end
    end
end

runs = table(RunID,SemimajorAxisKm,Eccentricity,InclinationDeg, ...
    PeriodSeconds,MaximumRelativeEnergyDrift, ...
    MaximumRelativeAngularMomentumDrift,PerigeeErrorKm,ApogeeErrorKm, ...
    FinalPositionClosureErrorKm,RuntimeSeconds,Passed);
summary = struct('totalRuns',height(runs), ...
    'successfulRuns',sum(runs.Passed),'failedRuns',sum(~runs.Passed), ...
    'maximumRelativeEnergyDrift',max(runs.MaximumRelativeEnergyDrift), ...
    'maximumRelativeAngularMomentumDrift', ...
        max(runs.MaximumRelativeAngularMomentumDrift), ...
    'maximumPerigeeErrorKm',max(runs.PerigeeErrorKm), ...
    'maximumApogeeErrorKm',max(runs.ApogeeErrorKm), ...
    'totalRuntimeSeconds',sum(runs.RuntimeSeconds));
end
