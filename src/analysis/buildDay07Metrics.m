function metrics = buildDay07Metrics(comparison,catalog,horizonsHours,earthRadiusKm)
%BUILDDAY07METRICS Build one engineering summary row per satellite/horizon.

arguments
    comparison (1,1) struct
    catalog (:,:) table
    horizonsHours (1,:) double {mustBePositive,mustBeFinite}
    earthRadiusKm (1,1) double {mustBePositive,mustBeFinite}
end

satelliteCount = height(catalog);
rowCount = satelliteCount*numel(horizonsHours);
SatelliteName = strings(rowCount,1); NORADCatalogID = zeros(rowCount,1);
Regime = strings(rowCount,1); HorizonHours = zeros(rowCount,1);
ElementEpochUtc = NaT(rowCount,1,'TimeZone','UTC');
StartTimeUtc = NaT(rowCount,1,'TimeZone','UTC');
InitialAltitudeKm = zeros(rowCount,1); InclinationDeg = zeros(rowCount,1);
Eccentricity = zeros(rowCount,1); FinalSgp4XKm = zeros(rowCount,1);
FinalSgp4YKm = zeros(rowCount,1); FinalSgp4ZKm = zeros(rowCount,1);
FinalTwoBodyXKm = zeros(rowCount,1); FinalTwoBodyYKm = zeros(rowCount,1);
FinalTwoBodyZKm = zeros(rowCount,1); FinalPositionSeparationKm = zeros(rowCount,1);
MaximumPositionSeparationKm = zeros(rowCount,1); RmsPositionSeparationKm = zeros(rowCount,1);
FinalVelocityDifferenceKmPerSec = zeros(rowCount,1);
FinalRadialKm = zeros(rowCount,1); FinalAlongTrackKm = zeros(rowCount,1);
FinalCrossTrackKm = zeros(rowCount,1); MaximumAbsRadialKm = zeros(rowCount,1);
MaximumAbsAlongTrackKm = zeros(rowCount,1); MaximumAbsCrossTrackKm = zeros(rowCount,1);

row = 0;
for satellite = 1:satelliteCount
    initialRadius = norm(comparison.positionSgp4J2000Km(1,:,satellite));
    for horizon = horizonsHours
        row = row+1;
        index = find(comparison.elapsedSeconds <= horizon*3600+1e-9,1,'last');
        range = 1:index;
        separation = comparison.positionSeparationKm(range,satellite);
        rtn = comparison.rtnDifferenceKm(range,:,satellite);
        rSgp4 = comparison.positionSgp4J2000Km(index,:,satellite);
        rTwoBody = comparison.positionTwoBodyJ2000Km(index,:,satellite);
        SatelliteName(row) = catalog.SatelliteName(satellite);
        NORADCatalogID(row) = catalog.NORADCatalogID(satellite);
        Regime(row) = catalog.Regime(satellite);
        HorizonHours(row) = horizon;
        ElementEpochUtc(row) = catalog.ElementEpochUtc(satellite);
        StartTimeUtc(row) = comparison.startTimeUtc;
        InitialAltitudeKm(row) = initialRadius-earthRadiusKm;
        InclinationDeg(row) = catalog.InclinationDeg(satellite);
        Eccentricity(row) = catalog.Eccentricity(satellite);
        FinalSgp4XKm(row) = rSgp4(1); FinalSgp4YKm(row) = rSgp4(2);
        FinalSgp4ZKm(row) = rSgp4(3); FinalTwoBodyXKm(row) = rTwoBody(1);
        FinalTwoBodyYKm(row) = rTwoBody(2); FinalTwoBodyZKm(row) = rTwoBody(3);
        FinalPositionSeparationKm(row) = separation(end);
        MaximumPositionSeparationKm(row) = max(separation);
        RmsPositionSeparationKm(row) = sqrt(mean(separation.^2));
        FinalVelocityDifferenceKmPerSec(row) = ...
            comparison.velocityDifferenceKmPerSec(index,satellite);
        FinalRadialKm(row) = rtn(end,1); FinalAlongTrackKm(row) = rtn(end,2);
        FinalCrossTrackKm(row) = rtn(end,3);
        MaximumAbsRadialKm(row) = max(abs(rtn(:,1)));
        MaximumAbsAlongTrackKm(row) = max(abs(rtn(:,2)));
        MaximumAbsCrossTrackKm(row) = max(abs(rtn(:,3)));
    end
end

metrics = table(SatelliteName,NORADCatalogID,Regime,HorizonHours, ...
    ElementEpochUtc,StartTimeUtc,InitialAltitudeKm,InclinationDeg, ...
    Eccentricity,FinalSgp4XKm,FinalSgp4YKm,FinalSgp4ZKm, ...
    FinalTwoBodyXKm,FinalTwoBodyYKm,FinalTwoBodyZKm, ...
    FinalPositionSeparationKm,MaximumPositionSeparationKm, ...
    RmsPositionSeparationKm,FinalVelocityDifferenceKmPerSec, ...
    FinalRadialKm,FinalAlongTrackKm,FinalCrossTrackKm, ...
    MaximumAbsRadialKm,MaximumAbsAlongTrackKm,MaximumAbsCrossTrackKm);
end
