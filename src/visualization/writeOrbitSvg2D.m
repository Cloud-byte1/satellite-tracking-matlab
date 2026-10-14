function writeOrbitSvg2D(position, earthRadius, outputFile)
%WRITEORBITSVG2D Write a self-contained 2D vector trajectory plot.
%   This base-MATLAB exporter does not require a graphics renderer. It is useful
%   for automated or headless runs; PLOTORBIT2D remains the interactive version.

arguments
    position (:,3) double {mustBeFinite}
    earthRadius (1,1) double {mustBePositive, mustBeFinite}
    outputFile (1,1) string
end

canvasWidth = 1000;
canvasHeight = 820;
centerX = 500;
centerY = 410;
plotHalfSize = 330;
limit = 1.10*max(vecnorm(position(:,1:2), 2, 2));
scale = plotHalfSize/limit;

pixelX = centerX + scale*position(:,1);
pixelY = centerY - scale*position(:,2);
earthPixelRadius = scale*earthRadius;
orbitPoints = pointsAttribute(pixelX, pixelY);

fileId = fopen(outputFile, 'w');
if fileId < 0
    error('writeOrbitSvg2D:FileOpenFailed', 'Cannot open %s.', outputFile);
end
fileCleanup = onCleanup(@() fclose(fileId));

fprintf(fileId, '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n', ...
    canvasWidth, canvasHeight, canvasWidth, canvasHeight);
fprintf(fileId, '<rect width="100%%" height="100%%" fill="white"/>\n');
fprintf(fileId, '<text x="500" y="38" text-anchor="middle" font-family="Arial" font-size="24" font-weight="bold">Two-Body Propagation: 500 km Circular Orbit</text>\n');
fprintf(fileId, '<line x1="170" y1="410" x2="830" y2="410" stroke="#b8c2cc" stroke-width="1"/>\n');
fprintf(fileId, '<line x1="500" y1="80" x2="500" y2="740" stroke="#b8c2cc" stroke-width="1"/>\n');
fprintf(fileId, '<circle cx="%.3f" cy="%.3f" r="%.3f" fill="#408cd9" stroke="#193f7a" stroke-width="2"/>\n', ...
    centerX, centerY, earthPixelRadius);
fprintf(fileId, '<polyline points="%s" fill="none" stroke="#d62728" stroke-width="3"/>\n', orbitPoints);
fprintf(fileId, '<circle cx="%.3f" cy="%.3f" r="7" fill="#ffd92f" stroke="black" stroke-width="2"/>\n', ...
    pixelX(1), pixelY(1));
fprintf(fileId, '<text x="500" y="790" text-anchor="middle" font-family="Arial" font-size="18">ECI x (km)</text>\n');
fprintf(fileId, '<text x="35" y="410" text-anchor="middle" font-family="Arial" font-size="18" transform="rotate(-90 35 410)">ECI y (km)</text>\n');
fprintf(fileId, '<rect x="690" y="90" width="235" height="88" rx="8" fill="white" stroke="#777"/>\n');
fprintf(fileId, '<circle cx="715" cy="115" r="9" fill="#408cd9"/><text x="735" y="121" font-family="Arial" font-size="16">Earth</text>\n');
fprintf(fileId, '<line x1="706" y1="145" x2="724" y2="145" stroke="#d62728" stroke-width="3"/><text x="735" y="151" font-family="Arial" font-size="16">500 km orbit</text>\n');
fprintf(fileId, '<circle cx="715" cy="166" r="6" fill="#ffd92f" stroke="black"/><text x="735" y="172" font-family="Arial" font-size="16">Initial state</text>\n');
fprintf(fileId, '</svg>\n');
end

function value = pointsAttribute(x, y)
pairs = compose('%.3f,%.3f', x, y);
value = strjoin(cellstr(pairs), ' ');
end

