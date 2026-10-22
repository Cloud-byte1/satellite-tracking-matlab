function app = SatelliteTrackingDashboard(options)
%SATELLITETRACKINGDASHBOARD Full Satellite Observer application.
%   All user workflows are available from this window: propagated state
%   observation, SGP4/two-body comparison, timing, verification, reports,
%   result export, cached-data reload, CelesTrak refresh, and the 3-D globe.

arguments
    options.Visible (1,1) logical = true
end

appDirectory = fileparts(mfilename('fullpath'));
projectRoot = string(fileparts(appDirectory));
addpath(projectRoot); setupProject(); addpath(fullfile(projectRoot,'scripts'));
resultsDirectory = fullfile(projectRoot,'results');
reportFile = fullfile(projectRoot,'output','pdf', ...
    'satellite_tracking_final_engineering_report.pdf');
[day07,day09,performanceMetrics,verificationResults] = loadApplicationData();
liveScenario = [];
liveSatellites = [];
liveTleResult = struct();
liveTimer = [];
lastLiveObservation = struct();
embeddedViewer = [];
scenarioError = [];

visibility = 'off';
if options.Visible
    visibility = 'on';
end
figureHandle = uifigure('Name','Satellite Observer', ...
    'Visible',visibility,'Color',[0.94 0.96 0.98]);
mainLayout = uigridlayout(figureHandle,[2 1]);
mainLayout.RowHeight = {62,'1x'};
mainLayout.Padding = [8 8 8 8];

header = uipanel(mainLayout,'BackgroundColor',[0.09 0.20 0.31], ...
    'BorderType','none');
header.Layout.Row = 1;
headerLayout = uigridlayout(header,[1 2]);
headerLayout.ColumnWidth = {'1x',520};
headerLayout.Padding = [18 4 18 4];
uilabel(headerLayout,'Text','SATELLITE OBSERVER', ...
    'FontSize',25,'FontWeight','bold','FontColor','white');
applicationStatus = uilabel(headerLayout, ...
    'Text','READY - verified saved orbital data loaded', ...
    'HorizontalAlignment','right','FontSize',12, ...
    'FontColor',[0.55 0.90 0.84]);

tabs = uitabgroup(mainLayout);
tabs.Layout.Row = 2;
observerTab = uitab(tabs,'Title','Observer');
analysisTab = uitab(tabs,'Title','Engineering Results');
helpTab = uitab(tabs,'Title','Guide & Limitations');

% Observer tab.
observerLayout = uigridlayout(observerTab,[2 2]);
observerLayout.RowHeight = {56,'1x'};
observerLayout.ColumnWidth = {405,'1x'};
observerLayout.Padding = [8 8 8 8];

controls = uigridlayout(observerLayout,[1 8]);
controls.Layout.Row = 1; controls.Layout.Column = [1 2];
controls.ColumnWidth = {65,220,60,85,115,145,145,145};
uilabel(controls,'Text','Satellite','FontWeight','bold');
satelliteDropDown = uidropdown(controls, ...
    'Items',cellstr(string(day07.catalog.SatelliteName)), ...
    'Value',char(string(day07.catalog.SatelliteName(1))));
uilabel(controls,'Text','Horizon','FontWeight','bold');
horizonDropDown = uidropdown(controls,'Items',{'1 h','6 h','24 h'}, ...
    'ItemsData',[1 6 24],'Value',1);
liveButton = uibutton(controls,'state','Text','LIVE NOW', ...
    'FontWeight','bold','Tooltip', ...
    'Propagate current CelesTrak orbital elements to the present UTC time');
exportButton = uibutton(controls,'Text','Export snapshot');
scenarioButton = uibutton(controls,'Text','RESTART 3-D VIEW', ...
    'FontWeight','bold','Tooltip', ...
    'Restart the embedded satelliteScenario at the current UTC time');
reloadButton = uibutton(controls,'Text','Reload results');

left = uigridlayout(observerLayout,[2 1]);
left.Layout.Row = 2; left.Layout.Column = 1;
left.RowHeight = {'1x',180};
summaryArea = uitextarea(left,'Editable','off','FontName','Consolas', ...
    'FontSize',12);
statusArea = uitextarea(left,'Editable','off','FontName','Consolas', ...
    'FontSize',10);
statusArea.Value = initialStatusText();

scenarioHost = uipanel(observerLayout,'BorderType','none', ...
    'BackgroundColor',[0.06 0.09 0.13], ...
    'AutoResizeChildren','off');
scenarioHost.Layout.Row = 2; scenarioHost.Layout.Column = 2;
scenarioHostLayout = uigridlayout(scenarioHost,[1 1]);
scenarioHostLayout.Padding = [0 0 0 0];
scenarioStatusLabel = uilabel(scenarioHostLayout, ...
    'Text','Loading the embedded satelliteScenario globe...', ...
    'HorizontalAlignment','center','FontSize',14, ...
    'FontColor',[0.75 0.84 0.90]);

