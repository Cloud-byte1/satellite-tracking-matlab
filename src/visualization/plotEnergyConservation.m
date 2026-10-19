function figureHandle = plotEnergyConservation(records)
%PLOTENERGYCONSERVATION Plot relative energy drift versus simulation time.
%   RECORDS contains scenario and energy fields from the Day 4 Task 1 runner.

arguments
    records (:,1) struct
end

figureHandle = figure('Color', 'white', 'Name', ...
    'Day 4 Specific Orbital Energy Conservation', ...
    'Position', [60 60 1380 820]);
layout = tiledlayout(figureHandle, 2, 3, ...
    'TileSpacing', 'compact', 'Padding', 'compact');

for index = 1:numel(records)
    axesHandle = nexttile(layout);
    analysis = records(index).energy;
    scenario = records(index).scenario;
    elapsedHours = analysis.timeSec/3600;
    plotValue = max(analysis.relativeDeviation, eps);
    semilogy(axesHandle, elapsedHours, plotValue, '-', ...
        'Color', scenario.color, 'LineWidth', 1.5);
    grid(axesHandle, 'on');
    box(axesHandle, 'on');
    set(axesHandle, 'Color', 'white', 'XColor', [0.15 0.15 0.15], ...
        'YColor', [0.15 0.15 0.15], 'GridColor', [0.72 0.72 0.72], ...
        'GridAlpha', 0.45, 'FontName', 'Arial', 'FontSize', 9);
    xlabel(axesHandle, 'Elapsed time (h)');
    ylabel(axesHandle, '|\epsilon(t)-\epsilon_0| / |\epsilon_0|');
    titleHandle = title(axesHandle, {scenario.name, sprintf( ...
        'E_0 = %.6f km^2/s^2, max drift = %.3e', ...
        analysis.initialEnergyKm2PerSec2, analysis.maxRelativeDrift)});
    set(titleHandle, 'Color', [0.10 0.10 0.10], 'FontSize', 10);
end

titleHandle = title(layout, { ...
    'Specific Orbital Energy Conservation — ode45 Two-Body Model', ...
    'Relative drift from each scenario''s initial energy'});
set(titleHandle, 'Color', [0.10 0.10 0.10], 'FontWeight', 'bold');
end
