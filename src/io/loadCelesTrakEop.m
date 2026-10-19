function eop = loadCelesTrakEop(fileName)
%LOADCELESTRAKEOP Read and validate CelesTrak Earth-orientation parameters.

arguments
    fileName (1,1) string
end

if ~isfile(fileName)
    error('loadCelesTrakEop:MissingFile','Missing EOP file: %s.',fileName);
end
raw = readtable(fileName,'TextType','string','VariableNamingRule','preserve');
required = ["DATE","DPSI","DEPS","DAT","DATA_TYPE"];
missing = setdiff(required,string(raw.Properties.VariableNames));
if ~isempty(missing)
    error('loadCelesTrakEop:MissingFields','Missing EOP fields: %s.', ...
        strjoin(cellstr(missing),', '));
end

if isdatetime(raw.DATE)
    dateUtc = raw.DATE;
else
    dateUtc = datetime(raw.DATE,'InputFormat','yyyy-MM-dd');
end
dateUtc.TimeZone = 'UTC';
if any(diff(dateUtc) <= seconds(0)) || any(~isfinite(raw.DPSI)) || ...
        any(~isfinite(raw.DEPS)) || any(~isfinite(raw.DAT))
    error('loadCelesTrakEop:InvalidData', ...
        'EOP dates must increase and required numeric fields must be finite.');
end

eop = table(dateUtc,double(raw.DPSI),double(raw.DEPS),double(raw.DAT), ...
    string(raw.DATA_TYPE),'VariableNames', ...
    {'DateUtc','DeltaPsiArcsec','DeltaEpsilonArcsec', ...
    'TaiMinusUtcSeconds','DataType'});
end
