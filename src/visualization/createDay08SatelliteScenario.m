function [scenario,satellites] = createDay08SatelliteScenario(analysis,startTimeUtc,options)
%CREATEDAY08SATELLITESCENARIO Visualize the exact Day 8 state histories.
%   The Day 8 histories are supplied as ephemerides so the native viewer
%   animates the same six real and three theoretical cases used by the
%   special-relativistic clock analysis.

arguments
    analysis (1,1) struct
    startTimeUtc (1,1) datetime
    options.StepSeconds (1,1) double {mustBePositive,mustBeFinite} = 60
end

if isempty(startTimeUtc.TimeZone)
    error('createDay08SatelliteScenario:TimeZoneRequired', ...
        'startTimeUtc must include an explicit time zone.');
end
startTimeUtc.TimeZone = 'UTC';
histories = analysis.histories;
if isempty(histories)
    error('createDay08SatelliteScenario:NoHistories', ...
        'The Day 8 analysis contains no state histories.');
end

elapsedSeconds = histories(1).elapsedSeconds(:);
stopTimeUtc = startTimeUtc+seconds(elapsedSeconds(end));
scenario = satelliteScenario(startTimeUtc,stopTimeUtc,options.StepSeconds, ...
    'AutoSimulate',false);

count = numel(histories);
colors = [lines(analysis.realSatelliteCount); ...
    0.95 0.35 0.10; 0.55 0.20 0.85; 0.10 0.75 0.55];
for index = 1:count
    history = histories(index);
    sampleTimes = startTimeUtc+seconds(history.elapsedSeconds(:));
    position = timetable(sampleTimes,history.positionKm*1000, ...
        'VariableNames',{'Position'});
    velocity = timetable(sampleTimes,history.velocityKmPerSec*1000, ...
        'VariableNames',{'Velocity'});
    currentSatellite = satellite(scenario,position,velocity, ...
        'CoordinateFrame','inertial','Name',history.name);
    if index == 1
        satellites = currentSatellite;
    else
        satellites(index) = currentSatellite;
    end

    color = colors(index,:);
    currentSatellite.MarkerColor = color;
    currentSatellite.MarkerSize = 9;
    currentSatellite.ShowLabel = true;
    currentSatellite.LabelFontSize = 11;
    currentSatellite.LabelFontColor = color;
    currentSatellite.Orbit.LineColor = color;
    currentSatellite.Orbit.LineWidth = 1.5;
    currentSatellite.GroundTrack.LeadLineColor = color;
    currentSatellite.GroundTrack.TrailLineColor = color;
    currentSatellite.GroundTrack.LineWidth = 1.25;
end
end
