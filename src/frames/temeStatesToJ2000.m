function [positionJ2000Km,velocityJ2000KmPerSec,metadata] = ...
    temeStatesToJ2000(positionTemeKm,velocityTemeKmPerSec,timeUtc,eop, ...
    frameLibraryDirectory)
%TEMESTATESTOJ2000 Convert TEME states to a J2000/FK5 inertial realization.
%   Uses Vallado's IAU-76/FK5 TEME conversion, IAU-1980 nutation series,
%   CelesTrak dPsi/dEpsilon corrections, and UTC->TT via TAI-UTC from EOP.

arguments
    positionTemeKm (:,3) double {mustBeFinite}
    velocityTemeKmPerSec (:,3) double {mustBeFinite}
    timeUtc (:,1) datetime
    eop (:,:) table
    frameLibraryDirectory (1,1) string
end

sampleCount = size(positionTemeKm,1);
if size(velocityTemeKmPerSec,1) ~= sampleCount || numel(timeUtc) ~= sampleCount
    error('temeStatesToJ2000:SizeMismatch', ...
        'Position, velocity, and time arrays must have equal row counts.');
end
if isempty(timeUtc.TimeZone)
    error('temeStatesToJ2000:TimeZoneRequired','timeUtc must specify UTC.');
end
timeUtc.TimeZone = 'UTC';
if min(timeUtc) < eop.DateUtc(1) || max(timeUtc) > eop.DateUtc(end)
    error('temeStatesToJ2000:EopCoverage', ...
        'Requested times fall outside the EOP file coverage.');
end

iau80 = iau80in(char(frameLibraryDirectory + filesep));
sourceSeconds = posixtime(eop.DateUtc);
querySeconds = posixtime(timeUtc);
deltaPsiArcsec = interp1(sourceSeconds,eop.DeltaPsiArcsec,querySeconds, ...
    'linear');
deltaEpsilonArcsec = interp1(sourceSeconds,eop.DeltaEpsilonArcsec, ...
    querySeconds,'linear');
taiMinusUtc = interp1(sourceSeconds,eop.TaiMinusUtcSeconds,querySeconds, ...
    'previous');
arcsecToRad = pi/(180*3600);

positionJ2000Km = zeros(sampleCount,3);
velocityJ2000KmPerSec = zeros(sampleCount,3);
maximumOrthogonalityError = 0;
for index = 1:sampleCount
    tt = timeUtc(index) + seconds(taiMinusUtc(index) + 32.184);
    [jd,jdf] = jday(year(tt),month(tt),day(tt),hour(tt),minute(tt),second(tt));
    ttt = (jd+jdf-2451545.0)/36525;
    ddpsi = deltaPsiArcsec(index)*arcsecToRad;
    ddeps = deltaEpsilonArcsec(index)*arcsecToRad;
    [position,velocity] = teme2eci(positionTemeKm(index,:).', ...
        velocityTemeKmPerSec(index,:).',zeros(3,1),iau80,ttt,ddpsi,ddeps);
    positionJ2000Km(index,:) = position.';
    velocityJ2000KmPerSec(index,:) = velocity.';

    % The position transformation is a pure rotation; recover its columns
    % periodically to verify numerical orthogonality without exposing vendor code.
    if index == 1 || index == sampleCount
        rotation = zeros(3);
        for axisIndex = 1:3
            basis = zeros(3,1); basis(axisIndex) = 1;
            rotation(:,axisIndex) = teme2eci(basis,zeros(3,1),zeros(3,1), ...
                iau80,ttt,ddpsi,ddeps);
        end
        maximumOrthogonalityError = max(maximumOrthogonalityError, ...
            norm(rotation.'*rotation-eye(3),'fro'));
    end
end

metadata = struct();
metadata.referenceFrame = ...
    "J2000/FK5 ECI (IAU-76 precession, IAU-1980 nutation)";
metadata.eopSource = "CelesTrak EOP-Last5Years.csv";
metadata.maximumRotationOrthogonalityError = maximumOrthogonalityError;
metadata.maximumAbsoluteEopCorrectionArcsec = max(abs( ...
    [deltaPsiArcsec;deltaEpsilonArcsec]),[],'all');
metadata.taiMinusUtcSeconds = unique(taiMinusUtc);
end
