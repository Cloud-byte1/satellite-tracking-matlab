function app = launchSatelliteObserver(options)
%LAUNCHSATELLITEOBSERVER Start the complete application from the project root.
%   Double-click "Satellite Observer.cmd" or call this function from MATLAB.

arguments
    options.Visible (1,1) logical = true
end

projectRoot = string(fileparts(mfilename('fullpath')));
requiredFiles = [ ...
    fullfile(projectRoot,"results","day07_sgp4_two_body_comparison.mat"); ...
    fullfile(projectRoot,"results","day09_general_relativity.mat")];
missing = requiredFiles(~isfile(requiredFiles));
if ~isempty(missing)
    error('launchSatelliteObserver:MissingApplicationData', ...
        'Required application data is missing: %s',strjoin(missing,', '));
end

addpath(projectRoot);
setupProject();
addpath(fullfile(projectRoot,'apps'));
addpath(fullfile(projectRoot,'scripts'));

splash = gobjects(0);
if options.Visible
    splash = createSplash();
end
try
    app = SatelliteTrackingDashboard(Visible=options.Visible);
catch exception
    closeSplash(splash);
    if options.Visible
        errordlg(getReport(exception,'basic','hyperlinks','off'), ...
            'Satellite Observer could not start','modal');
    end
    rethrow(exception);
end
closeSplash(splash);

setappdata(app.Figure,'SatelliteObserverApplication',app);
if options.Visible
    figure(app.Figure);
end
end

function splash = createSplash()
splash = uifigure('Name','Satellite Observer','Position',[100 100 460 190], ...
    'Resize','off','WindowStyle','alwaysontop','Color',[0.93 0.96 0.98]);
movegui(splash,'center');
layout = uigridlayout(splash,[3 1]);
layout.RowHeight = {62,40,'1x'};
titleLabel = uilabel(layout,'Text','SATELLITE OBSERVER', ...
    'FontSize',24,'FontWeight','bold','FontColor',[0.09 0.25 0.38], ...
    'HorizontalAlignment','center');
titleLabel.Layout.Row = 1;
statusLabel = uilabel(layout, ...
    'Text','Loading live SGP4 observation and engineering tools...', ...
    'FontSize',12,'HorizontalAlignment','center', ...
    'FontColor',[0.12 0.42 0.53]);
statusLabel.Layout.Row = 2;
detailLabel = uilabel(layout, ...
    'Text','ISS | GPS | NOAA-20 | Landsat 9 | GOES-16', ...
    'FontSize',10,'HorizontalAlignment','center', ...
    'FontColor',[0.35 0.40 0.44]);
detailLabel.Layout.Row = 3;
drawnow;
end

function closeSplash(splash)
if ~isempty(splash) && isvalid(splash)
    delete(splash);
end
end
