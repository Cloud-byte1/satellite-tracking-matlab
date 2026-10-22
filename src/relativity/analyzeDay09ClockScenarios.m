function analysis = analyzeDay09ClockScenarios(day08Analysis,config)
%ANALYZEDAY09CLOCKSCENARIOS Apply combined relativity to saved trajectories.

arguments
    day08Analysis (1,1) struct
    config (1,1) struct
end

histories = day08Analysis.histories;
for index = 1:numel(histories)
    histories(index).relativity = combinedRelativisticClockModel( ...
        histories(index).positionKm,histories(index).velocityKmPerSec, ...
        histories(index).elapsedSeconds,config.muEarthKm3PerSec2, ...
        config.earthRadiusKm,config.speedOfLightKmPerSec, ...
        ReferenceClockConvention=config.referenceClockConvention, ...
        CoordinateTimeConvention=config.coordinateTimeConvention);
end

summary = buildSummary(histories);
timeSeries = buildTimeSeries(histories);
gpsIndex = find([histories.name]== ...
    "Theoretical GPS 20,200 km circular",1);
if isempty(gpsIndex)
    error('analyzeDay09ClockScenarios:MissingGpsBenchmark', ...
        'The Day 8 histories do not contain the theoretical GPS orbit.');
end
gpsBenchmark = buildGpsBenchmark(histories(gpsIndex),config);
crossover = buildCrossover(config);
ellipticalVerification = buildEllipticalVerification(config);

analysis = struct();
analysis.histories = histories;
analysis.summary = summary;
analysis.timeSeries = timeSeries;
analysis.gpsBenchmark = gpsBenchmark;
analysis.crossover = crossover;
analysis.ellipticalVerification = ellipticalVerification;
analysis.scenarioCount = numel(histories);
analysis.realSatelliteCount = day08Analysis.realSatelliteCount;
analysis.referenceClockConvention = config.referenceClockConvention;
analysis.coordinateTimeConvention = config.coordinateTimeConvention;
analysis.referenceFrame = config.referenceFrame;
analysis.modelLimitations = ...
    "Spherical nonrotating Earth; idealized stationary equatorial surface " + ...
    "clock; first-order gravitational potential; no J2/geopotential, " + ...
    "Earth rotation, tides, third bodies, signal propagation, onboard clock " + ...
    "telemetry, or operational GPS time realization";
end

function summary = buildSummary(histories)
count = numel(histories);
ScenarioName = strings(count,1); Source = strings(count,1);
Regime = strings(count,1); MeanAltitudeKm = zeros(count,1);
PerigeeAltitudeKm = zeros(count,1); ApogeeAltitudeKm = zeros(count,1);
MeanSpeedKmPerSec = zeros(count,1);
GravitationalMicrosecondsPerDay = zeros(count,1);
KinematicMicrosecondsPerDay = zeros(count,1);
NetMicrosecondsPerDay = zeros(count,1);
AccumulatedGravitationalMicroseconds = zeros(count,1);
AccumulatedKinematicMicroseconds = zeros(count,1);
AccumulatedNetMicroseconds = zeros(count,1);
for index = 1:count
    history = histories(index); model = history.relativity;
    ScenarioName(index) = history.name;
    Source(index) = history.source;
    Regime(index) = history.regime;
    MeanAltitudeKm(index) = mean(history.altitudeKm);
    PerigeeAltitudeKm(index) = min(history.altitudeKm);
    ApogeeAltitudeKm(index) = max(history.altitudeKm);
    MeanSpeedKmPerSec(index) = mean(model.speedKmPerSec);
    GravitationalMicrosecondsPerDay(index) = ...
        model.gravitational.equivalentMicrosecondsPerDay;
    KinematicMicrosecondsPerDay(index) = ...
        model.kinematic.equivalentApproximateMicrosecondsPerDay;
    NetMicrosecondsPerDay(index) = ...
        model.equivalentNetApproximateMicrosecondsPerDay;
    AccumulatedGravitationalMicroseconds(index) = ...
        model.gravitational.accumulatedMicroseconds(end);
    AccumulatedKinematicMicroseconds(index) = ...
        model.kinematic.accumulatedApproximateMicroseconds(end);
    AccumulatedNetMicroseconds(index) = ...
        model.accumulatedNetApproximateMicroseconds(end);
end
summary = table(ScenarioName,Source,Regime,MeanAltitudeKm, ...
    PerigeeAltitudeKm,ApogeeAltitudeKm,MeanSpeedKmPerSec, ...
    GravitationalMicrosecondsPerDay,KinematicMicrosecondsPerDay, ...
    NetMicrosecondsPerDay,AccumulatedGravitationalMicroseconds, ...
    AccumulatedKinematicMicroseconds,AccumulatedNetMicroseconds);
end

