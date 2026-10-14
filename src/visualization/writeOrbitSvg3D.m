function writeOrbitSvg3D(position, earthRadius, outputFile)
%WRITEORBITSVG3D Write an orthographic 3D-style vector trajectory plot.
%   The projected sphere grid and orbit use a 35-degree azimuth and 25-degree
%   elevation. This exporter is renderer-independent and uses base MATLAB only.

arguments
    position (:,3) double {mustBeFinite}
    earthRadius (1,1) double {mustBePositive, mustBeFinite}
    outputFile (1,1) string
end

canvasWidth = 1000;
canvasHeight = 820;
centerX = 500;
centerY = 420;
plotHalfSize = 330;
limit = 1.12*max(vecnorm(position, 2, 2));
scale = plotHalfSize/limit;
azimuth = deg2rad(35);
elevation = deg2rad(25);

[orbitU, orbitV] = project(position, azimuth, elevation);
orbitX = centerX + scale*orbitU;
orbitY = centerY - scale*orbitV;

fileId = fopen(outputFile, 'w');
if fileId < 0
    error('writeOrbitSvg3D:FileOpenFailed', 'Cannot open %s.', outputFile);
end
fileCleanup = onCleanup(@() fclose(fileId));

fprintf(fileId, '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n', ...
    canvasWidth, canvasHeight, canvasWidth, canvasHeight);
fprintf(fileId, '<rect width="100%%" height="100%%" fill="white"/>\n');
fprintf(fileId, '<text x="500" y="38" text-anchor="middle" font-family="Arial" font-size="24" font-weight="bold">Three-Dimensional Earth-Centered Inertial Trajectory</text>\n');
fprintf(fileId, '<defs><radialGradient id="earth" cx="35%%" cy="30%%"><stop offset="0%%" stop-color="#83c7ef"/><stop offset="100%%" stop-color="#1f5f9b"/></radialGradient></defs>\n');
fprintf(fileId, '<circle cx="%g" cy="%g" r="%.3f" fill="url(#earth)" stroke="#153e68" stroke-width="2"/>\n', ...
    centerX, centerY, scale*earthRadius);

theta = linspace(0, 2*pi, 241).';
for latitudeDegrees = [-60, -30, 0, 30, 60]
    latitude = deg2rad(latitudeDegrees);
    grid = earthRadius*[cos(latitude)*cos(theta), ...
        cos(latitude)*sin(theta), sin(latitude)*ones(size(theta))];
    writeGridLine(fileId, grid, azimuth, elevation, centerX, centerY, scale);
end
for longitudeDegrees = 0:30:150
    longitude = deg2rad(longitudeDegrees);
    grid = earthRadius*[cos(theta)*cos(longitude), ...
        cos(theta)*sin(longitude), sin(theta)];
    writeGridLine(fileId, grid, azimuth, elevation, centerX, centerY, scale);
end

fprintf(fileId, '<polyline points="%s" fill="none" stroke="#d62728" stroke-width="3.2"/>\n', ...
    pointsAttribute(orbitX, orbitY));
fprintf(fileId, '<circle cx="%.3f" cy="%.3f" r="7" fill="#ffd92f" stroke="black" stroke-width="2"/>\n', ...
    orbitX(1), orbitY(1));

% Project and draw the positive coordinate axes for orientation.
axisLength = 1.27*max(vecnorm(position, 2, 2));
origins = zeros(3,3);
endpoints = axisLength*eye(3);
axisColors = [0.10 0.10 0.10; 0.10 0.10 0.10; 0.10 0.10 0.10];
axisLabels = ["x" "y" "z"];
for index = 1:3
    [originU, originV] = project(origins(index,:), azimuth, elevation);
    [endU, endV] = project(endpoints(index,:), azimuth, elevation);
    x1 = centerX + scale*originU; y1 = centerY - scale*originV;
    x2 = centerX + scale*endU; y2 = centerY - scale*endV;
    fprintf(fileId, '<line x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f" stroke="rgb(%d,%d,%d)" stroke-width="1.5"/>\n', ...
        x1, y1, x2, y2, round(255*axisColors(index,1)), ...
        round(255*axisColors(index,2)), round(255*axisColors(index,3)));
    fprintf(fileId, '<text x="%.2f" y="%.2f" font-family="Arial" font-size="18">ECI %s</text>\n', ...
        x2+5, y2-5, axisLabels(index));
end

fprintf(fileId, '<rect x="690" y="90" width="235" height="88" rx="8" fill="white" stroke="#777"/>\n');
fprintf(fileId, '<circle cx="715" cy="115" r="9" fill="#408cd9"/><text x="735" y="121" font-family="Arial" font-size="16">Earth</text>\n');
fprintf(fileId, '<line x1="706" y1="145" x2="724" y2="145" stroke="#d62728" stroke-width="3"/><text x="735" y="151" font-family="Arial" font-size="16">500 km orbit</text>\n');
fprintf(fileId, '<circle cx="715" cy="166" r="6" fill="#ffd92f" stroke="black"/><text x="735" y="172" font-family="Arial" font-size="16">Initial state</text>\n');
fprintf(fileId, '</svg>\n');
end

function writeGridLine(fileId, points, azimuth, elevation, centerX, centerY, scale)
[u, v] = project(points, azimuth, elevation);
x = centerX + scale*u;
y = centerY - scale*v;
fprintf(fileId, '<polyline points="%s" fill="none" stroke="#d5e8f5" stroke-width="1" opacity="0.75"/>\n', ...
    pointsAttribute(x, y));
end

function [u, v] = project(points, azimuth, elevation)
u = -sin(azimuth)*points(:,1) + cos(azimuth)*points(:,2);
v = -sin(elevation)*cos(azimuth)*points(:,1) ...
    - sin(elevation)*sin(azimuth)*points(:,2) ...
    + cos(elevation)*points(:,3);
end

function value = pointsAttribute(x, y)
pairs = compose('%.3f,%.3f', x, y);
value = strjoin(cellstr(pairs), ' ');
end

