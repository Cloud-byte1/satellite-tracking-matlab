function figureHandle = plotOrbit2D(position, earthRadius)
%PLOTORBIT2D Plot an equatorial trajectory and Earth cross-section.

arguments
    position (:,3) double {mustBeFinite}
    earthRadius (1,1) double {mustBePositive, mustBeFinite}
end


theta = linspace(0, 2*pi, 500);
earthX = earthRadius*cos(theta);
earthY = earthRadius*sin(theta);

figureHandle = figure('Color', 'white', 'Name', 'Day 1 2D Orbit');
earthPatch = fill(earthX, earthY, [0.25 0.55 0.85], ...
    'EdgeColor', [0.10 0.25 0.55], 'DisplayName', 'Earth');
hold on
orbitLine = plot(position(:,1), position(:,2), 'r-', 'LineWidth', 1.8, ...
    'DisplayName', '500 km orbit');
initialPoint = plot(position(1,1), position(1,2), 'ko', ...
    'MarkerFaceColor', 'y', 'MarkerSize', 7, 'DisplayName', 'Initial state');
axis equal
grid on
xlabel('ECI x (km)')
ylabel('ECI y (km)')
title('Two-Body Propagation: 500 km Circular Orbit')
legend([earthPatch, orbitLine, initialPoint], 'Location', 'best')
end

