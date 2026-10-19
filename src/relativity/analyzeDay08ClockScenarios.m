function analysis = analyzeDay08ClockScenarios(comparison,catalog,config)
%ANALYZEDAY08CLOCKSCENARIOS Evaluate real and theoretical clock histories.

arguments
    comparison (1,1) struct
    catalog (:,:) table
    config (1,1) struct
end

elapsedSeconds = comparison.elapsedSeconds(:);
if abs(elapsedSeconds(end)-config.durationSeconds)>1e-9
    error('analyzeDay08ClockScenarios:DurationMismatch', ...
        'Day 7 input must span exactly the configured Day 8 duration.');
end
if ~contains(string(comparison.referenceFrame),"J2000/FK5")
    error('analyzeDay08ClockScenarios:FrameMismatch', ...
        'Day 8 requires the verified J2000/FK5 velocity histories.');
end

realCount = height(catalog);
scenarioCount = realCount+3;
template = struct('name',"",'source',"",'regime',"", ...
    'elapsedSeconds',[],'positionKm',[],'velocityKmPerSec',[], ...
    'radiusKm',[],'altitudeKm',[],'trueAnomalyDeg',[], ...
    'orbitalPeriodHours',NaN,'perigeeAltitudeKm',NaN, ...
    'apogeeAltitudeKm',NaN,'clock',struct());
histories = repmat(template,scenarioCount,1);

for satellite = 1:realCount
    position = comparison.positionSgp4J2000Km(:,:,satellite);
    velocity = comparison.velocitySgp4J2000KmPerSec(:,:,satellite);
    histories(satellite) = makeHistory(catalog.SatelliteName(satellite), ...
        "Real CelesTrak SGP4",catalog.Regime(satellite),elapsedSeconds, ...
        position,velocity,nan(size(elapsedSeconds)),config);
end

index = realCount+1;
histories(index) = makeCircularHistory("Theoretical 500 km circular LEO", ...
    "LEO",config.circularLeoAltitudeKm,elapsedSeconds,config);
index = index+1;
histories(index) = makeCircularHistory("Theoretical GPS 20,200 km circular", ...
    "MEO",config.gpsAltitudeKm,elapsedSeconds,config);
index = index+1;
[histories(index),ellipticalVerification] = makeEllipticalHistory( ...
    elapsedSeconds,config);

summary = buildSummary(histories);
timeSeries = buildTimeSeries(histories);
gpsRow = summary.ScenarioName=="Theoretical GPS 20,200 km circular";
analysis = struct();
analysis.histories = histories;
analysis.summary = summary;
analysis.timeSeries = timeSeries;
analysis.gpsBenchmark = summary(gpsRow,:);
analysis.ellipticalVerification = ellipticalVerification;
analysis.coordinateTimeConvention = config.coordinateTimeConvention;
analysis.referenceFrame = config.referenceFrame;
analysis.realSatelliteCount = realCount;
analysis.scenarioCount = scenarioCount;
end

function history = makeCircularHistory(name,regime,altitudeKm,time,config)
radiusKm = config.earthRadiusKm+altitudeKm;
speedKmPerSec = sqrt(config.muEarthKm3PerSec2/radiusKm);
meanMotion = speedKmPerSec/radiusKm;
phase = meanMotion*time;
position = radiusKm*[cos(phase) sin(phase) zeros(size(phase))];
velocity = speedKmPerSec*[-sin(phase) cos(phase) zeros(size(phase))];
history = makeHistory(name,"Theoretical two-body",regime,time, ...
    position,velocity,mod(rad2deg(phase),360),config);
history.orbitalPeriodHours = 2*pi/meanMotion/3600;
history.perigeeAltitudeKm = altitudeKm;
history.apogeeAltitudeKm = altitudeKm;
end

function [history,verification] = makeEllipticalHistory(time,config)
perigeeRadius = config.earthRadiusKm+config.ellipticalPerigeeAltitudeKm;
apogeeRadius = config.earthRadiusKm+config.ellipticalApogeeAltitudeKm;
semimajorAxis = 0.5*(perigeeRadius+apogeeRadius);
eccentricity = (apogeeRadius-perigeeRadius)/(apogeeRadius+perigeeRadius);
elements = struct('aKm',semimajorAxis,'e',eccentricity, ...
    'iDeg',config.ellipticalInclinationDeg,'raanDeg',0, ...
    'argPeriapsisDeg',0,'trueAnomalyDeg',0);
[position0,velocity0] = orbitalElementsToState( ...
    elements,config.muEarthKm3PerSec2);
solution = propagateTwoBody([position0;velocity0],time, ...
    config.muEarthKm3PerSec2, ...
    RelativeTolerance=config.relativeTolerance, ...
    AbsoluteTolerance=config.absoluteTolerance, ...
    MaximumStep=config.maximumStepSeconds);
trueAnomaly = calculateTrueAnomaly(solution.position,solution.velocity, ...
    semimajorAxis,eccentricity,config.muEarthKm3PerSec2);
