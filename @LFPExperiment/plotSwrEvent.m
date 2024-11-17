function plotSwrEvent(obj, axesHandle, event_id, showFIR, showEnvelope, mainLfpAxesHandle)
% Plot a single SWR Event on its own axis with some extra info
cla(axesHandle);

% Get the event
tetrode_num = 1;
this_event = obj.swr_events{tetrode_num}(event_id);  % only tetrode 1 for now

% Get the start and end indices of the event
es = this_event.event_start;
ee = this_event.event_end;

% Add samples of padding to the raw LFP trace to show swr event better
padding = 200;
es_padded = max(1, es - padding);  % Ensure indices are within bounds
ee_padded = min(length(obj.time_vec), ee + padding);


% Subset time vector and LFP data for the padded and unpadded cases
raw_time_vec_padded = obj.time_vec(es_padded:ee_padded);
raw_lfp_padded = obj.lfp_data{tetrode_num}(es_padded:ee_padded);

% Subset time vector for the event (no padding) for the other plots
% event_time_vec = obj.time_vec(es:ee);
%event_lfp = obj.lfp_data{tetrode_num}(es:ee);

% % Subset time vector for this event
% event_time_vec = obj.time_vec(es:ee);
% event_lfp = obj.lfp_data{tetrode_num}(es:ee);



%% Plot the raw LFP trace in blue and ripple portion in red
hold(axesHandle, 'on');

% Find the indices of the ripple event within the padded range
ripple_start_idx = es - es_padded + 1;  % Adjust for the padded start index
ripple_end_idx = ee - es_padded + 1;

% Plot the raw LFP trace before the ripple (in blue)
hold(axesHandle, 'on');
plot(axesHandle, raw_time_vec_padded(1:ripple_start_idx), raw_lfp_padded(1:ripple_start_idx), ...
     'Color', [0 0 1], 'LineWidth', 1.5);  % Blue - Before the ripple

% Plot the portion of the raw LFP trace during the ripple (in red)
plot(axesHandle, raw_time_vec_padded(ripple_start_idx:ripple_end_idx), raw_lfp_padded(ripple_start_idx:ripple_end_idx), ...
     'Color', [1 0 0], 'LineWidth', 1.5);  % Red - During the ripple

% Plot the raw LFP trace after the ripple (in blue)
plot(axesHandle, raw_time_vec_padded(ripple_end_idx:end), raw_lfp_padded(ripple_end_idx:end), ...
     'Color', [0 0 1], 'LineWidth', 1.5);  % Blue - After the ripple


%% Plot the filtered LFP trace (ripple waveform) using event indices
if showFIR
    event_fir = obj.lfp_fir_filtered{tetrode_num}(es_padded:ee_padded);
    plot(axesHandle, raw_time_vec_padded, event_fir, 'Color', [1 0.5 0], 'LineWidth', 1.5);  % Orange - FIR filtered trace
end

%% Plot the shaded area under the envelope
if showEnvelope
    event_hilbert = obj.lfp_amp_envelope{tetrode_num}(es_padded:ee_padded);
    fill(axesHandle, [raw_time_vec_padded, fliplr(raw_time_vec_padded)], ...
          [event_hilbert, fliplr(zeros(size(event_hilbert)))], ...
          [0.3 1 0.3], 'FaceAlpha', 0.3, 'EdgeColor', 'none');  % Green shaded area
end

%% Show Zero Crossings
%% Plot stuff
% Add a dotted red line at y = 0
yline(axesHandle, 0, 'r--', 'LineWidth', 1);

% Set the y-axis ticks to show amplitude values
set(axesHandle, 'YTickMode', 'auto');  % Enable Y ticks to show amplitude

title(axesHandle, sprintf('Ripple Event: %d', event_id));


%% Zoom or move the main LFP plot to the location of the SWR event
%% DO NOT USE: NOT VERY PRETTY
% Get the time range of the event
% event_time_start = obj.time_vec(es);
% event_time_end = obj.time_vec(ee);
% xlim(mainLfpAxesHandle, [event_time_start, event_time_end]);



end