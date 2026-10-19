function figureHandle = plotMultipleOrbits3D(runs, earthRadiusKm)
%PLOTMULTIPLEORBITS3D Plot Earth and multiple propagated ECI trajectories.
%   RUNS is the structure array produced by RUN_DAY03_ADVANCED_ORBITS.

arguments
    runs (:,1) struct
    earthRadiusKm (1,1) double {mustBePositive, mustBeFinite}
end

figureHandle = figure('Color', 'white', 'Name', 'Day 3 Multi-Orbit Comparison', ...
    'Position', [80 80 1280 820]);
axesHandle = axes(figureHandle);
set(axesHandle, 'Color', 'white', 'XColor', [0.15 0.15 0.15], ...
    'YColor', [0.15 0.15 0.15], 'ZColor', [0.15 0.15 0.15], ...
    'GridColor', [0.72 0.72 0.72], 'GridAlpha', 0.45);
hold(axesHandle, 'on');

[earthX, earthY, earthZ] = sphere(120);
earthSurface = surf(axesHandle, earthRadiusKm*earthX, earthRadiusKm*earthY, ...
    earthRadiusKm*earthZ, 'FaceColor', [0.10 0.36 0.62], ...
    'EdgeColor', 'none', 'FaceAlpha', 0.82, 'DisplayName', 'Earth');

orbitHandles = gobjects(numel(runs), 1);
markerHandles = gobjects(numel(runs), 1);
maximumRadius = earthRadiusKm;
for index = 1:numel(runs)
    scenario = runs(index).scenario;
    position = runs(index).solution.position;
    velocity = runs(index).solution.velocity;
    maximumRadius = max(maximumRadius, max(vecnorm(position, 2, 2)));
    orbitHandles(index) = plot3(axesHandle, position(:,1), position(:,2), ...
        position(:,3), '-', 'Color', scenario.color, 'LineWidth', 1.8, ...
        'DisplayName', scenario.name);
    markerHandles(index) = plot3(axesHandle, position(1,1), position(1,2), ...
        position(1,3), 'o', 'Color', scenario.color, ...
        'MarkerFaceColor', scenario.color, 'MarkerSize', 6, ...
        'HandleVisibility', 'off');

    % A normalized arrow at the initial state indicates direction of motion.
    arrowLength = 0.055*max(vecnorm(position, 2, 2));
    direction = velocity(1,:)/norm(velocity(1,:));
    quiver3(axesHandle, position(1,1), position(1,2), position(1,3), ...
        arrowLength*direction(1), arrowLength*direction(2), ...
        arrowLength*direction(3), 0, 'Color', scenario.color, ...
        'LineWidth', 1.4, 'MaxHeadSize', 0.8, 'HandleVisibility', 'off');
end

axis(axesHandle, 'equal');
limit = 1.08*maximumRadius;
xlim(axesHandle, [-limit limit]);
ylim(axesHandle, [-limit limit]);
zlim(axesHandle, [-limit limit]);
grid(axesHandle, 'on');
box(axesHandle, 'on');
xlabel(axesHandle, 'ECI x (km)');
ylabel(axesHandle, 'ECI y (km)');
zlabel(axesHandle, 'ECI z (km)');
titleHandle = title(axesHandle, {'Day 3: Six Two-Body Earth Orbits', ...
    'Initial epoch t = 0 s; each trajectory spans one Kepler period'});
set(titleHandle, 'Color', [0.10 0.10 0.10], 'FontWeight', 'bold');
legendHandle = legend(axesHandle, [earthSurface; orbitHandles], ...
    'Location', 'eastoutside');
set(legendHandle, 'Color', 'white', 'TextColor', [0.10 0.10 0.10], ...
    'EdgeColor', [0.65 0.65 0.65]);
view(axesHandle, 35, 24);
camlight(axesHandle, 'headlight');
lighting(axesHandle, 'gouraud');
set(axesHandle, 'FontName', 'Arial', 'FontSize', 10);
end
