function analysis = energyConservationAnalysis(solution)
%ENERGYCONSERVATIONANALYSIS Evaluate two-body specific-energy conservation.
%   Position must be in km, velocity in km/s, and mu in km^3/s^2. Specific
%   energy is therefore reported in km^2/s^2 at every requested output time.

arguments
    solution (1,1) struct
end

requiredFields = ["time", "position", "velocity", "mu"];
for fieldName = requiredFields
    if ~isfield(solution, fieldName)
        error('energyConservationAnalysis:MissingField', ...
            'Solution field "%s" is required.', fieldName);
    end
end

if size(solution.position, 2) ~= 3 || size(solution.velocity, 2) ~= 3
    error('energyConservationAnalysis:InvalidStateHistory', ...
        'Position and velocity histories must each have three columns.');
end
if size(solution.position, 1) ~= numel(solution.time) || ...
        size(solution.velocity, 1) ~= numel(solution.time)
    error('energyConservationAnalysis:HistoryLengthMismatch', ...
        'Time, position, and velocity histories must have equal lengths.');
end

radiusKm = vecnorm(solution.position, 2, 2);
speedKmPerSec = vecnorm(solution.velocity, 2, 2);
specificEnergy = 0.5*speedKmPerSec.^2 - solution.mu./radiusKm;
initialEnergy = specificEnergy(1);
if initialEnergy == 0
    error('energyConservationAnalysis:ZeroEnergyScale', ...
        'Relative drift is undefined for a zero-energy parabolic state.');
end

signedDeviation = specificEnergy - initialEnergy;
absoluteDeviation = abs(signedDeviation);
relativeDeviation = absoluteDeviation/abs(initialEnergy);

analysis = struct();
analysis.timeSec = solution.time;
analysis.specificEnergyKm2PerSec2 = specificEnergy;
analysis.initialEnergyKm2PerSec2 = initialEnergy;
analysis.finalEnergyKm2PerSec2 = specificEnergy(end);
analysis.signedDeviationKm2PerSec2 = signedDeviation;
analysis.absoluteDeviationKm2PerSec2 = absoluteDeviation;
analysis.relativeDeviation = relativeDeviation;
analysis.maxAbsoluteDeviationKm2PerSec2 = max(absoluteDeviation);
analysis.maxRelativeDrift = max(relativeDeviation);
analysis.finalSignedDeviationKm2PerSec2 = signedDeviation(end);
analysis.finalRelativeDrift = relativeDeviation(end);
end