history = makeHistory("Theoretical elliptical 500 x 20,200 km", ...
    "Theoretical two-body","Elliptical",time,solution.position, ...
    solution.velocity,trueAnomaly,config);
orbitalPeriodSeconds = 2*pi*sqrt(semimajorAxis^3/ ...
    config.muEarthKm3PerSec2);
history.orbitalPeriodHours = orbitalPeriodSeconds/3600;
history.perigeeAltitudeKm = config.ellipticalPerigeeAltitudeKm;
history.apogeeAltitudeKm = config.ellipticalApogeeAltitudeKm;

verificationTime = linspace(0,orbitalPeriodSeconds, ...
    config.ellipticalVerificationSamples).';
verificationOrbit = propagateTwoBody([position0;velocity0], ...
    verificationTime,config.muEarthKm3PerSec2, ...
    RelativeTolerance=config.relativeTolerance, ...
    AbsoluteTolerance=config.absoluteTolerance, ...
    MaximumStep=config.maximumStepSeconds);
verificationClock = specialRelativisticClockModel( ...
    verificationOrbit.velocity,verificationTime, ...
    config.speedOfLightKmPerSec, ...
    CoordinateTimeConvention=config.coordinateTimeConvention);
analyticalApproximateSeconds = -config.muEarthKm3PerSec2/ ...
    (2*semimajorAxis*config.speedOfLightKmPerSec^2)*orbitalPeriodSeconds;
verification = struct();
verification.semimajorAxisKm = semimajorAxis;
verification.eccentricity = eccentricity;
verification.orbitalPeriodSeconds = orbitalPeriodSeconds;
verification.perigeeSpeedKmPerSec = norm(velocity0);
verification.apogeeSpeedKmPerSec = sqrt(config.muEarthKm3PerSec2* ...
    (2/apogeeRadius-1/semimajorAxis));
verification.perigeeRateCorrection = ...
    history.clock.exactClockRateCorrection(1);
[~,apogeeIndex] = max(history.radiusKm( ...
    history.elapsedSeconds<=orbitalPeriodSeconds));
verification.apogeeRateCorrection = ...
    history.clock.exactClockRateCorrection(apogeeIndex);
verification.numericalApproximateSeconds = ...
    verificationClock.accumulatedApproximateSeconds(end);
verification.numericalExactSeconds = ...
    verificationClock.accumulatedExactSeconds(end);
verification.analyticalApproximateSeconds = analyticalApproximateSeconds;
verification.integrationErrorSeconds = ...
    verification.numericalApproximateSeconds-analyticalApproximateSeconds;
verification.relativeIntegrationError = abs(verification.integrationErrorSeconds/ ...
    analyticalApproximateSeconds);
end

function history = makeHistory(name,source,regime,time,position,velocity, ...
    trueAnomaly,config)
radius = vecnorm(position,2,2);
altitude = radius-config.earthRadiusKm;
clock = specialRelativisticClockModel(velocity,time, ...
    config.speedOfLightKmPerSec, ...
    CoordinateTimeConvention=config.coordinateTimeConvention);
specificEnergy = 0.5*sum(velocity(1,:).^2)- ...
    config.muEarthKm3PerSec2/radius(1);
if specificEnergy<0
    semimajorAxis = -config.muEarthKm3PerSec2/(2*specificEnergy);
    orbitalPeriodHours = 2*pi*sqrt(semimajorAxis^3/ ...
        config.muEarthKm3PerSec2)/3600;
else
    orbitalPeriodHours = NaN;
end
history = struct('name',string(name),'source',string(source), ...
    'regime',string(regime),'elapsedSeconds',time, ...
    'positionKm',position,'velocityKmPerSec',velocity, ...
    'radiusKm',radius,'altitudeKm',altitude, ...
    'trueAnomalyDeg',trueAnomaly,'orbitalPeriodHours',orbitalPeriodHours, ...
    'perigeeAltitudeKm',min(altitude), ...
    'apogeeAltitudeKm',max(altitude),'clock',clock);
end

function trueAnomaly = calculateTrueAnomaly(position,velocity,a,e,mu)
radius = vecnorm(position,2,2);
radialVelocity = sum(position.*velocity,2)./radius;
parameter = a*(1-e^2);
cosine = (parameter./radius-1)/e;
sine = radialVelocity*sqrt(mu*parameter)/(mu*e);
cosine = min(1,max(-1,cosine));
sine = min(1,max(-1,sine));
trueAnomaly = mod(atan2d(sine,cosine),360);
end

