function timeSeries = buildDay07TimeSeries(comparison,catalog)
%BUILDDAY07TIMESERIES Flatten all trajectory differences for CSV export.

sampleCount = numel(comparison.timeUtc);
satelliteCount = height(catalog);
rows = sampleCount*satelliteCount;
SatelliteName = strings(rows,1); NORADCatalogID = zeros(rows,1);
Regime = strings(rows,1); TimeUtc = NaT(rows,1,'TimeZone','UTC');
ElapsedHours = zeros(rows,1); PositionSeparationKm = zeros(rows,1);
VelocityDifferenceKmPerSec = zeros(rows,1); RadialKm = zeros(rows,1);
AlongTrackKm = zeros(rows,1); CrossTrackKm = zeros(rows,1);
for satellite = 1:satelliteCount
    range = (satellite-1)*sampleCount+(1:sampleCount);
    SatelliteName(range) = catalog.SatelliteName(satellite);
    NORADCatalogID(range) = catalog.NORADCatalogID(satellite);
    Regime(range) = catalog.Regime(satellite);
    TimeUtc(range) = comparison.timeUtc;
    ElapsedHours(range) = comparison.elapsedSeconds/3600;
    PositionSeparationKm(range) = comparison.positionSeparationKm(:,satellite);
    VelocityDifferenceKmPerSec(range) = ...
        comparison.velocityDifferenceKmPerSec(:,satellite);
    RadialKm(range) = comparison.rtnDifferenceKm(:,1,satellite);
    AlongTrackKm(range) = comparison.rtnDifferenceKm(:,2,satellite);
    CrossTrackKm(range) = comparison.rtnDifferenceKm(:,3,satellite);
end
timeSeries = table(SatelliteName,NORADCatalogID,Regime,TimeUtc, ...
    ElapsedHours,PositionSeparationKm,VelocityDifferenceKmPerSec, ...
    RadialKm,AlongTrackKm,CrossTrackKm);
end
