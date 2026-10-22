function app = launchSatelliteTracker(options)
%LAUNCHSATELLITETRACKER Compatibility entry point for Satellite Observer.

arguments
    options.Visible (1,1) logical = true
end

app = launchSatelliteObserver(Visible=options.Visible);
end
