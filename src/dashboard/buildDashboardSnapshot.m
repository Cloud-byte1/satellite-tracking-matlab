function snapshot = buildDashboardSnapshot(comparison,catalog,timingSummary, ...
    satelliteIndex,horizonHours)
%BUILDDASHBOARDSNAPSHOT Build one validated real-satellite dashboard record.

arguments
    comparison (1,1) struct
    catalog (:,:) table
    timingSummary (:,:) table
    satelliteIndex (1,1) double {mustBeInteger,mustBePositive}
    horizonHours (1,1) double {mustBeMember(horizonHours,[1 6 24])}
end
if satelliteIndex>height(catalog)
    error('buildDashboardSnapshot:SatelliteIndexOutOfRange', ...
        'Satellite index %d exceeds the %d catalog entries.', ...
        satelliteIndex,height(catalog));
end
[timeError,index] = min(abs(comparison.elapsedSeconds-horizonHours*3600));
if timeError>comparison.stepSeconds/2
    error('buildDashboardSnapshot:UnavailableHorizon', ...
        'The requested horizon is not present on the propagated timeline.');
end
name = string(catalog.SatelliteName(satelliteIndex));
timingIndex = find(string(timingSummary.ScenarioName)==name,1);
if isempty(timingIndex)
    error('buildDashboardSnapshot:MissingTimingRecord', ...
        'No relativistic timing record matches %s.',name);
end

snapshot = struct();
snapshot.SatelliteName = name;
snapshot.NORADCatalogID = catalog.NORADCatalogID(satelliteIndex);
snapshot.Regime = string(catalog.Regime(satelliteIndex));
snapshot.HorizonHours = horizonHours;
snapshot.PredictionTimeUtc = comparison.timeUtc(index);
snapshot.Sgp4PositionJ2000Km = ...
    reshape(comparison.positionSgp4J2000Km(index,:,satelliteIndex),1,3);
snapshot.Sgp4VelocityJ2000KmPerSec = ...
    reshape(comparison.velocitySgp4J2000KmPerSec(index,:,satelliteIndex),1,3);
snapshot.TwoBodyPositionJ2000Km = ...
    reshape(comparison.positionTwoBodyJ2000Km(index,:,satelliteIndex),1,3);
snapshot.TwoBodyVelocityJ2000KmPerSec = ...
    reshape(comparison.velocityTwoBodyJ2000KmPerSec(index,:,satelliteIndex),1,3);
snapshot.PositionSeparationKm = ...
    comparison.positionSeparationKm(index,satelliteIndex);
snapshot.RtnSeparationKm = ...
    reshape(comparison.rtnDifferenceKm(index,:,satelliteIndex),1,3);
snapshot.GravitationalMicrosecondsPerDay = ...
    timingSummary.GravitationalMicrosecondsPerDay(timingIndex);
snapshot.KinematicMicrosecondsPerDay = ...
    timingSummary.KinematicMicrosecondsPerDay(timingIndex);
snapshot.NetMicrosecondsPerDay = ...
    timingSummary.NetMicrosecondsPerDay(timingIndex);
snapshot.ReferenceFrame = string(comparison.referenceFrame);
snapshot.DifferenceConvention = string(comparison.differenceConvention);
end