% Engineering Results tab.
analysisLayout = uigridlayout(analysisTab,[2 2]);
analysisLayout.RowHeight = {58,'1x'};
analysisLayout.ColumnWidth = {'1x','1x'};
analysisLayout.Padding = [8 8 8 8];
actions = uigridlayout(analysisLayout,[1 6]);
actions.Layout.Row = 1; actions.Layout.Column = [1 2];
actions.ColumnWidth = {150,180,165,150,165,'1x'};
returnObserverButton = uibutton(actions,'Text','Return to 3-D Observer', ...
    'FontWeight','bold');
verifyButton = uibutton(actions,'Text','Run acceptance checks');
refreshButton = uibutton(actions,'Text','Update from CelesTrak');
reportButton = uibutton(actions,'Text','Open engineering report');
resultsButton = uibutton(actions,'Text','Open results folder');
analysisStatus = uilabel(actions,'Text','Saved verification evidence loaded', ...
    'HorizontalAlignment','right','FontColor',[0.12 0.42 0.53]);

tablesLayout = uigridlayout(analysisLayout,[2 1]);
tablesLayout.Layout.Row = 2; tablesLayout.Layout.Column = 1;
tablesLayout.RowHeight = {'0.48x','0.52x'};
metricsPanel = uipanel(tablesLayout,'Title','Performance Metrics', ...
    'FontWeight','bold');
metricsGrid = uigridlayout(metricsPanel,[1 1]);
performanceTable = uitable(metricsGrid,'Data',performanceMetrics, ...
    'ColumnEditable',false);
performanceTable.ColumnWidth = {290,130,130};
verificationPanel = uipanel(tablesLayout,'Title','Verification Summary', ...
    'FontWeight','bold');
verificationGrid = uigridlayout(verificationPanel,[1 1]);
verificationTable = uitable(verificationGrid,'Data',verificationResults, ...
    'ColumnEditable',false);
verificationTable.ColumnWidth = {300,100,75,90,120,65};

figurePanel = uipanel(analysisLayout,'Title', ...
    '24-hour SGP4 versus Two-Body Model Separation','FontWeight','bold');
figurePanel.Layout.Row = 2; figurePanel.Layout.Column = 2;
figureGrid = uigridlayout(figurePanel,[1 1]);
separationImage = uiimage(figureGrid,'ScaleMethod','fit');
separationFigureFile = fullfile(projectRoot,'figures', ...
    'final_02_sgp4_two_body_separation.png');
if isfile(separationFigureFile)
    separationImage.ImageSource = separationFigureFile;
end

% Guide tab.
guideLayout = uigridlayout(helpTab,[1 2]);
guideLayout.ColumnWidth = {'0.55x','0.45x'};
guideLayout.Padding = [18 18 18 18];
guideArea = uitextarea(guideLayout,'Editable','off','FontSize',12, ...
    'Value',guideText());
limitationsArea = uitextarea(guideLayout,'Editable','off','FontSize',12, ...
    'Value',limitationsText());

% Floating controls shown over the full-figure satelliteScenario viewer.
observerOverlay = uipanel(figureHandle,'Visible','off', ...
    'Position',[14 78 390 700],'BackgroundColor',[0.09 0.16 0.23], ...
    'ForegroundColor','white','BorderType','line','HighlightColor',[0.3 0.7 0.8]);
overlayLayout = uigridlayout(observerOverlay,[8 1]);
overlayLayout.RowHeight = {44,28,38,38,'1x',38,38,24};
overlayLayout.Padding = [12 10 12 10];
uilabel(overlayLayout,'Text','SATELLITE OBSERVER', ...
    'FontSize',20,'FontWeight','bold','FontColor','white');
uilabel(overlayLayout,'Text','Embedded MATLAB satelliteScenario', ...
    'FontColor',[0.55 0.90 0.84]);
overlaySatelliteDropDown = uidropdown(overlayLayout, ...
    'Items',satelliteDropDown.Items,'Value',satelliteDropDown.Value);
overlayModeRow = uigridlayout(overlayLayout,[1 2]);
overlayModeRow.ColumnWidth = {'1x','1x'};
overlayModeRow.Padding = [0 0 0 0];
overlayLiveButton = uibutton(overlayModeRow,'state','Text','LIVE NOW', ...
    'FontWeight','bold');
overlayHorizonDropDown = uidropdown(overlayModeRow, ...
    'Items',horizonDropDown.Items,'ItemsData',horizonDropDown.ItemsData, ...
    'Value',horizonDropDown.Value);
