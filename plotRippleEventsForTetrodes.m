function plotRippleEventsForTetrodes(axesHandle, experiment_obj, yOffset)
    % Parameters
    box_height = yOffset;  % Height of each box
    Fs = experiment_obj.sampling_freq;  % Sampling frequency

    % Loop through each tetrode
    for tetrode_num = 1:experiment_obj.num_tetrodes
        % Get the array of SWR_Event objects for the current tetrode
        swr_events = experiment_obj.swr_events{tetrode_num};
        num_ripples = length(swr_events);  % Number of detected ripple events
        
        %fprintf('Number of ripple events detected: %d in tetrode: %d\n', num_ripples, tetrode_num);
        
        % Loop through each detected ripple event and plot the box
        y_offset_tetrode = (tetrode_num - 1) * yOffset;  % Offset used for plotting the LFP signal
        for i = 1:num_ripples
            % Get the current SWR_Event object
            ripple_event = swr_events(i);
            
            % Extract the start and end times of the ripple event (in samples)
            event_start = ripple_event.ES;  % Start time of ripple event
            event_end = ripple_event.EE;    % End time of ripple event
            
            %fprintf('Tetrode %d, Ripple %d: Start = %d, End = %d\n', tetrode_num, i, event_start, event_end);
            
            % Convert start and end times to seconds
            start_time = event_start / Fs;
            end_time = event_end / Fs;

            % Calculate y_start and y_end for the box
            y_center = y_offset_tetrode;  % Center of the box for this tetrode
            y_start = y_center - box_height / 2;  % Bottom of the box
            y_end = y_center + box_height / 2;    % Top of the box

            % Debugging: print values before calling draw_box
            %fprintf('Start time: %.2f, End time: %.2f, Y start: %.2f, Y end: %.2f\n', start_time, end_time, y_start, y_end);


            % Draw a box around the ripple event
            draw_box(axesHandle, start_time, end_time, y_start, y_end, i);
        end
    end
end