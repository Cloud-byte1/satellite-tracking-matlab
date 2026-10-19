function comparison = compareSgp4WithTwoBody(catalog,retrievals,eop,config,options)
%COMPARESGP4WITHTWOBODY Propagate real records with SGP4 and ode45.

arguments
    catalog (:,:) table
    retrievals (:,1) struct
    eop (:,:) table
    config (1,1) struct
    options.StartTimeUtc (1,1) datetime = max(catalog.RetrievalTimeUtc)
end

sgp4 = propagateSgp4Catalog(catalog,retrievals, ...
    StartTimeUtc=options.StartTimeUtc,DurationHours=config.durationHours, ...
    StepSeconds=config.stepSeconds);
sampleCount = numel(sgp4.timeUtc);
satelliteCount = height(catalog);
positionSgp4J2000Km = zeros(sampleCount,3,satelliteCount);
velocitySgp4J2000KmPerSec = zeros(sampleCount,3,satelliteCount);
positionTwoBodyJ2000Km = zeros(sampleCount,3,satelliteCount);
velocityTwoBodyJ2000KmPerSec = zeros(sampleCount,3,satelliteCount);
positionDifferenceJ2000Km = zeros(sampleCount,3,satelliteCount);
velocityDifferenceJ2000KmPerSec = zeros(sampleCount,3,satelliteCount);
rtnDifferenceKm = zeros(sampleCount,3,satelliteCount);
rtnBasis = zeros(sampleCount,3,3,satelliteCount);
rtnReconstructionErrorKm = zeros(sampleCount,satelliteCount);
frameMetadata = cell(satelliteCount,1);

for satellite = 1:satelliteCount
    [rSgp4,vSgp4,frameMetadata{satellite}] = temeStatesToJ2000( ...
        sgp4.positionTemeKm(:,:,satellite), ...
        sgp4.velocityTemeKmPerSec(:,:,satellite),sgp4.timeUtc,eop, ...
        config.frameLibraryDirectory);
    initialState = [rSgp4(1,:) vSgp4(1,:)].';
    twoBody = propagateTwoBody(initialState,sgp4.elapsedSeconds, ...
        config.twoBodyMuKm3PerSec2, ...
        RelativeTolerance=config.relativeTolerance, ...
        AbsoluteTolerance=config.absoluteTolerance, ...
        MaximumStep=config.maximumStepSeconds);
    deltaPosition = twoBody.position-rSgp4;
    deltaVelocity = twoBody.velocity-vSgp4;
    [rtn,basis,reconstructionError] = decomposeRtnDifference( ...
        rSgp4,vSgp4,deltaPosition);
    positionSgp4J2000Km(:,:,satellite) = rSgp4;
    velocitySgp4J2000KmPerSec(:,:,satellite) = vSgp4;
    positionTwoBodyJ2000Km(:,:,satellite) = twoBody.position;
    velocityTwoBodyJ2000KmPerSec(:,:,satellite) = twoBody.velocity;
    positionDifferenceJ2000Km(:,:,satellite) = deltaPosition;
    velocityDifferenceJ2000KmPerSec(:,:,satellite) = deltaVelocity;
    rtnDifferenceKm(:,:,satellite) = rtn;
    rtnBasis(:,:,:,satellite) = basis;
    rtnReconstructionErrorKm(:,satellite) = reconstructionError;
end

comparison = sgp4;
comparison.positionSgp4J2000Km = positionSgp4J2000Km;
comparison.velocitySgp4J2000KmPerSec = velocitySgp4J2000KmPerSec;
comparison.positionTwoBodyJ2000Km = positionTwoBodyJ2000Km;
comparison.velocityTwoBodyJ2000KmPerSec = velocityTwoBodyJ2000KmPerSec;
comparison.positionDifferenceJ2000Km = positionDifferenceJ2000Km;
comparison.velocityDifferenceJ2000KmPerSec = velocityDifferenceJ2000KmPerSec;
comparison.rtnDifferenceKm = rtnDifferenceKm;
comparison.rtnBasis = rtnBasis;
comparison.rtnReconstructionErrorKm = rtnReconstructionErrorKm;
comparison.positionSeparationKm = squeeze(vecnorm(positionDifferenceJ2000Km,2,2));
comparison.velocityDifferenceKmPerSec = squeeze(vecnorm( ...
    velocityDifferenceJ2000KmPerSec,2,2));
comparison.referenceFrame = config.referenceFrame;
comparison.differenceConvention = "two-body minus SGP4";
comparison.frameMetadata = vertcat(frameMetadata{:});
comparison.twoBodyMuKm3PerSec2 = config.twoBodyMuKm3PerSec2;
comparison.config = config;
end
