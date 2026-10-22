function figures = plotFinalEngineeringFigures(day07,day09,convergence, ...
    representative)
%PLOTFINALENGINEERINGFIGURES Create the six final engineering figures.

comparison = day07.comparison;
catalog = day07.catalog;
colors = lines(height(catalog));
figures = gobjects(6,1);

figures(1) = figure('Name','Final 3D satellite trajectories', ...
    'Color','white','Position',[100 100 1050 720]);
axesHandle = axes(figures(1)); hold(axesHandle,'on');
styleAxes(axesHandle);
[xEarth,yEarth,zEarth] = sphere(60);
earthRadius = comparison.config.earthRadiusKm;
surf(axesHandle,xEarth*earthRadius,yEarth*earthRadius,zEarth*earthRadius, ...
    'FaceColor',[0.12 0.36 0.68],'EdgeColor','none','FaceAlpha',0.75, ...
    'DisplayName','Earth');
for satellite = 1:height(catalog)
    r = comparison.positionSgp4J2000Km(:,:,satellite);
    plot3(axesHandle,r(:,1),r(:,2),r(:,3),'LineWidth',1.6, ...
        'Color',colors(satellite,:),'DisplayName',catalog.SatelliteName(satellite));
end
axis(axesHandle,'equal'); grid(axesHandle,'on'); view(axesHandle,3);
xlabel(axesHandle,'J2000 X (km)'); ylabel(axesHandle,'J2000 Y (km)');
zlabel(axesHandle,'J2000 Z (km)');
title(axesHandle,'24-hour SGP4 trajectories from real CelesTrak records', ...
    'Color',[0.1 0.1 0.1],'FontSize',14);
legendHandle = legend(axesHandle,'Location','eastoutside');
set(legendHandle,'Color','white','TextColor',[0.1 0.1 0.1]);

figures(2) = figure('Name','Final position separation', ...
    'Color','white','Position',[120 120 1050 650]);
axesHandle = axes(figures(2)); hold(axesHandle,'on');
styleAxes(axesHandle);
for satellite = 1:height(catalog)
    plot(axesHandle,comparison.elapsedSeconds/3600, ...
        comparison.positionSeparationKm(:,satellite),'LineWidth',1.5, ...
        'Color',colors(satellite,:),'DisplayName',catalog.SatelliteName(satellite));
end
grid(axesHandle,'on'); xlabel(axesHandle,'Prediction horizon (h)');
ylabel(axesHandle,'|two-body - SGP4| (km)');
title(axesHandle,'Model separation is disagreement, not validated ephemeris error', ...
    'Color',[0.1 0.1 0.1],'FontSize',14);
legendHandle = legend(axesHandle,'Location','northwest');
set(legendHandle,'Color','white','TextColor',[0.1 0.1 0.1]);

figures(3) = figure('Name','Final RTN separation', ...
    'Color','white','Position',[140 80 1200 760]);
layout = tiledlayout(figures(3),2,3,'TileSpacing','compact');
for satellite = 1:height(catalog)
    axesHandle = nexttile(layout); hold(axesHandle,'on');
    styleAxes(axesHandle);
    rtn = comparison.rtnDifferenceKm(:,:,satellite);
    plot(axesHandle,comparison.elapsedSeconds/3600,rtn,'LineWidth',1.1);
    grid(axesHandle,'on'); title(axesHandle,catalog.SatelliteName(satellite), ...
        'Color',[0.1 0.1 0.1]);
    xlabel(axesHandle,'Hours'); ylabel(axesHandle,'Difference (km)');
    if satellite==1
        legendHandle = legend(axesHandle,{'Radial','Along-track','Cross-track'}, ...
            'Location','best');
        set(legendHandle,'Color','white','TextColor',[0.1 0.1 0.1]);
    end
end
title(layout,'RTN components of two-body minus SGP4 separation', ...
    'Color',[0.1 0.1 0.1],'FontSize',14);

figures(4) = figure('Name','Final solver convergence', ...
    'Color','white','Position',[160 140 900 600]);
axesHandle = axes(figures(4));
loglog(axesHandle,convergence.RelativeTolerance, ...
    convergence.FinalPositionDifferenceMeters,'o-','LineWidth',1.8, ...
    'MarkerFaceColor',[0.1 0.45 0.75]);
styleAxes(axesHandle);
set(axesHandle,'XDir','reverse'); grid(axesHandle,'on');
xlabel(axesHandle,'ode45 relative tolerance');
ylabel(axesHandle,'6-hour final position difference (m)');
title(axesHandle,'Numerical convergence against a tighter ode45 solution', ...
    'Color',[0.1 0.1 0.1],'FontSize',14);

figures(5) = figure('Name','Final energy conservation', ...
    'Color','white','Position',[180 160 900 600]);
axesHandle = axes(figures(5));
semilogy(axesHandle,representative.solution.time/3600, ...
    max(abs(representative.diagnostics.specificEnergy- ...
    representative.diagnostics.specificEnergy(1))/ ...
    abs(representative.diagnostics.specificEnergy(1)),eps), ...
    'LineWidth',1.7);
styleAxes(axesHandle);
grid(axesHandle,'on'); xlabel(axesHandle,'Elapsed time (h)');
ylabel(axesHandle,'Relative specific-energy drift');
title(axesHandle,'Representative two-body energy conservation', ...
    'Color',[0.1 0.1 0.1],'FontSize',14);

figures(6) = figure('Name','Final relativistic altitude sweep', ...
    'Color','white','Position',[200 100 950 620]);
axesHandle = axes(figures(6)); hold(axesHandle,'on');
styleAxes(axesHandle);
crossover = day09.analysis.crossover;
plot(axesHandle,crossover.altitudeKm, ...
    crossover.gravitationalMicrosecondsPerDay,'LineWidth',1.8, ...
    'DisplayName','Gravitational');
plot(axesHandle,crossover.altitudeKm, ...
    crossover.kinematicMicrosecondsPerDay,'LineWidth',1.8, ...
    'DisplayName','Kinematic');
plot(axesHandle,crossover.altitudeKm,crossover.netMicrosecondsPerDay, ...
    'k','LineWidth',2.1,'DisplayName','Net');
yline(axesHandle,0,':','HandleVisibility','off');
xline(axesHandle,crossover.altitudeKmAnalytical,'--', ...
    sprintf('Crossover %.1f km',crossover.altitudeKmAnalytical), ...
    'HandleVisibility','off');
grid(axesHandle,'on'); xlabel(axesHandle,'Circular-orbit altitude (km)');
ylabel(axesHandle,'Clock drift relative to surface (microseconds/day)');
title(axesHandle,'Weak-field relativistic clock drift by altitude', ...
    'Color',[0.1 0.1 0.1],'FontSize',14);
legendHandle = legend(axesHandle,'Location','southeast');
set(legendHandle,'Color','white','TextColor',[0.1 0.1 0.1]);
end

function styleAxes(axesHandle)
set(axesHandle,'Color','white','XColor',[0.12 0.12 0.12], ...
    'YColor',[0.12 0.12 0.12],'ZColor',[0.12 0.12 0.12], ...
    'GridColor',[0.45 0.45 0.45],'MinorGridColor',[0.7 0.7 0.7], ...
    'FontSize',11);
end