function summary = buildSummary(histories)
count = numel(histories);
ScenarioName = strings(count,1); Source = strings(count,1);
Regime = strings(count,1); MeanAltitudeKm = zeros(count,1);
PerigeeAltitudeKm = zeros(count,1); ApogeeAltitudeKm = zeros(count,1);
MeanSpeedKmPerSec = zeros(count,1); MinimumSpeedKmPerSec = zeros(count,1);
MaximumSpeedKmPerSec = zeros(count,1); OrbitalPeriodHours = zeros(count,1);
InitialClockRateCorrection = zeros(count,1); MeanClockRateCorrection = zeros(count,1);
InitialDriftMicrosecondsPerDay = zeros(count,1);
IntegratedDrift24HoursMicroseconds = zeros(count,1);
ApproximateDrift24HoursMicroseconds = zeros(count,1);
EquivalentDriftMicrosecondsPerDay = zeros(count,1);
ExactApproxDifferencePicoseconds = zeros(count,1);
MaximumRateFormulaDifference = zeros(count,1);
for index = 1:count
    history = histories(index); clock = history.clock;
    ScenarioName(index) = history.name; Source(index) = history.source;
    Regime(index) = history.regime;
    MeanAltitudeKm(index) = mean(history.altitudeKm);
    PerigeeAltitudeKm(index) = history.perigeeAltitudeKm;
    ApogeeAltitudeKm(index) = history.apogeeAltitudeKm;
    MeanSpeedKmPerSec(index) = mean(clock.speedKmPerSec);
    MinimumSpeedKmPerSec(index) = min(clock.speedKmPerSec);
    MaximumSpeedKmPerSec(index) = max(clock.speedKmPerSec);
    OrbitalPeriodHours(index) = history.orbitalPeriodHours;
    InitialClockRateCorrection(index) = clock.exactClockRateCorrection(1);
    MeanClockRateCorrection(index) = clock.accumulatedExactSeconds(end)/ ...
        history.elapsedSeconds(end);
    InitialDriftMicrosecondsPerDay(index) = ...
        clock.instantaneousExactMicrosecondsPerDay(1);
    IntegratedDrift24HoursMicroseconds(index) = ...
        clock.accumulatedExactMicroseconds(end);
    ApproximateDrift24HoursMicroseconds(index) = ...
        clock.accumulatedApproximateMicroseconds(end);
    EquivalentDriftMicrosecondsPerDay(index) = ...
        clock.equivalentExactMicrosecondsPerDay;
    ExactApproxDifferencePicoseconds(index) = ...
        (clock.accumulatedExactSeconds(end)- ...
        clock.accumulatedApproximateSeconds(end))*1e12;
    MaximumRateFormulaDifference(index) = max(abs( ...
        clock.exactClockRateCorrection-clock.approximateClockRateCorrection));
end
summary = table(ScenarioName,Source,Regime,MeanAltitudeKm, ...
    PerigeeAltitudeKm,ApogeeAltitudeKm,MeanSpeedKmPerSec, ...
    MinimumSpeedKmPerSec,MaximumSpeedKmPerSec,OrbitalPeriodHours, ...
    InitialClockRateCorrection,MeanClockRateCorrection, ...
    InitialDriftMicrosecondsPerDay,IntegratedDrift24HoursMicroseconds, ...
    ApproximateDrift24HoursMicroseconds,EquivalentDriftMicrosecondsPerDay, ...
    ExactApproxDifferencePicoseconds,MaximumRateFormulaDifference);
end

function timeSeries = buildTimeSeries(histories)
scenarioCount = numel(histories);
sampleCount = numel(histories(1).elapsedSeconds);
rows = scenarioCount*sampleCount;
ScenarioName = strings(rows,1); Source = strings(rows,1);
Regime = strings(rows,1); ElapsedHours = zeros(rows,1);
AltitudeKm = zeros(rows,1); SpeedKmPerSec = zeros(rows,1);
ExactClockRateCorrection = zeros(rows,1);
ApproximateClockRateCorrection = zeros(rows,1);
InstantaneousDriftMicrosecondsPerDay = zeros(rows,1);
AccumulatedExactMicroseconds = zeros(rows,1);
AccumulatedApproximateMicroseconds = zeros(rows,1);
TrueAnomalyDeg = nan(rows,1);
for index = 1:scenarioCount
    range = (index-1)*sampleCount+(1:sampleCount);
    history = histories(index); clock = history.clock;
    ScenarioName(range) = history.name; Source(range) = history.source;
    Regime(range) = history.regime;
    ElapsedHours(range) = history.elapsedSeconds/3600;
    AltitudeKm(range) = history.altitudeKm;
    SpeedKmPerSec(range) = clock.speedKmPerSec;
    ExactClockRateCorrection(range) = clock.exactClockRateCorrection;
    ApproximateClockRateCorrection(range) = clock.approximateClockRateCorrection;
    InstantaneousDriftMicrosecondsPerDay(range) = ...
        clock.instantaneousExactMicrosecondsPerDay;
    AccumulatedExactMicroseconds(range) = clock.accumulatedExactMicroseconds;
    AccumulatedApproximateMicroseconds(range) = ...
        clock.accumulatedApproximateMicroseconds;
    TrueAnomalyDeg(range) = history.trueAnomalyDeg;
end
timeSeries = table(ScenarioName,Source,Regime,ElapsedHours,AltitudeKm, ...
    SpeedKmPerSec,ExactClockRateCorrection,ApproximateClockRateCorrection, ...
    InstantaneousDriftMicrosecondsPerDay,AccumulatedExactMicroseconds, ...
    AccumulatedApproximateMicroseconds,TrueAnomalyDeg);
end
