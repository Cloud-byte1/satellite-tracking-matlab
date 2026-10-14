function url = buildCelesTrakGpUrl(queryName, queryValue, format, baseUrl)
%BUILDCELESTRAKGPURL Construct a documented CelesTrak GP query URL.
%   URL = BUILDCELESTRAKGPURL(NAME, VALUE, FORMAT, BASEURL) supports the
%   CATNR and GROUP query types used by the Day 2 pipeline.

arguments
    queryName (1,1) string {mustBeMember(queryName, ["CATNR", "GROUP"])}
    queryValue (1,1) string
    format (1,1) string {mustBeMember(format, ["CSV", "JSON", "TLE"])}
    baseUrl (1,1) string
end

if strlength(strtrim(queryValue)) == 0
    error('buildCelesTrakGpUrl:EmptyQueryValue', ...
        'The CelesTrak query value cannot be empty.');
end

url = baseUrl + "?" + queryName + "=" + queryValue + "&FORMAT=" + format;
end

