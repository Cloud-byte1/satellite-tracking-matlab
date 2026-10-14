function figureHandle = plotOrbit3D(position, earthRadius)
%PLOTORBIT3D Plot a Cartesian trajectory around a spherical Earth.

arguments
    position (:,3) double {mustBeFinite}
    earthRadius (1,1) double {mustBePositive, mustBeFinite}
end


[earthX, earthY, earthZ] = sphere(100);

figureHandle = figure('Color', 'white', 'Name', 'Day 1 3D Orbit');
earthSurface = surf(earthRadius*earthX, earthRadius*earthY, earthRadius*earthZ, ...
    'FaceColor', [0.20 0.50 0.80], 'EdgeColor', 'none', ...
    'FaceAlpha', 0.85, 'DisplayName', 'Earth');
hold on
orbitLine = plot3(position(:,1), position(:,2), position(:,3), ...
    'r-', 'LineWidth', 2.0, 'DisplayName', '500 km orbit');
initialPoint = plot3(position(1,1), position(1,2), position(1,3), ...
    'ko', 'MarkerFaceColor', 'y', 'MarkerSize', 7, ...
    'DisplayName', 'Initial state');
axis equal
grid on
xlabel('ECI x (km)')
ylabel('ECI y (km)')
zlabel('ECI z (km)')
title('Three-Dimensional Earth-Centered Inertial Trajectory')
legend([earthSurface, orbitLine, initialPoint], 'Location', 'best')
view(35, 25)
camlight headlight
lighting gouraud
end

