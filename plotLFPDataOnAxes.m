function plotLFPDataOnAxes(axesHandle, lfpData, timeVec, startX, endX, yOffset, tetrodeNumbers)
    % Clear previous plots on the specified axes
    cla(axesHandle);

    % Plot the LFP data for all 7 tetrodes
    hold(axesHandle, 'on');  % Keep adding plots to the same axes
    
    for i = 1:length(tetrodeNumbers)
        tetrode = tetrodeNumbers(i);  % Get the current tetrode number to plot
        current_lfp_data = lfpData{tetrode};  % Access LFP data for the current tetrode
         
        % Apply an offset to show nice vertical stack
        offset_data = current_lfp_data + (i - 1) * yOffset;
        
        % Plot each tetrode's LFP data with the offset
        plot(axesHandle, timeVec, offset_data);   
    end
    
    % Set plot title, labels, and legend

    title(axesHandle, 'LFP Data from Selected Tetrodes');
    xlabel(axesHandle, 'Time (s)');
    ylabel(axesHandle, 'Amplitude');
    set(axesHandle, 'YTick', []);  % empty Y ticks so they dont show up. Bc they dont make sense with many tetrodes on 1 plot

    % Set the x-axis limits based on app input (startX, endX)
    xlim(axesHandle, [startX, endX]);


legendLabels = arrayfun(@(x) sprintf('Tetrode %d', x), tetrodeNumbers, 'UniformOutput', false);    hold(axesHandle, 'off');  % Turn hold off after plotting
legend(axesHandle, legendLabels);
    
hold(axesHandle, 'off');  % Turn hold off after plotting

end