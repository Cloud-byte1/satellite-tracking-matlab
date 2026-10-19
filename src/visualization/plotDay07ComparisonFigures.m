function figures = plotDay07ComparisonFigures(comparison,catalog,metrics,earthRadiusKm)
%PLOTDAY07COMPARISONFIGURES Create four report-quality model comparisons.

colors = lines(height(catalog));
figures = gobjects(4,1);

figures(1) = figure('Color','white','Position',[40 40 1500 900], ...
    'Name','Day 7 Trajectory Comparison');
layout = tiledlayout(figures(1),2,3,'TileSpacing','compact','Padding','compact');
for satellite = 1:height(catalog)
    ax = nexttile(layout); hold(ax,'on');
    [x,y,z] = sphere(36);
    surf(ax,earthRadiusKm*x,earthRadiusKm*y,earthRadiusKm*z, ...
        'FaceColor',[0.16 0.42 0.68],'FaceAlpha',0.55,'EdgeColor','none');
    plot3(ax,comparison.positionSgp4J2000Km(:,1,satellite), ...
        comparison.positionSgp4J2000Km(:,2,satellite), ...
        comparison.positionSgp4J2000Km(:,3,satellite),'-', ...
        'Color',colors(satellite,:),'LineWidth',1.5);
    plot3(ax,comparison.positionTwoBodyJ2000Km(:,1,satellite), ...
        comparison.positionTwoBodyJ2000Km(:,2,satellite), ...
        comparison.positionTwoBodyJ2000Km(:,3,satellite),'--', ...
        'Color',[0.15 0.15 0.15],'LineWidth',1.15);
    axis(ax,'equal'); grid(ax,'on'); view(ax,35,25);
    title(ax,sprintf('%s | %s',catalog.SatelliteName(satellite), ...
        catalog.Regime(satellite)),'Interpreter','none');
    xlabel(ax,'x (km)'); ylabel(ax,'y (km)'); zlabel(ax,'z (km)');
    legend(ax,{'Earth','SGP4','Two-body'},'Location','best');
end
title(layout,'SGP4 and Newtonian Two-Body Trajectories — J2000/FK5 ECI');
applyReportTheme(figures(1));

figures(2) = figure('Color','white','Position',[80 80 1200 720], ...
    'Name','Day 7 Position Separation');
ax = axes(figures(2)); hold(ax,'on');
for satellite = 1:height(catalog)
    semilogy(ax,comparison.elapsedSeconds/3600, ...
        max(comparison.positionSeparationKm(:,satellite),1e-9), ...
        'LineWidth',1.7,'Color',colors(satellite,:), ...
        'DisplayName',catalog.SatelliteName(satellite));
end
set(ax,'YScale','log');
grid(ax,'on'); xlabel(ax,'Prediction time (h)');
ylabel(ax,'Position separation (km, logarithmic scale)');
title(ax,'SGP4-to-Two-Body Position Separation');
legend(ax,'Location','northwest','Interpreter','none');
applyReportTheme(figures(2));

figures(3) = figure('Color','white','Position',[50 50 1500 900], ...
    'Name','Day 7 RTN Differences');
layout = tiledlayout(figures(3),2,3,'TileSpacing','compact','Padding','compact');
for satellite = 1:height(catalog)
    ax = nexttile(layout); hold(ax,'on');
    plot(ax,comparison.elapsedSeconds/3600, ...
        comparison.rtnDifferenceKm(:,1,satellite),'LineWidth',1.25);
    plot(ax,comparison.elapsedSeconds/3600, ...
        comparison.rtnDifferenceKm(:,2,satellite),'LineWidth',1.25);
    plot(ax,comparison.elapsedSeconds/3600, ...
        comparison.rtnDifferenceKm(:,3,satellite),'LineWidth',1.25);
    grid(ax,'on'); xlabel(ax,'Time (h)'); ylabel(ax,'Difference (km)');
    title(ax,catalog.SatelliteName(satellite),'Interpreter','none');
    legend(ax,{'Radial','Along-track','Cross-track'},'Location','best');
end
title(layout,'RTN Components of Two-Body Minus SGP4');
applyReportTheme(figures(3));

figures(4) = figure('Color','white','Position',[100 100 1250 720], ...
    'Name','Day 7 Regime Comparison');
pivot = unstack(metrics(:,{'SatelliteName','HorizonHours', ...
    'FinalPositionSeparationKm'}),'FinalPositionSeparationKm','HorizonHours', ...
    'AggregationFunction',@mean,'VariableNamingRule','preserve');
values = pivot{:,2:end};
bar(values); grid on;
set(gca,'YScale','log','XTick',1:height(pivot), ...
    'XTickLabel',pivot.SatelliteName,'TickLabelInterpreter','none');
ylabel('Final position separation (km, logarithmic scale)');
xlabel('Satellite'); title('Model Separation Across LEO, MEO, and GEO');
legend(compose('%g h',sort(unique(metrics.HorizonHours))), ...
    'Location','northwest');
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