function timeSeries = buildTimeSeries(histories)
scenarioCount = numel(histories);
sampleCount = numel(histories(1).elapsedSeconds);
rowCount = scenarioCount*sampleCount;
ScenarioName = strings(rowCount,1); Source = strings(rowCount,1);
Regime = strings(rowCount,1); ElapsedHours = zeros(rowCount,1);
AltitudeKm = zeros(rowCount,1); SpeedKmPerSec = zeros(rowCount,1);
GravitationalRateCorrection = zeros(rowCount,1);
KinematicRateCorrection = zeros(rowCount,1);
NetRateCorrection = zeros(rowCount,1);
InstantaneousGravitationalMicrosecondsPerDay = zeros(rowCount,1);
InstantaneousKinematicMicrosecondsPerDay = zeros(rowCount,1);
InstantaneousNetMicrosecondsPerDay = zeros(rowCount,1);
AccumulatedGravitationalMicroseconds = zeros(rowCount,1);
AccumulatedKinematicMicroseconds = zeros(rowCount,1);
AccumulatedNetMicroseconds = zeros(rowCount,1);
for index = 1:scenarioCount
    range = (index-1)*sampleCount+(1:sampleCount);
    history = histories(index); model = history.relativity;
    ScenarioName(range) = history.name;
    Source(range) = history.source;
    Regime(range) = history.regime;
    ElapsedHours(range) = model.elapsedSeconds/3600;
    AltitudeKm(range) = model.radiusKm-configuredRadius(model);
    SpeedKmPerSec(range) = model.speedKmPerSec;
    GravitationalRateCorrection(range) = ...
        model.gravitational.clockRateCorrection;
    KinematicRateCorrection(range) = ...
        model.kinematic.approximateClockRateCorrection;
    NetRateCorrection(range) = model.netApproximateClockRateCorrection;
    InstantaneousGravitationalMicrosecondsPerDay(range) = ...
        model.gravitational.instantaneousMicrosecondsPerDay;
    InstantaneousKinematicMicrosecondsPerDay(range) = ...
        model.kinematic.instantaneousApproximateMicrosecondsPerDay;
    InstantaneousNetMicrosecondsPerDay(range) = ...
        model.instantaneousNetApproximateMicrosecondsPerDay;
    AccumulatedGravitationalMicroseconds(range) = ...
        model.gravitational.accumulatedMicroseconds;
    AccumulatedKinematicMicroseconds(range) = ...
        model.kinematic.accumulatedApproximateMicroseconds;
    AccumulatedNetMicroseconds(range) = ...
        model.accumulatedNetApproximateMicroseconds;
end
timeSeries = table(ScenarioName,Source,Regime,ElapsedHours,AltitudeKm, ...
    SpeedKmPerSec,GravitationalRateCorrection,KinematicRateCorrection, ...
    NetRateCorrection,InstantaneousGravitationalMicrosecondsPerDay, ...
    InstantaneousKinematicMicrosecondsPerDay, ...
    InstantaneousNetMicrosecondsPerDay,AccumulatedGravitationalMicroseconds, ...
    AccumulatedKinematicMicroseconds,AccumulatedNetMicroseconds);
end

function radius = configuredRadius(model)
radius = model.gravitational.referenceRadiusKm;
end

function benchmark = buildGpsBenchmark(history,config)
radiusKm = config.earthRadiusKm+config.gpsAltitudeKm;
speedKmPerSec = sqrt(config.muEarthKm3PerSec2/radiusKm);
periodSeconds = 2*pi*sqrt(radiusKm^3/config.muEarthKm3PerSec2);
model = history.relativity;
benchmark = struct();
benchmark.altitudeKm = config.gpsAltitudeKm;
benchmark.radiusKm = radiusKm;
benchmark.speedKmPerSec = speedKmPerSec;
benchmark.periodSeconds = periodSeconds;
benchmark.periodHours = periodSeconds/3600;
benchmark.surfacePotentialKm2PerSec2 = ...
    -config.muEarthKm3PerSec2/config.earthRadiusKm;
benchmark.satellitePotentialKm2PerSec2 = ...
    -config.muEarthKm3PerSec2/radiusKm;
benchmark.potentialDifferenceKm2PerSec2 = ...
    benchmark.satellitePotentialKm2PerSec2- ...
    benchmark.surfacePotentialKm2PerSec2;
benchmark.gravitationalMicrosecondsPerDay = ...
    model.gravitational.equivalentMicrosecondsPerDay;
benchmark.kinematicMicrosecondsPerDay = ...
    model.kinematic.equivalentApproximateMicrosecondsPerDay;
benchmark.netMicrosecondsPerDay = ...
    model.equivalentNetApproximateMicrosecondsPerDay;
benchmark.differenceFromStandard38p5MicrosecondsPerDay = ...
    benchmark.netMicrosecondsPerDay-38.5;
end

