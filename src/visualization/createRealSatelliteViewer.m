function figureHandle = createRealSatelliteViewer(simulation, earthRadiusKm)
%CREATEREALSATELLITEVIEWER Interactive five-satellite TEME animation.
%   The viewer provides play/pause, a timeline slider, playback speed, and native
%   MATLAB 3D rotation/zoom. Earth is centered in TEME; no ECEF map is implied.

arguments
    simulation (1,1) struct
    earthRadiusKm (1,1) double {mustBePositive, mustBeFinite}
end

colors = lines(numel(simulation.catalogIds));
figureHandle = figure('Color','white', 'Name', ...
    'Real Satellite SGP4 Simulation (TEME)', 'Position',[60 60 1380 850]);
axesHandle = axes(figureHandle, 'Position',[0.06 0.11 0.73 0.82]);
hold(axesHandle,'on');
set(axesHandle,'Color','white','XColor',[0.15 0.15 0.15], ...
    'YColor',[0.15 0.15 0.15],'ZColor',[0.15 0.15 0.15], ...
    'GridColor',[0.72 0.72 0.72],'GridAlpha',0.45);

[earthX,earthY,earthZ] = sphere(100);
earthSurface = surf(axesHandle, earthRadiusKm*earthX, earthRadiusKm*earthY, ...
    earthRadiusKm*earthZ, 'FaceColor',[0.10 0.36 0.62], ...
    'EdgeColor','none','FaceAlpha',0.86,'DisplayName','Earth');
satelliteCount = numel(simulation.catalogIds);
pathHandles = gobjects(satelliteCount,1);
markerHandles = gobjects(satelliteCount,1);
labelHandles = gobjects(satelliteCount,1);
maximumRadius = earthRadiusKm;

for index = 1:satelliteCount
    position = simulation.positionTemeKm(:,:,index);
    maximumRadius = max(maximumRadius,max(vecnorm(position,2,2)));
    pathHandles(index) = plot3(axesHandle,position(:,1),position(:,2),position(:,3), ...
        '-','Color',colors(index,:),'LineWidth',1.25, ...
        'DisplayName',simulation.satelliteNames(index));
    markerHandles(index) = plot3(axesHandle,position(1,1),position(1,2),position(1,3), ...
        'o','Color',colors(index,:),'MarkerFaceColor',colors(index,:), ...
        'MarkerSize',8,'HandleVisibility','off');
    labelHandles(index) = text(axesHandle,position(1,1),position(1,2),position(1,3), ...
        "  " + simulation.satelliteNames(index),'Color',colors(index,:), ...
        'FontSize',8,'FontWeight','bold','HandleVisibility','off');
end

axis(axesHandle,'equal'); grid(axesHandle,'on'); box(axesHandle,'on');
limit = 1.08*maximumRadius;
xlim(axesHandle,[-limit limit]); ylim(axesHandle,[-limit limit]);
zlim(axesHandle,[-limit limit]);
xlabel(axesHandle,'TEME x (km)'); ylabel(axesHandle,'TEME y (km)');
zlabel(axesHandle,'TEME z (km)'); view(axesHandle,35,24);
camlight(axesHandle,'headlight'); lighting(axesHandle,'gouraud');
legend(axesHandle,[earthSurface;pathHandles],'Location','eastoutside');

sampleCount = numel(simulation.timeUtc);
playButton = uicontrol(figureHandle,'Style','togglebutton','String','Play', ...
    'Units','normalized','Position',[0.08 0.025 0.08 0.045], ...
    'Callback',@playCallback);
sliderHandle = uicontrol(figureHandle,'Style','slider','Min',1,'Max',sampleCount, ...
    'Value',1,'SliderStep',[1/max(1,sampleCount-1),10/max(1,sampleCount-1)], ...
    'Units','normalized','Position',[0.18 0.03 0.47 0.035], ...
    'Callback',@sliderCallback);
speedMenu = uicontrol(figureHandle,'Style','popupmenu', ...
    'String',{'1x','2x','5x','10x'},'Value',2,'Units','normalized', ...
    'Position',[0.67 0.026 0.08 0.043]);
timeLabel = uicontrol(figureHandle,'Style','text','BackgroundColor','white', ...
    'HorizontalAlignment','left','Units','normalized', ...
    'Position',[0.77 0.025 0.21 0.045]);
rotate3d(figureHandle,'on');
updateFrame(1);

    function sliderCallback(~,~)
        updateFrame(round(sliderHandle.Value));
    end

    function playCallback(~,~)
        if playButton.Value
            playButton.String = 'Pause';
        end
        frameSteps = [1 2 5 10];
        while isvalid(figureHandle) && playButton.Value
            nextIndex = round(sliderHandle.Value) + frameSteps(speedMenu.Value);
            if nextIndex > sampleCount
                nextIndex = 1;
            end
            sliderHandle.Value = nextIndex;
            updateFrame(nextIndex);
            drawnow;
            pause(0.035);
        end
        if isvalid(figureHandle)
            playButton.String = 'Play';
        end
    end

    function updateFrame(frameIndex)
        for satellite = 1:satelliteCount
            position = simulation.positionTemeKm(frameIndex,:,satellite);
            set(markerHandles(satellite),'XData',position(1), ...
                'YData',position(2),'ZData',position(3));
            set(labelHandles(satellite),'Position',position);
        end
        timestamp = string(simulation.timeUtc(frameIndex), ...
            "yyyy-MM-dd HH:mm:ss 'UTC'");
        titleHandle = title(axesHandle,{ ...
            'Five Real Satellites — SGP4 in TEME', ...
            char(timestamp + " | drag to rotate, scroll to zoom")});
        set(titleHandle,'Color',[0.10 0.10 0.10],'FontWeight','bold');
        timeLabel.String = sprintf('Frame %d/%d\n%s', ...
            frameIndex,sampleCount,timestamp);
    end
end