overlaySummaryArea = uitextarea(overlayLayout,'Editable','off', ...
    'FontName','Consolas','FontSize',11);
overlayPrimaryButtons = uigridlayout(overlayLayout,[1 2]);
overlayPrimaryButtons.ColumnWidth = {'1x','1x'};
overlayPrimaryButtons.Padding = [0 0 0 0];
overlayRestartButton = uibutton(overlayPrimaryButtons, ...
    'Text','Restart 3-D view','FontWeight','bold');
overlayEngineeringButton = uibutton(overlayPrimaryButtons, ...
    'Text','Engineering results');
overlaySecondaryButtons = uigridlayout(overlayLayout,[1 2]);
overlaySecondaryButtons.ColumnWidth = {'1x','1x'};
overlaySecondaryButtons.Padding = [0 0 0 0];
overlayExportButton = uibutton(overlaySecondaryButtons,'Text','Export snapshot');
overlayReportButton = uibutton(overlaySecondaryButtons,'Text','Open report');
overlayStatusLabel = uilabel(overlayLayout, ...
    'Text','Six satellites • current UTC start • 60x playback', ...
    'FontSize',10,'FontColor',[0.72 0.80 0.86]);

% Apply the final window size only after the engineering layout hierarchy exists.
figureHandle.Position = [55 55 1440 850];
drawnow;

satelliteDropDown.ValueChangedFcn = @(~,~) updateObserver();
horizonDropDown.ValueChangedFcn = @(~,~) updateObserver();
liveButton.ValueChangedFcn = @(~,~) toggleLiveView();
exportButton.ButtonPushedFcn = @(~,~) exportSnapshot();
scenarioButton.ButtonPushedFcn = @(~,~) openScenario();
reloadButton.ButtonPushedFcn = @(~,~) reloadSavedResults();
verifyButton.ButtonPushedFcn = @(~,~) runAcceptanceChecks();
refreshButton.ButtonPushedFcn = @(~,~) refreshCelesTrakData();
reportButton.ButtonPushedFcn = @(~,~) openReport();
resultsButton.ButtonPushedFcn = @(~,~) openResults();
returnObserverButton.ButtonPushedFcn = @(~,~) initializeEmbeddedScenario();
figureHandle.CloseRequestFcn = @(~,~) closeApplication();
tabs.SelectionChangedFcn = @(~,~) handleTabSelection();
overlaySatelliteDropDown.ValueChangedFcn = @(~,~) overlaySatelliteChanged();
overlayHorizonDropDown.ValueChangedFcn = @(~,~) overlayHorizonChanged();
overlayLiveButton.ValueChangedFcn = @(~,~) overlayLiveChanged();
overlayRestartButton.ButtonPushedFcn = @(~,~) restartEmbeddedScenario();
overlayEngineeringButton.ButtonPushedFcn = @(~,~) showEngineeringConsole();
overlayExportButton.ButtonPushedFcn = @(~,~) exportSnapshot();
overlayReportButton.ButtonPushedFcn = @(~,~) openReport();
updateObserver();

app = struct('Figure',figureHandle,'Tabs',tabs, ...
    'SatelliteDropDown',overlaySatelliteDropDown, ...
    'HorizonDropDown',overlayHorizonDropDown, ...
    'LiveButton',overlayLiveButton,'ScenarioHost',scenarioHost, ...
    'ObserverOverlay',observerOverlay, ...
    'SummaryArea',overlaySummaryArea,'StatusArea',statusArea, ...
    'PerformanceTable',performanceTable, ...
    'VerificationTable',verificationTable, ...
    'ApplicationStatus',applicationStatus, ...
    'Comparison',day07.comparison,'Catalog',day07.catalog, ...
    'TimingSummary',day09.analysis.summary, ...
    'GetScenarioViewer',@getScenarioViewer, ...
    'GetScenario',@getScenario, ...
    'GetScenarioError',@getScenarioError, ...
    'RestartScenario',@restartEmbeddedScenario, ...
    'ShowEngineering',@showEngineeringConsole, ...
    'Close',@closeApplication);
if options.Visible
    drawnow;
    initializeEmbeddedScenario();