function crossover = buildCrossover(config)
altitudeKm = linspace(config.altitudePlotRangeKm(1), ...
    config.altitudePlotRangeKm(2),config.altitudePlotSamples).';
radiusKm = config.earthRadiusKm+altitudeKm;
speedKmPerSec = sqrt(config.muEarthKm3PerSec2./radiusKm);
gravitationalRate = config.muEarthKm3PerSec2/ ...
    config.speedOfLightKmPerSec^2.*((radiusKm-config.earthRadiusKm)./ ...
    (config.earthRadiusKm.*radiusKm));
kinematicRate = -0.5*(speedKmPerSec/config.speedOfLightKmPerSec).^2;
netRate = gravitationalRate+kinematicRate;
crossoverRadiusKm = 1.5*config.earthRadiusKm;
crossoverAltitudeKm = 0.5*config.earthRadiusKm;
crossover = struct();
crossover.altitudeKm = altitudeKm;
crossover.radiusKm = radiusKm;
crossover.gravitationalMicrosecondsPerDay = ...
    gravitationalRate*config.secondsPerDay*1e6;
crossover.kinematicMicrosecondsPerDay = ...
    kinematicRate*config.secondsPerDay*1e6;
crossover.netMicrosecondsPerDay = netRate*config.secondsPerDay*1e6;
crossover.radiusKmAnalytical = crossoverRadiusKm;
crossover.altitudeKmAnalytical = crossoverAltitudeKm;
crossover.assumptions = ...
    "Circular orbit; spherical nonrotating Earth; stationary surface clock; " + ...
    "leading weak-field gravitational and kinematic terms";
end

function verification = buildEllipticalVerification(config)
perigeeRadius = config.earthRadiusKm+config.ellipticalPerigeeAltitudeKm;
apogeeRadius = config.earthRadiusKm+config.ellipticalApogeeAltitudeKm;
semimajorAxis = 0.5*(perigeeRadius+apogeeRadius);
eccentricity = (apogeeRadius-perigeeRadius)/(apogeeRadius+perigeeRadius);
elements = struct('aKm',semimajorAxis,'e',eccentricity, ...
    'iDeg',config.ellipticalInclinationDeg,'raanDeg',0, ...
    'argPeriapsisDeg',0,'trueAnomalyDeg',0);
[position0,velocity0] = orbitalElementsToState( ...
    elements,config.muEarthKm3PerSec2);
periodSeconds = 2*pi*sqrt(semimajorAxis^3/config.muEarthKm3PerSec2);
elapsedSeconds = linspace(0,periodSeconds, ...
    config.ellipticalVerificationSamples).';
orbit = propagateTwoBody([position0;velocity0],elapsedSeconds, ...
    config.muEarthKm3PerSec2, ...
    RelativeTolerance=config.relativeTolerance, ...
    AbsoluteTolerance=config.absoluteTolerance, ...
    MaximumStep=config.maximumStepSeconds);
model = combinedRelativisticClockModel(orbit.position,orbit.velocity, ...
    elapsedSeconds,config.muEarthKm3PerSec2,config.earthRadiusKm, ...
    config.speedOfLightKmPerSec, ...
    ReferenceClockConvention=config.referenceClockConvention, ...
    CoordinateTimeConvention=config.coordinateTimeConvention);
meanInverseRadius = 1/semimajorAxis;
gravitationalAnalyticalSeconds = config.muEarthKm3PerSec2/ ...
    config.speedOfLightKmPerSec^2* ...
    (1/config.earthRadiusKm-meanInverseRadius)*periodSeconds;
kinematicAnalyticalSeconds = -config.muEarthKm3PerSec2/ ...
    (2*semimajorAxis*config.speedOfLightKmPerSec^2)*periodSeconds;
netAnalyticalSeconds = gravitationalAnalyticalSeconds+ ...
    kinematicAnalyticalSeconds;
verification = struct();
verification.semimajorAxisKm = semimajorAxis;
verification.eccentricity = eccentricity;
verification.periodSeconds = periodSeconds;
verification.positionKm = orbit.position;
verification.velocityKmPerSec = orbit.velocity;
verification.model = model;
verification.gravitationalAnalyticalSeconds = gravitationalAnalyticalSeconds;
verification.kinematicAnalyticalSeconds = kinematicAnalyticalSeconds;
verification.netAnalyticalSeconds = netAnalyticalSeconds;
verification.gravitationalIntegrationErrorSeconds = ...
    model.gravitational.accumulatedSeconds(end)-gravitationalAnalyticalSeconds;
verification.kinematicIntegrationErrorSeconds = ...
    model.kinematic.accumulatedApproximateSeconds(end)- ...
    kinematicAnalyticalSeconds;
verification.netIntegrationErrorSeconds = ...
    model.accumulatedNetApproximateSeconds(end)-netAnalyticalSeconds;
end
