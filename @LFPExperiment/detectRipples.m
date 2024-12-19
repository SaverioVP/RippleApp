function obj = detectRipples(obj, std_cutoff, freq_band, window_size, min_event_duration)
% Method to detect ripples for each tetrode and store SWR_Event objects

% Check if the object has been initialized with data
if isempty(obj.lfp_data) || isempty(obj.time_vec) || obj.sf == 0
    error('Error finding ripples: LFPExperiment object is not initialized. Please call loadData first.');
end

obj.std_cutoff = std_cutoff;
obj.freq_band = freq_band;
obj.window_size = window_size;
obj.min_event_duration = min_event_duration;


% Compute the filtered band for the entire LFP
obj.lfp_ripple_band_filtered = cell(obj.num_tetrodes, 1);
for tet_id = 1:obj.num_tetrodes
    lfp_data = obj.lfp_data{tet_id};
    % Ensure LFP is a row vector
    if size(lfp_data, 2) == 1  
        disp('LFP data is a column vector, transposing...');
        lfp_data = lfp_data.';  
    end
    obj.lfp_ripple_band_filtered{tet_id} = eegfilt(lfp_data, obj.sf, freq_band(1), freq_band(2));
end

% Compute sharp wave band for entire LFP
obj.lfp_sharp_wave_filtered = cell(obj.num_tetrodes, 1);
for tet_id = 1:obj.num_tetrodes
    % Ensure LFP is a row vector
    lfp_data = obj.lfp_data{tet_id};
    if size(lfp_data, 2) == 1
        lfp_data = lfp_data.';  % Transpose to make it a row vector
    end
    obj.lfp_sharp_wave_filtered{tet_id} = mybutter(lfp_data, obj.sf, 5, 15);  % Filter in the sharp wave band (8-40 Hz)
end

%% Compute detection threshold for LFP
obj.det_threshold = cell(obj.num_tetrodes, 1);

% Calculate mean and std of ripple band power
for tet_id = 1:obj.num_tetrodes
    lfp_data = obj.lfp_data{tet_id};
    if size(lfp_data, 2) == 1
        lfp_data = lfp_data.';  % Transpose to make it a row vector
    end
    lfp_rp = eegfilt(lfp_data, obj.sf, freq_band(1), freq_band(2));
    lfp_rp_hil = abs(hilbert(lfp_rp));  % Envelope of the ripple band signal using Hilbert transform
    lfp_rp_power = smoothdata(lfp_rp_hil, 'gaussian', 10);  % Smooth the ripple band envelope  
    rp_power_mean = mean(lfp_rp_power);  % Filter in the sharp wave band (8-40 Hz)
    rp_power_std = std(lfp_rp_power);
    obj.det_threshold{tet_id} = rp_power_mean + std_cutoff * rp_power_std; 
end

% Set threshold for ripple detection as mean + (Cutoff * standard deviation)



% Vars to store data about found ripple events
total_ripples = 0;
%ripple_count_per_tetrode = zeros(obj.num_tetrodes, 1);  % Array to store ripple counts for each tetrode
total_frequency = 0;
total_duration = 0;
%total_animal_velocity = 0;
%velocity_available = ~isempty(obj.pos_data);  % Check if pos_data is available

for tetrode = 1:obj.num_tetrodes 
    tetrode_lfp = obj.lfp_data{tetrode};  % Get LFP data for this tetrode

    % Skip if the LFP data for this tetrode is empty
    if isempty(tetrode_lfp)
        fprintf('Skipping tetrode %d: LFP data is empty.\n', tetrode);
        continue;
    end

    % Ensure LFP is a row vector
    if size(tetrode_lfp, 2) == 1  
        disp("transposing vector");
        tetrode_lfp = tetrode_lfp.';  
    end

    % Call the ripple detection function for this tetrode
    swrEvents = RP_DETECT_CSP(tetrode_lfp, obj.sf, std_cutoff, freq_band, window_size, min_event_duration);
    
    % Loop over each detected swr event to set properties
    for i = 1:length(swrEvents)
        % Set properties of each swr event not available inside the rp
        % detect function
        swrEvents(i) = swrEvents(i).setEventProperties(tetrode, tetrode_lfp, obj.time_vec, obj.sf);
        
        %if velocity_available
            % Calculate animal velocity if pos_data is available
        %    swrEvents(i).animal_velocity = get_animal_velocity(obj.pos_data, swrEvents(i).t_start, swrEvents(i).t_end);
        %    total_animal_velocity = total_animal_velocity + swrEvents(i).animal_velocity;
        %else
        %    swrEvents(i).animal_velocity = NaN; % Set animal_velocity to NaN if pos_data is not available
        %end

        % Accumulate total frequency and duration for averages
        total_frequency = total_frequency + swrEvents(i).internal_frequency;
        total_duration = total_duration + swrEvents(i).duration;
    end

    % Store modified events in obj.swr_events for this tetrode
    obj.swr_events{tetrode} = swrEvents;
    
    % Track the number of ripples detected on this tetrode
    ripple_count_per_tetrode(tetrode) = length(swrEvents);
    total_ripples = total_ripples + length(swrEvents);
end

obj.total_ripples = total_ripples;

if total_ripples > 0
    obj.avg_frequency = total_frequency / total_ripples;
    obj.avg_duration = total_duration / total_ripples;
end

end