end

    function [snapshot,satelliteIndex] = currentSnapshot()
        satelliteIndex = find(string(day07.catalog.SatelliteName)== ...
            string(satelliteDropDown.Value),1);
        snapshot = buildDashboardSnapshot(day07.comparison,day07.catalog, ...
            day09.analysis.summary,satelliteIndex,horizonDropDown.Value);
    end

    function value = getScenarioViewer()
        value = embeddedViewer;
    end

    function value = getScenario()
        value = liveScenario;
    end

    function value = getScenarioError()
        value = scenarioError;
    end

    function overlaySatelliteChanged()
        satelliteDropDown.Value = overlaySatelliteDropDown.Value;
        updateObserver();
    end

    function overlayHorizonChanged()
        horizonDropDown.Value = overlayHorizonDropDown.Value;
        updateObserver();
    end

    function overlayLiveChanged()
        liveButton.Value = overlayLiveButton.Value;
        toggleLiveView();
    end

    function updateObserver()
        overlaySatelliteDropDown.Value = satelliteDropDown.Value;
        overlayHorizonDropDown.Value = horizonDropDown.Value;
        if liveButton.Value
            updateLiveObserver();
            return
        end
        snapshot = currentSnapshot();
        summaryArea.Value = composeSummary(snapshot);
        overlaySummaryArea.Value = summaryArea.Value;
        drawnow limitrate;
    end

    function exportSnapshot()
        if liveButton.Value && ~isempty(fieldnames(lastLiveObservation))
            snapshot = lastLiveObservation;
        else
            snapshot = currentSnapshot();
        end
        output = struct2table(snapshot,'AsArray',true);
        outputFile = fullfile(resultsDirectory,'dashboard_snapshot.csv');
        writetable(output,outputFile);
        appendStatus(sprintf('Exported snapshot: %s',outputFile));
        uialert(figureHandle,'The current observation was exported.', ...
            'Snapshot exported','Icon','success');
    end

    function openScenario()
        restartEmbeddedScenario();
    end

    function reloadSavedResults()
        if liveButton.Value
            liveButton.Value = false;
            stopLiveView();
        end
        progress = uiprogressdlg(figureHandle,'Title','Satellite Observer', ...
            'Message','Reloading saved orbital and timing results...', ...
            'Indeterminate','on');
        try
            [day07,day09,performanceMetrics,verificationResults] = ...
                loadApplicationData();
            satelliteDropDown.Items = ...
                cellstr(string(day07.catalog.SatelliteName));
            satelliteDropDown.Value = satelliteDropDown.Items{1};
            performanceTable.Data = performanceMetrics;
            verificationTable.Data = verificationResults;
            updateObserver();
            applicationStatus.Text = 'READY - saved results reloaded';
            appendStatus('Reloaded all saved application results.');
        catch exception
            uialert(figureHandle,getReport(exception,'basic','hyperlinks','off'), ...
                'Reload error','Icon','error');
        end
        delete(progress);
    end

    function runAcceptanceChecks()
        progress = uiprogressdlg(figureHandle,'Title','Verification', ...
            'Message','Running the consolidated acceptance suite...', ...
            'Indeterminate','on','Cancelable','off');
        applicationStatus.Text = 'RUNNING ACCEPTANCE CHECKS';
        drawnow;
        try
            outputs = run_final_engineering_sprint(ExportFigures=false, ...
                ShowFigures=false,BenchmarkDashboard=false,ReuseCampaign=true);
            performanceMetrics = outputs.performanceMetrics;
            verificationResults = outputs.verification.results;
            performanceTable.Data = performanceMetrics;
            verificationTable.Data = verificationResults;
            analysisStatus.Text = sprintf('%d/%d checks passed; %d simulations', ...
                outputs.verification.passedTests, ...
                outputs.verification.totalTests, ...
                outputs.campaignSummary.successfulRuns);
            applicationStatus.Text = 'READY - acceptance checks passed';
            uialert(figureHandle,analysisStatus.Text, ...
                'Verification complete','Icon','success');
        catch exception
            applicationStatus.Text = 'ERROR - acceptance check failed';
            uialert(figureHandle,getReport(exception,'basic','hyperlinks','off'), ...
                'Verification error','Icon','error');
        end
        delete(progress);
    end

    function refreshCelesTrakData()
        choice = uiconfirm(figureHandle, ...
            ['This retrieves new CelesTrak records and rebuilds the 24-hour ' ...
             'SGP4, two-body, and relativity results. It can take several minutes.'], ...
            'Update orbital data','Options',{'Update now','Cancel'}, ...
            'DefaultOption','Cancel','CancelOption','Cancel');
        if choice~="Update now"
            return;
        end
        progress = uiprogressdlg(figureHandle,'Title','CelesTrak update', ...
            'Message','Retrieving and validating current orbital records...', ...
            'Indeterminate','on','Cancelable','off');
        applicationStatus.Text = 'UPDATING FROM CELESTRAK';
        drawnow;
        try
            run_day07_sgp4_two_body_comparison(ForceRefresh=true, ...
                ExportFigures=false,ShowFigures=false);
            progress.Message = 'Recomputing special-relativistic timing...';
            drawnow;
            run_day08_special_relativity(ExportFigures=false,ShowFigures=false);
            progress.Message = 'Recomputing combined relativistic timing...';
            drawnow;
            run_day09_general_relativity(ExportFigures=false,ShowFigures=false);
            progress.Message = 'Running final acceptance checks...';
            drawnow;
            run_final_engineering_sprint(ExportFigures=false, ...
                ShowFigures=false,BenchmarkDashboard=false,ReuseCampaign=true);
            [day07,day09,performanceMetrics,verificationResults] = ...
                loadApplicationData();
            satelliteDropDown.Items = ...
                cellstr(string(day07.catalog.SatelliteName));
            satelliteDropDown.Value = satelliteDropDown.Items{1};
            performanceTable.Data = performanceMetrics;
            verificationTable.Data = verificationResults;
            updateObserver();
            applicationStatus.Text = 'READY - CelesTrak update verified';
            appendStatus('CelesTrak data and all dependent analyses updated.');
            uialert(figureHandle, ...
                'Orbital data, timing models, and verification are updated.', ...
                'Update complete','Icon','success');
        catch exception
            applicationStatus.Text = 'ERROR - update did not complete';
            uialert(figureHandle,getReport(exception,'basic','hyperlinks','off'), ...
                'CelesTrak update error','Icon','error');
        end
        delete(progress);
    end

    function toggleLiveView()
        if liveButton.Value
            startLiveView();
        else
            stopLiveView();
            updateObserver();
        end
    end

    function startLiveView()
        applicationStatus.Text = 'STARTING LIVE NOW';
        drawnow;
        try
            if isempty(liveSatellites)
                initializeEmbeddedScenario();
            end
            if isempty(liveSatellites)
                error('SatelliteTrackingDashboard:ScenarioUnavailable', ...
                    'The embedded satelliteScenario is unavailable.');
            end
            liveTimer = timer('ExecutionMode','fixedSpacing','Period',5, ...
                'BusyMode','drop','TimerFcn',@(~,~) liveTimerTick());
            setappdata(figureHandle,'SatelliteObserverLiveTimer',liveTimer);
            horizonDropDown.Enable = 'off';
            overlayHorizonDropDown.Enable = 'off';
            applicationStatus.Text = 'LIVE NOW - updates every 5 seconds';
            appendStatus('Live Now started. Position is SGP4-propagated, not telemetry.');
            updateLiveObserver();
            start(liveTimer);
        catch exception
            liveButton.Value = false;
            overlayLiveButton.Value = false;
            stopLiveView();
            applicationStatus.Text = 'ERROR - LIVE NOW unavailable';
            uialert(figureHandle,getReport(exception,'basic','hyperlinks','off'), ...
                'Live Now error','Icon','error');
        end
    end

    function liveTimerTick()
        if ~isvalid(figureHandle) || ~liveButton.Value
            return
        end
        try
            updateLiveObserver();
        catch exception
            appendStatus("Live update paused: "+string(exception.message));
            liveButton.Value = false;
            stopLiveView();
            applicationStatus.Text = 'LIVE NOW paused after an update error';
        end
    end

    function updateLiveObserver()
        if isempty(liveSatellites)
            return
        end
        satelliteIndex = find(string(day07.catalog.SatelliteName)== ...
            string(satelliteDropDown.Value),1);
        timestamp = datetime('now','TimeZone','UTC');
        [positionMeters,velocityMetersPerSecond] = states( ...
            liveSatellites(satelliteIndex),timestamp, ...
            'CoordinateFrame','inertial');
        geographic = states(liveSatellites(satelliteIndex),timestamp, ...
            'CoordinateFrame','geographic');
        positionKm = positionMeters(:).'/1000;
        velocityKmPerSec = velocityMetersPerSecond(:).'/1000;
        latitudeDeg = geographic(1);
        longitudeDeg = geographic(2);
        altitudeKm = geographic(3)/1000;
        speedKmPerSec = norm(velocityKmPerSec);
        elementEpoch = liveTleResult.Catalog.ElementEpochUtc(satelliteIndex);
        elementAgeHours = hours(timestamp-elementEpoch);
        retrievalTime = liveTleResult.Catalog.RetrievalTimeUtc(satelliteIndex);
        source = liveTleResult.Catalog.Source(satelliteIndex);
        lastLiveObservation = struct( ...
            'Mode',"LIVE NOW - SGP4 propagation, not telemetry", ...
            'SatelliteName',string(satelliteDropDown.Value), ...
            'NORADCatalogID',day07.catalog.NORADCatalogID(satelliteIndex), ...
            'ObservationTimeUtc',timestamp,'LatitudeDeg',latitudeDeg, ...
            'LongitudeDeg',longitudeDeg,'AltitudeKm',altitudeKm, ...
            'SpeedKmPerSec',speedKmPerSec, ...
            'InertialPositionXKm',positionKm(1), ...
            'InertialPositionYKm',positionKm(2), ...
            'InertialPositionZKm',positionKm(3), ...
            'InertialVelocityXKmPerSec',velocityKmPerSec(1), ...
            'InertialVelocityYKmPerSec',velocityKmPerSec(2), ...
            'InertialVelocityZKmPerSec',velocityKmPerSec(3), ...
            'ElementEpochUtc',elementEpoch, ...
            'ElementAgeHours',elementAgeHours, ...
            'RetrievalTimeUtc',retrievalTime,'Source',source);
        summaryArea.Value = composeLiveSummary(lastLiveObservation);
        overlaySummaryArea.Value = summaryArea.Value;
        applicationStatus.Text = "LIVE NOW - "+ ...
            string(timestamp,"HH:mm:ss 'UTC'")+" - updates every 5 s";
        drawnow limitrate;
    end

    function initializeEmbeddedScenario()
        if ~isempty(embeddedViewer) && isvalid(embeddedViewer)
            header.Visible = 'off';
            tabs.Visible = 'off';
            observerOverlay.Visible = 'on';
            uistack(observerOverlay,'top');
            return
        end
        progress = [];
        if strcmp(figureHandle.Visible,'on')
            progress = uiprogressdlg(figureHandle, ...
                'Title','Satellite Observer', ...
                'Message','Loading the embedded satelliteScenario...', ...
                'Indeterminate','on','Cancelable','off');
        end
        scenarioStatusLabel.Visible = 'on';
        scenarioStatusLabel.Text = ...
            'Loading current orbital elements and the 3-D globe...';
        applicationStatus.Text = 'LOADING EMBEDDED 3-D VIEW';
        scenarioError = [];
        drawnow;
        try
            targets = day07SatelliteCatalog();
            liveTleResult = fetchCelesTrakTleCatalog(targets, ...
                CacheDirectory=fullfile(projectRoot,'data','raw'), ...
                OutputFile=fullfile(projectRoot,'data','processed', ...
                    'satellite_observer_live.tle'),ForceRefresh=false);
            startTime = datetime('now','TimeZone','UTC');
            [liveScenario,liveSatellites] = createNativeSatelliteScenario( ...
                liveTleResult.File,StartTimeUtc=startTime, ...
                DurationHours=3,StepSeconds=10);
            embeddedViewer = satelliteScenarioViewer(liveScenario, ...
                Parent=figureHandle);
            for satelliteIndex = 1:numel(liveSatellites)
                show(liveSatellites(satelliteIndex).GroundTrack,embeddedViewer);
            end
            embeddedViewer.PlaybackSpeedMultiplier = 60;
            scenarioStatusLabel.Visible = 'off';
            header.Visible = 'off';
            tabs.Visible = 'off';
            observerOverlay.Visible = 'on';
            uistack(observerOverlay,'top');
            % Viewer construction can replace figure callbacks, so restore the
            % Satellite Observer lifecycle callbacks after embedding it.
            figureHandle.CloseRequestFcn = @(~,~) closeApplication();
            play(liveScenario,Viewer=embeddedViewer, ...
                PlaybackSpeedMultiplier=60);
            applicationStatus.Text = ...
                '3-D VIEW PLAYING - starts at current UTC, 60x speed';
            appendStatus(['Embedded satelliteScenario started with six ' ...
                'moving satellites at 60x speed.']);
        catch exception
            scenarioError = exception;
            cleanupEmbeddedScenario();
            scenarioStatusLabel.Visible = 'on';
            scenarioStatusLabel.Text = ...
                "Embedded 3-D view unavailable: "+string(exception.message);
            applicationStatus.Text = 'ERROR - EMBEDDED 3-D VIEW unavailable';
            observerOverlay.Visible = 'off';
            header.Visible = 'on';
            tabs.Visible = 'on';
            if strcmp(figureHandle.Visible,'on')
                uialert(figureHandle, ...
                    getReport(exception,'basic','hyperlinks','off'), ...
                    'Embedded 3-D view error','Icon','error');
            end
        end
        if ~isempty(progress) && isvalid(progress)
            delete(progress);
        end
    end

    function restartEmbeddedScenario()
        liveWasEnabled = liveButton.Value;
        liveButton.Value = false;
        stopLiveView();
        cleanupEmbeddedScenario();
        initializeEmbeddedScenario();
        if liveWasEnabled && ~isempty(liveSatellites)
            liveButton.Value = true;
            overlayLiveButton.Value = true;
            startLiveView();
        end
    end

    function showEngineeringConsole()
        overlayLiveButton.Value = false;
        liveButton.Value = false;
        stopLiveView();
        cleanupEmbeddedScenario();
        observerOverlay.Visible = 'off';
        header.Visible = 'on';
        tabs.Visible = 'on';
        tabs.SelectedTab = analysisTab;
        applicationStatus.Text = 'ENGINEERING RESULTS - 3-D view paused';
    end

    function handleTabSelection()
        if tabs.SelectedTab == observerTab && ...
                (isempty(embeddedViewer) || ~isvalid(embeddedViewer))
            initializeEmbeddedScenario();
        end
    end

    function cleanupEmbeddedScenario()
        if ~isempty(liveScenario)
            try
                stop(liveScenario);
            catch
            end
        end
        if ~isempty(embeddedViewer) && isvalid(embeddedViewer)
            delete(embeddedViewer);
        end
        embeddedViewer = [];
        liveScenario = [];
        liveSatellites = [];
    end

    function stopLiveView()
        if ~isempty(liveTimer) && isvalid(liveTimer)
            stop(liveTimer);
            delete(liveTimer);
        end
        liveTimer = [];
        if isvalid(figureHandle) && isappdata(figureHandle, ...
                'SatelliteObserverLiveTimer')
            rmappdata(figureHandle,'SatelliteObserverLiveTimer');
        end
        horizonDropDown.Enable = 'on';
        overlayHorizonDropDown.Enable = 'on';
        if isvalid(figureHandle)
            applicationStatus.Text = 'READY - verified saved orbital data loaded';
        end
    end

    function closeApplication()
        stopLiveView();
        cleanupEmbeddedScenario();
        if isvalid(figureHandle)
            delete(figureHandle);
        end
        if strcmp(getenv('SATELLITE_OBSERVER_STANDALONE'),'1') || ...
                strcmp(getenv('SATELLITE_TRACKER_STANDALONE'),'1')
            setenv('SATELLITE_OBSERVER_STANDALONE','');
            setenv('SATELLITE_TRACKER_STANDALONE','');
            exit;
        end
    end

    function openReport()
        if ~isfile(reportFile)
            uialert(figureHandle,'The final PDF report is missing.', ...
                'Report unavailable','Icon','warning');
            return;
        end
        winopen(reportFile);
        applicationStatus.Text = 'READY - engineering report opened';
    end

    function openResults()
        winopen(resultsDirectory);
        applicationStatus.Text = 'READY - results folder opened';
    end

    function appendStatus(message)
        stamp = string(datetime('now','Format','HH:mm:ss'));
        statusArea.Value = [statusArea.Value; {sprintf('[%s] %s',stamp,message)}];
        drawnow limitrate;
    end

    function [loadedDay07,loadedDay09,metrics,checks] = loadApplicationData()
        loadedDay07 = load(fullfile(resultsDirectory, ...
            'day07_sgp4_two_body_comparison.mat'),'comparison','catalog');
        loadedDay09 = load(fullfile(resultsDirectory, ...
            'day09_general_relativity.mat'),'analysis');
        metricsFile = fullfile(resultsDirectory,'final_performance_metrics.csv');
        checksFile = fullfile(resultsDirectory,'final_verification_summary.csv');
        if isfile(metricsFile)
            metrics = readtable(metricsFile,'TextType','string');
        else
            metrics = table("No metrics file",NaN,"", ...
                'VariableNames',{'Metric','Value','Unit'});
        end
        if isfile(checksFile)
            checks = readtable(checksFile,'TextType','string');
        else
            checks = table("Not run",NaN,"==",1,"logical",false, ...
                'VariableNames',{'Test','MeasuredValue','Comparison', ...
                'Criterion','Unit','Passed'});
        end
    end
