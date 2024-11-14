function obj = detectRipples(obj, std_cutoff, freq_band, window_size, min_event_duration)
% Method to detect ripples for each tetrode and store SWR_Event objects

% Check if the object has been initialized with data
if isempty(obj.lfp_data) || isempty(obj.time_vec) || obj.sf == 0
    error('Error finding ripples: LFPExperiment object is not initialized. Please call loadData first.');
end

% Print the parameters at the start
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
fprintf('Finding ripples with:\n');
fprintf('  Standard Deviation Cutoff: %.2f\n', std_cutoff);
fprintf('  Frequency Band: [%d, %d] Hz\n', freq_band(1), freq_band(2));
fprintf('  Window Size: %d samples\n', window_size);
fprintf('  Minimum Event Duration: %d samples\n', min_event_duration);
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');

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
    fprintf('Total Number of Ripple Events Detected: %d\n', total_ripples);
    % Print summary of the ripple detection results
    if total_ripples > 0
        avg_frequency = total_frequency / total_ripples;
        avg_duration = total_duration / total_ripples;
        %if velocity_available
        %    avg_speed = total_animal_velocity / total_ripples;
        %    fprintf('Average animal speed during event: %.2f cm/s\n', avg_speed);
        %else
        %    fprintf('Average animal speed during event: Not available\n');
        %end
        fprintf('Average Internal Frequency: %.2f Hz\n', avg_frequency);
        fprintf('Average Duration: %.2f ms\n', avg_duration * 1000);
    else
        fprintf('No ripple events detected.\n');
    end

    for tetrode = 1:obj.num_tetrodes
        fprintf('  Tetrode %d: %d ripples\n', tetrode, ripple_count_per_tetrode(tetrode));
    end
end