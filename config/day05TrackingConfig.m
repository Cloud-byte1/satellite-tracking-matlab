function config = day05TrackingConfig()
%DAY05TRACKINGCONFIG Configure CelesTrak retrieval and cache behavior.

base = celesTrakConfig();
config = struct();
config.baseUrl = base.baseUrl;
config.format = "CSV";
config.timeZone = "UTC";
config.cacheRefreshHours = 2;
config.requestTimeoutSec = 30;
config.userAgent = "MATLAB-Orbital-Portfolio/Day5";
config.requiredFields = ["OBJECT_NAME", "NORAD_CAT_ID", "EPOCH", ...
    "INCLINATION", "ECCENTRICITY", "MEAN_MOTION"];
end
