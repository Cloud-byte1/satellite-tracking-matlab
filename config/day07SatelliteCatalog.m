function targets = day07SatelliteCatalog()
%DAY07SATELLITECATALOG Real spacecraft selected for model comparison.

MissionRole = ["Crewed LEO";"Navigation";"Navigation"; ...
    "Weather/Science";"Earth observation";"Geostationary weather"];
Constellation = ["ISS";"GPS";"GPS";"JPSS";"Landsat";"GOES"];
CatalogNumber = [25544;26407;27663;43013;49260;41866];
ExpectedNamePattern = ["ISS";"NAVSTAR|GPS";"NAVSTAR|GPS"; ...
    "NOAA 20|JPSS";"LANDSAT 9";"GOES 16"];
Regime = ["LEO";"MEO";"MEO";"LEO";"LEO";"GEO"];

targets = table(MissionRole,Constellation,CatalogNumber, ...
    ExpectedNamePattern,Regime);
end
