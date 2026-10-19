function controls = createDay08VisibilityControls(viewer,satellites,analysis,options)
%CREATEDAY08VISIBILITYCONTROLS Add per-satellite visibility toggles.

arguments
    viewer
    satellites
    analysis (1,1) struct
    options.ShowGroundTracks (1,1) logical = true
end

count = numel(satellites);
if count ~= analysis.scenarioCount
    error('createDay08VisibilityControls:CountMismatch', ...
        'The satellite count must match the Day 8 scenario count.');
end

controlFigure = uifigure('Name','Day 8 Satellite Visibility', ...
    'Position',[80 120 520 450]);
layout = uigridlayout(controlFigure,[count+3 2]);
layout.ColumnWidth = {'1x',150};
layout.RowHeight = [34 36 26 repmat(28,1,count)];
layout.Padding = [12 10 12 10];

titleLabel = uilabel(layout,'Text','Day 8 — choose what appears on the globe', ...
    'FontWeight','bold','FontSize',15);
titleLabel.Layout.Row = 1;
titleLabel.Layout.Column = [1 2];

buttonLayout = uigridlayout(layout,[1 4]);
buttonLayout.Layout.Row = 2;
buttonLayout.Layout.Column = [1 2];
buttonLayout.ColumnWidth = {'1x','1x','1x','1x'};
buttonLayout.Padding = [0 0 0 0];
buttonLayout.ColumnSpacing = 7;
allButton = uibutton(buttonLayout,'Text','All', ...
    'ButtonPushedFcn',@(~,~) setGroup("all"));
realButton = uibutton(buttonLayout,'Text','Real only', ...
    'ButtonPushedFcn',@(~,~) setGroup("real"));
theoreticalButton = uibutton(buttonLayout,'Text','Theoretical only', ...
    'ButtonPushedFcn',@(~,~) setGroup("theoretical"));
noneButton = uibutton(buttonLayout,'Text','None', ...
    'ButtonPushedFcn',@(~,~) setGroup("none"));

nameHeader = uilabel(layout,'Text','Satellite / orbit','FontWeight','bold');
nameHeader.Layout.Row = 3;
nameHeader.Layout.Column = 1;
driftHeader = uilabel(layout,'Text','SR clock drift','FontWeight','bold', ...
    'HorizontalAlignment','right');
driftHeader.Layout.Row = 3;
driftHeader.Layout.Column = 2;

checkBoxes = gobjects(count,1);
for index = 1:count
    history = analysis.histories(index);
    label = history.name+"  ["+history.regime+"]";
    checkBoxes(index) = uicheckbox(layout,'Text',label,'Value',true, ...
        'ValueChangedFcn',@(~,event) setOne(index,event.Value));
    checkBoxes(index).Layout.Row = index+3;
    checkBoxes(index).Layout.Column = 1;
    if index > analysis.realSatelliteCount
        checkBoxes(index).FontWeight = 'bold';
        checkBoxes(index).FontColor = [0.45 0.15 0.70];
    end
    drift = analysis.summary.IntegratedDrift24HoursMicroseconds(index);
    driftLabel = uilabel(layout,'Text',sprintf('%+.3f microseconds/day',drift), ...
        'HorizontalAlignment','right');
    driftLabel.Layout.Row = index+3;
    driftLabel.Layout.Column = 2;
end

controls = struct('Figure',controlFigure,'CheckBoxes',checkBoxes, ...
    'AllButton',allButton,'RealButton',realButton, ...
    'TheoreticalButton',theoreticalButton,'NoneButton',noneButton, ...
    'SetGroup',@setGroup,'SetOne',@setOne);

    function setGroup(group)
        realIndices = 1:analysis.realSatelliteCount;
        theoreticalIndices = analysis.realSatelliteCount+1:count;
        switch string(group)
            case "all"
                visible = true(count,1);
            case "real"
                visible = false(count,1);
                visible(realIndices) = true;
            case "theoretical"
                visible = false(count,1);
                visible(theoreticalIndices) = true;
            case "none"
                visible = false(count,1);
            otherwise
                error('createDay08VisibilityControls:UnknownGroup', ...
                    'Unknown visibility group: %s',string(group));
        end
        for item = 1:count
            checkBoxes(item).Value = visible(item);
            setOne(item,visible(item));
        end
        drawnow limitrate
    end

    function setOne(index,isVisible)
        if isVisible
            show(satellites(index),viewer);
            show(satellites(index).Orbit,viewer);
            if options.ShowGroundTracks
                show(satellites(index).GroundTrack,viewer);
            end
        else
            hide(satellites(index),viewer);
            hide(satellites(index).Orbit,viewer);
            hide(satellites(index).GroundTrack,viewer);
        end
    end
end