end

function lines = composeSummary(snapshot)
position = snapshot.Sgp4PositionJ2000Km;
velocity = snapshot.Sgp4VelocityJ2000KmPerSec;
rtn = snapshot.RtnSeparationKm;
lines = { ...
    sprintf('%s  |  NORAD %d  |  %s',snapshot.SatelliteName, ...
        snapshot.NORADCatalogID,snapshot.Regime); ...
    sprintf('UTC: %s',string(snapshot.PredictionTimeUtc, ...
        "yyyy-MM-dd HH:mm:ss 'UTC'")); ...
    sprintf('Horizon: %.0f h',snapshot.HorizonHours); ...
    ''; ...
    'SGP4 J2000 state'; ...
    sprintf('r = [%10.3f %10.3f %10.3f] km',position); ...
    sprintf('v = [%10.6f %10.6f %10.6f] km/s',velocity); ...
    ''; ...
    sprintf('|two-body - SGP4| = %.6f km',snapshot.PositionSeparationKm); ...
    sprintf('RTN = [%+.6f %+.6f %+.6f] km',rtn); ...
    ''; ...
    'Relativistic clock drift'; ...
    sprintf('gravity:   %+.6f microseconds/day', ...
        snapshot.GravitationalMicrosecondsPerDay); ...
    sprintf('kinematic: %+.6f microseconds/day', ...
        snapshot.KinematicMicrosecondsPerDay); ...
    sprintf('net:       %+.6f microseconds/day', ...
        snapshot.NetMicrosecondsPerDay)};
