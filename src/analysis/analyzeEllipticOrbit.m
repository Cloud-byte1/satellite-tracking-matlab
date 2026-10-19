function analysis = analyzeEllipticOrbit(scenario, solution, earthRadiusKm)
%ANALYZEELLIPTICORBIT Compare numerical and analytical orbit properties.

arguments
    scenario (1,1) struct
    solution (1,1) struct
    earthRadiusKm (1,1) double {mustBePositive, mustBeFinite}
end

mu = solution.mu;
a = scenario.aKm;
e = scenario.e;
perigeeRadius = a*(1 - e);
apogeeRadius = a*(1 + e);
period = 2*pi*sqrt(a^3/mu);
perigeeSpeed = sqrt(mu*(2/perigeeRadius - 1/a));
apogeeSpeed = sqrt(mu*(2/apogeeRadius - 1/a));
diagnostics = orbitDiagnostics(solution);
recovered = stateToOrbitalElements( ...
    solution.position(1,:).', solution.velocity(1,:).', mu);

analysis = struct();
analysis.periodSec = period;
analysis.perigeeAltitudeKm = perigeeRadius - earthRadiusKm;
analysis.apogeeAltitudeKm = apogeeRadius - earthRadiusKm;
analysis.minimumSpeedKmPerSec = apogeeSpeed;
analysis.maximumSpeedKmPerSec = perigeeSpeed;
analysis.specificEnergyKm2PerSec2 = -mu/(2*a);
analysis.specificAngularMomentumKm2PerSec = sqrt(mu*a*(1 - e^2));
analysis.eccentricityFromState = recovered.e;
analysis.numericalPerigeeAltitudeKm = min(diagnostics.radius) - earthRadiusKm;
analysis.numericalApogeeAltitudeKm = max(diagnostics.radius) - earthRadiusKm;
analysis.numericalMinimumSpeedKmPerSec = min(diagnostics.speed);
analysis.numericalMaximumSpeedKmPerSec = max(diagnostics.speed);
analysis.maxRelativeEnergyDrift = diagnostics.maxRelativeEnergyDrift;
analysis.maxRelativeAngularMomentumDrift = ...
    diagnostics.maxRelativeAngularMomentumDrift;
analysis.positionClosureErrorKm = norm( ...
    solution.position(end,:) - solution.position(1,:));
analysis.velocityClosureErrorKmPerSec = norm( ...
    solution.velocity(end,:) - solution.velocity(1,:));
end
