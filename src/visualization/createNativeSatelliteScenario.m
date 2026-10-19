function [scenario, satellites] = createNativeSatelliteScenario(tleFile, options)
%CREATENATIVESATELLITESCENARIO Build a native, movable 3-D SGP4 scenario.

arguments
    tleFile (1,1) string
    options.StartTimeUtc (1,1) datetime = datetime('now','TimeZone','UTC')
    options.DurationHours (1,1) double {mustBePositive,mustBeFinite} = 12
    options.StepSeconds (1,1) double {mustBePositive,mustBeFinite} = 60
end

if ~isfile(tleFile)
    error('createNativeSatelliteScenario:MissingTleFile', ...
        'TLE file does not exist: %s',tleFile);
end
if isempty(options.StartTimeUtc.TimeZone)
    error('createNativeSatelliteScenario:TimeZoneRequired', ...
        'StartTimeUtc must include an explicit time zone.');
end
startTimeUtc = options.StartTimeUtc;
startTimeUtc.TimeZone = 'UTC';
stopTimeUtc = startTimeUtc + hours(options.DurationHours);

scenario = satelliteScenario(startTimeUtc,stopTimeUtc,options.StepSeconds, ...
    'AutoSimulate',false);
satellites = satellite(scenario,tleFile);
colors = lines(numel(satellites));
for index = 1:numel(satellites)
    color = colors(index,:);
    satellites(index).MarkerColor = color;
    satellites(index).MarkerSize = 8;
    satellites(index).ShowLabel = true;
    satellites(index).LabelFontSize = 12;
    satellites(index).LabelFontColor = color;
    satellites(index).Orbit.LineColor = color;
    satellites(index).Orbit.LineWidth = 1.5;
    satellites(index).GroundTrack.LeadLineColor = color;
    satellites(index).GroundTrack.TrailLineColor = color;
    satellites(index).GroundTrack.LineWidth = 1.5;
end
end
