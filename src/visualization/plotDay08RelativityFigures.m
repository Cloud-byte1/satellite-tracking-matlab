function figures = plotDay08RelativityFigures(analysis,config)
%PLOTDAY08RELATIVITYFIGURES Create four report-quality timing figures.

summary = analysis.summary;
colors = lines(height(summary));
figures = gobjects(4,1);

figures(1) = figure('Color','white','Position',[80 80 1200 720], ...
    'Name','Day 8 Altitude Trend');
altitude = logspace(log10(200),log10(50000),600).';
radius = config.earthRadiusKm+altitude;
speed = sqrt(config.muEarthKm3PerSec2./radius);
betaSquared = (speed/config.speedOfLightKmPerSec).^2;
dailyDrift = -betaSquared./(1+sqrt(1-betaSquared))*86400*1e6;
ax = axes(figures(1)); hold(ax,'on');
semilogx(ax,altitude,dailyDrift,'Color',[0.05 0.28 0.55], ...
    'LineWidth',2,'DisplayName','Theoretical circular orbit');
for index = 1:height(summary)
    scatter(ax,summary.MeanAltitudeKm(index), ...
        summary.EquivalentDriftMicrosecondsPerDay(index),55, ...
        colors(index,:),'filled','DisplayName',summary.ScenarioName(index));
end
grid(ax,'on'); xlabel(ax,'Mean orbital altitude (km)');
ylabel(ax,'Kinematic clock drift (\mus/day)');
title(ax,'Special-Relativistic Clock Drift Versus Orbital Altitude');
subtitle(ax,'Velocity term only; satellite proper time minus J2000/FK5 coordinate time');
legend(ax,'Location','eastoutside','Interpreter','none');
applyReportTheme(figures(1));

figures(2) = figure('Color','white','Position',[100 100 1200 720], ...
    'Name','Day 8 Accumulated Drift');
ax = axes(figures(2)); hold(ax,'on');
for index = 1:numel(analysis.histories)
    history = analysis.histories(index);
    plot(ax,history.elapsedSeconds/3600, ...
        history.clock.accumulatedExactMicroseconds,'LineWidth',1.5, ...
        'Color',colors(index,:),'DisplayName',history.name);
end
grid(ax,'on'); xlabel(ax,'Elapsed coordinate time (h)');
ylabel(ax,'Accumulated proper-time difference (\mus)');
title(ax,'Accumulated Special-Relativistic Clock Drift');
subtitle(ax,'Integrated exact kinematic rate; gravitational effects excluded');
legend(ax,'Location','eastoutside','Interpreter','none');
applyReportTheme(figures(2));

figures(3) = figure('Color','white','Position',[120 80 1250 760], ...
    'Name','Day 8 Scenario Comparison');
ax = axes(figures(3));
barh(ax,summary.EquivalentDriftMicrosecondsPerDay, ...
    'FaceColor',[0.15 0.48 0.72]);
grid(ax,'on'); set(ax,'YTick',1:height(summary), ...
    'YTickLabel',summary.ScenarioName,'TickLabelInterpreter','none', ...
    'YDir','reverse');
xlabel(ax,'Equivalent kinematic drift (\mus/day)');
ylabel(ax,'Satellite or orbital scenario');
title(ax,'Special-Relativistic Correction Across Satellite Types');
subtitle(ax,'More negative values correspond to higher mean orbital speed');
applyReportTheme(figures(3));

ellipticalIndex = find([analysis.histories.name]== ...
    "Theoretical elliptical 500 x 20,200 km",1);
history = analysis.histories(ellipticalIndex);
periodSeconds = history.orbitalPeriodHours*3600;
mask = history.elapsedSeconds<=periodSeconds;
anomaly = history.trueAnomalyDeg(mask);
[anomaly,order] = sort(anomaly);
speed = history.clock.speedKmPerSec(mask); speed = speed(order);
drift = history.clock.instantaneousExactMicrosecondsPerDay(mask); drift = drift(order);
figures(4) = figure('Color','white','Position',[140 100 1200 720], ...
    'Name','Day 8 Elliptical Orbit');
ax = axes(figures(4));
yyaxis(ax,'left');
plot(ax,anomaly,drift,'LineWidth',2,'Color',[0.75 0.18 0.18]);
ylabel(ax,'Instantaneous clock drift (\mus/day)');
yyaxis(ax,'right');
plot(ax,anomaly,speed,'--','LineWidth',1.7,'Color',[0.10 0.36 0.68]);
ylabel(ax,'Orbital speed (km/s)');
grid(ax,'on'); xlabel(ax,'True anomaly from perigee (deg)');
title(ax,'Elliptical-Orbit Kinematic Clock Rate');
subtitle(ax,'500 km perigee, 20,200 km apogee; perigee at 0 degrees');
legend(ax,{'Clock drift','Orbital speed'},'Location','south');
applyReportTheme(figures(4));
end

function applyReportTheme(figureHandle)
axesHandles = findall(figureHandle,'Type','axes');
set(axesHandles,'Color','white','XColor',[0.12 0.12 0.12], ...
    'YColor',[0.12 0.12 0.12],'ZColor',[0.12 0.12 0.12], ...
    'GridColor',[0.72 0.72 0.72],'GridAlpha',0.5);
legendHandles = findall(figureHandle,'Type','legend');
set(legendHandles,'Color','white','TextColor',[0.12 0.12 0.12], ...
    'EdgeColor',[0.45 0.45 0.45]);
textHandles = findall(figureHandle,'Type','text');
set(textHandles,'Color',[0.12 0.12 0.12]);
end
