function panel = createSatelliteObservationPanel(scenario,satellites,options)
%CREATESATELLITEOBSERVATIONPANEL Live state readout for a native globe.
%   The panel follows scenario.SimulationTime while the user plays or scrubs
%   MATLAB's satelliteScenario viewer. Selecting a satellite reports its
%   inertial position, velocity, altitude, and speed at that exact UTC time.

arguments
    scenario
    satellites
    options.EarthRadiusKm (1,1) double {mustBePositive,mustBeFinite} = 6378.137
    options.UpdatePeriodSeconds (1,1) double {mustBePositive,mustBeFinite} = 0.20
end

count = numel(satellites);
if count == 0
    error('createSatelliteObservationPanel:NoSatellites', ...
        'At least one satellite is required.');
end

names = strings(count,1);
for index = 1:count
    names(index) = string(satellites(index).Name);
end

panelFigure = uifigure('Name','Satellite Time & Position', ...
    'Position',[90 90 470 510]);
layout = uigridlayout(panelFigure,[7 1]);
layout.RowHeight = {32,22,36,28,28,'1x',34};
layout.Padding = [14 12 14 12];

uilabel(layout,'Text','Observe a satellite', ...
    'FontSize',17,'FontWeight','bold');
uilabel(layout, ...
    'Text','Play or scrub the globe timeline; this state follows it live.', ...
    'FontColor',[0.35 0.35 0.35]);
satelliteDropDown = uidropdown(layout,'Items',cellstr(names), ...
    'Value',char(names(1)),'ValueChangedFcn',@(~,~) updateReadout());
timeLabel = uilabel(layout,'Text','Time:','FontWeight','bold');
statusLabel = uilabel(layout,'Text','Simulation:');
readout = uitextarea(layout,'Editable','off','FontName','Consolas', ...
    'FontSize',12,'BackgroundColor',[0.96 0.98 1]);
refreshButton = uibutton(layout,'Text','Refresh position now', ...
    'ButtonPushedFcn',@(~,~) updateReadout());

pollTimer = timer('ExecutionMode','fixedSpacing', ...
    'Period',options.UpdatePeriodSeconds,'BusyMode','drop', ...
    'TimerFcn',@(~,~) updateReadout());
panelFigure.CloseRequestFcn = @closePanel;
start(pollTimer);
updateReadout();

panel = struct('Figure',panelFigure,'SatelliteDropDown',satelliteDropDown, ...
    'TimeLabel',timeLabel,'StatusLabel',statusLabel,'Readout',readout, ...
    'RefreshButton',refreshButton,'Timer',pollTimer,'Refresh',@updateReadout);

    function updateReadout()
        if ~isvalid(panelFigure)
            return
        end
        selectedIndex = find(names == string(satelliteDropDown.Value),1);
        timestamp = scenario.SimulationTime;
        timestamp.TimeZone = 'UTC';
        [positionMeters,velocityMetersPerSecond] = states( ...
            satellites(selectedIndex),timestamp,'CoordinateFrame','inertial');
        geographicPosition = states(satellites(selectedIndex),timestamp, ...
            'CoordinateFrame','geographic');
        positionKm = positionMeters(:).'/1000;
        velocityKmPerSec = velocityMetersPerSecond(:).'/1000;
        latitudeDeg = geographicPosition(1);
        longitudeDeg = geographicPosition(2);
        altitudeKm = geographicPosition(3)/1000;
        speedKmPerSec = norm(velocityKmPerSec);
        timeLabel.Text = "Time: "+string(timestamp,"yyyy-MM-dd HH:mm:ss 'UTC'");
        statusLabel.Text = "Simulation: "+string(scenario.SimulationStatus);
        readout.Value = splitlines(sprintf([ ...
            '%s\n\nGEODETIC POSITION\n' ...
            'Latitude   %+12.6f deg\nLongitude  %+12.6f deg\n' ...
            'Altitude   %12.3f km\n\nPOSITION - INERTIAL (km)\n' ...
            'X  %+14.3f\nY  %+14.3f\nZ  %+14.3f\n\n' ...
            'Speed     %12.6f km/s\n\n' ...
            'VELOCITY - INERTIAL (km/s)\n' ...
            'X  %+12.6f\nY  %+12.6f\nZ  %+12.6f'], ...
            names(selectedIndex),latitudeDeg,longitudeDeg,altitudeKm, ...
            positionKm(1),positionKm(2),positionKm(3), ...
            speedKmPerSec,velocityKmPerSec(1), ...
            velocityKmPerSec(2),velocityKmPerSec(3)));
    end

    function closePanel(~,~)
        if isvalid(pollTimer)
            stop(pollTimer);
            delete(pollTimer);
        end
        delete(panelFigure);
    end
end
