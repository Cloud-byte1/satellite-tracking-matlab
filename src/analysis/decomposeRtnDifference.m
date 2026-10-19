function [componentsKm,basisRtnToInertial,reconstructionErrorKm] = ...
    decomposeRtnDifference(referencePositionKm,referenceVelocityKmPerSec, ...
    differenceKm)
%DECOMPOSERTNDIFFERENCE Resolve inertial differences in the reference RTN frame.
%   The signed difference is comparison minus reference. R points outward,
%   N follows r cross v, and T = N cross R (approximately along velocity).

arguments
    referencePositionKm (:,3) double {mustBeFinite}
    referenceVelocityKmPerSec (:,3) double {mustBeFinite}
    differenceKm (:,3) double {mustBeFinite}
end

count = size(referencePositionKm,1);
if size(referenceVelocityKmPerSec,1) ~= count || size(differenceKm,1) ~= count
    error('decomposeRtnDifference:SizeMismatch', ...
        'All inputs must have equal row counts.');
end

componentsKm = zeros(count,3);
basisRtnToInertial = zeros(count,3,3);
reconstructionErrorKm = zeros(count,1);
for index = 1:count
    r = referencePositionKm(index,:).';
    v = referenceVelocityKmPerSec(index,:).';
    radial = r/norm(r);
    normal = cross(r,v); normal = normal/norm(normal);
    transverse = cross(normal,radial); transverse = transverse/norm(transverse);
    rotation = [radial transverse normal];
    component = rotation.'*differenceKm(index,:).';
    reconstruction = rotation*component;
    componentsKm(index,:) = component.';
    basisRtnToInertial(index,:,:) = reshape(rotation,1,3,3);
    reconstructionErrorKm(index) = norm( ...
        reconstruction-differenceKm(index,:).');
end
end
