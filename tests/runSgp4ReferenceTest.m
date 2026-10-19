function report = runSgp4ReferenceTest(valladoDirectory)
%RUNSGP4REFERENCETEST Compare the included Vallado case at epoch.

arguments
    valladoDirectory (1,1) string
end

tleFile = fullfile(valladoDirectory,'SGP4-VER.TLE');
fileId = fopen(tleFile,'r');
if fileId < 0
    error('runSgp4ReferenceTest:FileOpenFailed','Cannot open %s.',tleFile);
end
cleanup = onCleanup(@() fclose(fileId));
fgetl(fileId); fgetl(fileId);
line1 = fgetl(fileId);
line2 = fgetl(fileId);
% The legacy verification parser reads columns 97:105. Some unzip/text
% pipelines omit the source file's final padding space, so restore it in
% memory without modifying the published reference data.
line2 = [line2 repmat(' ',1,max(0,105-numel(line2)))];
[~,~,~,satrec] = twoline2rv(line1,line2,'v','m','a',72);
[satrec,position,velocity] = sgp4(satrec,0);

expectedPositionKm = [7022.46529266,-1400.08296755,0.03995155];
expectedVelocityKmPerSec = [1.893841015,6.405893759,4.534807250];
positionErrorKm = norm(position-expectedPositionKm);
velocityErrorKmPerSec = norm(velocity-expectedVelocityKmPerSec);
testName = ["Vallado epoch position";"Vallado epoch velocity";"SGP4 error code"];
measuredValue = [positionErrorKm;velocityErrorKmPerSec;satrec.error];
tolerance = [1e-8;1e-9;0];
unit = ["km";"km/s";"code"];
passed = measuredValue <= tolerance;
results = table(testName,measuredValue,tolerance,unit,passed, ...
    'VariableNames',{'Test','MeasuredValue','Tolerance','Unit','Passed'});
report = struct('results',results,'passedTests',sum(passed), ...
    'totalTests',height(results),'allPassed',all(passed));
if ~report.allPassed
    error('runSgp4ReferenceTest:VerificationFailure', ...
        'The Vallado SGP4 reference case did not match expected output.');
end
end