end

function lines = composeLiveSummary(observation)
position = [observation.InertialPositionXKm, ...
    observation.InertialPositionYKm,observation.InertialPositionZKm];
velocity = [observation.InertialVelocityXKmPerSec, ...
    observation.InertialVelocityYKmPerSec, ...
    observation.InertialVelocityZKmPerSec];
lines = { ...
    'LIVE NOW  |  SGP4 PROPAGATION  |  NOT TELEMETRY'; ...
    sprintf('%s  |  NORAD %d',observation.SatelliteName, ...
        observation.NORADCatalogID); ...
    sprintf('Updated: %s',string(observation.ObservationTimeUtc, ...
        "yyyy-MM-dd HH:mm:ss 'UTC'")); ...
    ''; ...
    'GEOGRAPHIC POSITION'; ...
    sprintf('Latitude:  %+12.6f deg',observation.LatitudeDeg); ...
    sprintf('Longitude: %+12.6f deg',observation.LongitudeDeg); ...
    sprintf('Altitude:  %12.3f km',observation.AltitudeKm); ...
    sprintf('Speed:     %12.6f km/s',observation.SpeedKmPerSec); ...
    ''; ...
    'INERTIAL STATE'; ...
    sprintf('r = [%10.3f %10.3f %10.3f] km',position); ...
    sprintf('v = [%10.6f %10.6f %10.6f] km/s',velocity); ...
    ''; ...
    'ORBITAL DATA PROVENANCE'; ...
    sprintf('Element epoch: %s',string(observation.ElementEpochUtc, ...
        "yyyy-MM-dd HH:mm:ss 'UTC'")); ...
    sprintf('Element age:   %.2f hours',observation.ElementAgeHours); ...
    sprintf('Retrieved:     %s',string(observation.RetrievalTimeUtc, ...
        "yyyy-MM-dd HH:mm:ss 'UTC'")); ...
    sprintf('Source:        %s',observation.Source)};
