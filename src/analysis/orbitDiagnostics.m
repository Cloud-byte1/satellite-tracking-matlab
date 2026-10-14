function diagnostics = orbitDiagnostics(solution)
%ORBITDIAGNOSTICS Evaluate conserved quantities and numerical drift.

position = solution.position;
velocity = solution.velocity;
mu = solution.mu;

radius = vecnorm(position, 2, 2);
speed = vecnorm(velocity, 2, 2);
specificEnergy = 0.5*speed.^2 - mu./radius;
specificAngularMomentumVector = cross(position, velocity, 2);
specificAngularMomentum = vecnorm(specificAngularMomentumVector, 2, 2);

energyScale = abs(specificEnergy(1));
angularMomentumScale = abs(specificAngularMomentum(1));

diagnostics = struct();
diagnostics.radius = radius;
diagnostics.speed = speed;
diagnostics.specificEnergy = specificEnergy;
diagnostics.specificAngularMomentumVector = specificAngularMomentumVector;
diagnostics.specificAngularMomentum = specificAngularMomentum;
diagnostics.maxRadiusDeviationKm = max(abs(radius - radius(1)));
diagnostics.maxRelativeEnergyDrift = ...
    max(abs(specificEnergy - specificEnergy(1))) / energyScale;
diagnostics.maxRelativeAngularMomentumDrift = ...
    max(abs(specificAngularMomentum - specificAngularMomentum(1))) / ...
    angularMomentumScale;
end

