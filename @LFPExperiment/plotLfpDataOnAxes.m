function plotLfpDataOnAxes(obj, axesHandle)
    % Description:
    % This method plots the LFP data from the specified tetrodes on the
    % provided axes handle.

    disp("Plotting...")
    % Check if the object has been initialized with data
    if isempty(obj.lfp_data) || isempty(obj.time_vec) || obj.sf == 0
        error('Error plotting data: LFPExperiment object is not initialized. Please call loadData first.');
    end

    cla(axesHandle, 'reset');

    % Plot the LFP data for all N tetrodes
    hold(axesHandle, 'on');

    % Determine non-empty tetrode numbers
    tetrodeNumbers = find(~cellfun(@isempty, obj.lfp_data));  % Find indices of non-empty cells

    % Check if the LFP data is a cell array (multi-tetrode case)
    for i = 1:length(tetrodeNumbers)
        tetrode = tetrodeNumbers(i);
        
        % Get the current LFP data and apply the offset
        current_lfp_data = obj.lfp_data{tetrode};
        offset_data = current_lfp_data + (i - 1) * obj.yOffset;
        
        % Plot the data with the offset
        plot(axesHandle, obj.time_vec, offset_data);

        % Add a dotted red line at y = 0
        yline(axesHandle, 0, 'r--', 'LineWidth', 1);

        % Set the y-axis ticks to show amplitude values
        set(axesHandle, 'YTickMode', 'auto');  % Enable Y ticks to show amplitude

        % Plot FIR filtered waveform in orange
        %plot(axesHandle, obj.time_vec, obj.lfp_fir_filtered{i}, 'Color', [1 0.5 0], 'LineWidth', 1.5);  % Orange - FIR filtered trace

        % Plot the shaded area under the envelope: Dont do this. It takes
        % too long for the entire thing
        %fill(axesHandle, [obj.time_vec, fliplr(obj.time_vec)], ...
        %     [obj.lfp_amp_envelope{i}, fliplr(zeros(size(obj.lfp_amp_envelope{i})))], ...
        %     [0.3 1 0.3], 'FaceAlpha', 0.3, 'EdgeColor', 'none');  % Green shaded area
        
        % Plot the zero crossings using scatter, with obj.time_vec on the x-axis
        %scatter(axesHandle, obj.time_vec(obj.lfp_zero_crossings{i}), ...
        %        obj.lfp_fir_filtered{i}(obj.lfp_zero_crossings{i}), ...
        %        50, 'r', 'filled');  % Red dots for zero crossings

    end


    % Set plot title, labels, and legend
    title(axesHandle, 'LFP Data from Selected Tetrodes');
    xlabel(axesHandle, 'Time (s)');
    ylabel(axesHandle, 'Amplitude');

    % Only remove Y ticks for multi-tetrode case
    %if iscell(obj.lfp_data)
    %    set(axesHandle, 'YTick', []);
    %end

    % Set the x-axis limits from 0 to the total time of the experiment
    xlim(axesHandle, [0, obj.total_time]);
    
    % Generate legend labels and add a legend if there are multiple tetrodes
    legendLabels = arrayfun(@(x) sprintf('Tetrode %d', x), tetrodeNumbers, 'UniformOutput', false);
    legend(axesHandle, legendLabels);
    %legend(axesHandle, 'Raw Trace', 'FIR - Filtered Trace', 'Oscillation Amplitude', 'Zero Crossings');
    % Turn hold off after plotting
    hold(axesHandle, 'off');
end