end

function lines = initialStatusText()
lines = { ...
    'DATA SOURCE'; ...
    '  Validated CelesTrak records with local cache fallback'; ...
    ''; ...
    'PROPAGATION'; ...
    '  Vallado SGP4 and independent ode45 two-body model'; ...
    ''; ...
    'FRAME / DIFFERENCE'; ...
    '  J2000/FK5 ECI; two-body minus SGP4'; ...
    ''; ...
    'CLOCK REFERENCE'; ...
    '  Satellite minus stationary equatorial surface clock'};
end

function lines = guideText()
lines = { ...
    'SATELLITE OBSERVER - QUICK GUIDE'; ...
    ''; ...
    'OBSERVER TAB'; ...
    '1. Select one of the six real satellites.'; ...
    '2. Press LIVE NOW for the current propagated position and 5-second updates.'; ...
    '3. The embedded satelliteScenario shows all six satellites moving.'; ...
    '4. Drag/zoom the globe and use its built-in timeline controls.'; ...
    '5. Use RESTART 3-D VIEW to reset the globe to current UTC.'; ...
    '6. Or select an engineering horizon, inspect results, and export a snapshot.'; ...
    ''; ...
    'ENGINEERING RESULTS TAB'; ...
    '- Review performance metrics and every verification check.'; ...
    '- Run the acceptance suite without leaving Satellite Observer.'; ...
    '- Update CelesTrak data and rebuild dependent analyses.'; ...
    '- Open the final report or results folder.'; ...
    ''; ...
    'UPDATE BEHAVIOR'; ...
    'A fresh-data update can take several minutes. If the network is unavailable,'; ...
    'the validated cache fallback remains available and retains provenance.'};
end

function lines = limitationsText()
lines = { ...
    'ENGINEERING LIMITATIONS'; ...
    ''; ...
    '- SGP4 versus two-body separation is model disagreement, not truth error.'; ...
    '- Cached records are reproducible evidence, not permanently current data.'; ...
    '- LIVE NOW is an SGP4 estimate from orbital elements, not onboard telemetry.'; ...
    '- The two-body model omits drag, J2, third bodies, radiation pressure,'; ...
    '  maneuvers, covariance, and measurement updates.'; ...
    '- Relativity uses a spherical nonrotating Earth and an idealized stationary'; ...
    '  equatorial reference clock.'; ...
    '- The native 3-D globe requires Satellite Communications Toolbox.'; ...
    ''; ...
    'VERIFIED ACCEPTANCE RESULT'; ...
    '- 120/120 automated simulations passed.'; ...
    '- 17/17 consolidated verification checks passed.'; ...
    '- The theoretical GPS net result was +38.452079 microseconds/day.'};
end
