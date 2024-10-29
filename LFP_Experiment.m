classdef LFP_Experiment
    properties
        lfp_data        % lfp_data = cell(1, num_tetrodes);
        sampling_freq   % Sampling frequency (constant)
        pos_data        % Position data object
        total_time      % How long (from 0 to t) the data was measured (in s)
        time_vec        % 1D array: Time array (duration / sampling freq)
        num_tetrodes    % num simultaneous tetrode recordings

        swr_events      % Cell array to store SWR_Event objects for each tetrode individually
        merged_swr_events   % Cell array to store events which occur simultaneously on more than 1 tetrode
        merge_peak_tolerance_ms = 10
    end
    
    methods
        % Constructor to initialize the Experiment object
        function obj = LFP_Experiment(lfp_data, sampling_freq, pos_data, num_tetrodes)
            if nargin > 0
                obj.lfp_data = lfp_data;
                obj.sampling_freq = sampling_freq;
                obj.pos_data = pos_data;
                obj.num_tetrodes = num_tetrodes;
                
                % Create time vector (used on x axis for most plots)
                data_length = length(lfp_data{1});  % use length of first tetrode lfp 1d array
                obj.total_time = data_length / sampling_freq;
                obj.time_vec = linspace(0, obj.total_time, data_length);
                
                % Init stuff for detecting ripples
                obj.swr_events = cell(obj.num_tetrodes, 1);  % Preallocate cell array for SWR events
                % Print details about the experiment
                fprintf('LFP Experiment object created with:\n');
                fprintf('  Data Length: %d samples\n', data_length);
                fprintf('  Total Time: %.2f seconds\n', obj.total_time);
                fprintf('  Number of Tetrodes: %d\n', obj.num_tetrodes);
                fprintf('  Sampling Frequency: %.2f Hz\n', obj.sampling_freq);
                %fprintf('  Position Data: %s\n', mat2str(size(obj.pos_data)));
                disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
            end
        end
        
        function obj = detectRipples(obj, std_cutoff, freq_band, window_size, min_event_duration)
            % Method to detect ripples for each tetrode and store SWR_Event objects

            % Print the parameters at the start
            fprintf('Finding ripples with:\n');
            fprintf('  Standard Deviation Cutoff: %.2f\n', std_cutoff);
            fprintf('  Frequency Band: [%d, %d] Hz\n', freq_band(1), freq_band(2));
            fprintf('  Window Size: %d samples\n', window_size);
            fprintf('  Minimum Event Duration: %d samples\n', min_event_duration);
            disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
            % Vars to store data about found ripple events
            total_ripples = 0;
            ripple_count_per_tetrode = zeros(obj.num_tetrodes, 1);  % Array to store ripple counts for each tetrode
            total_frequency = 0;
            total_duration = 0;
            total_animal_velocity = 0;


            for tetrode = 1:obj.num_tetrodes
                tetrode_lfp = obj.lfp_data{tetrode};  % Get LFP data for this tetrode

                if size(tetrode_lfp, 2) == 1  % If it's a column vector
                    tetrode_lfp = tetrode_lfp.';  % Transpose to make it a row vector. This fixes a bug but I dont know why bug happens
                end

                % Call the ripple detection function for this tetrode
                swrEvents = RP_DETECT_CSP(tetrode_lfp, obj.sampling_freq, std_cutoff, freq_band, window_size, min_event_duration);
                
                % Loop over each detected ripple to set properties
                for i = 1:length(swrEvents)
                    swrEvents(i).tetrode_num = tetrode;
                    swrEvents(i).animal_velocity = get_animal_velocity(obj.pos_data, swrEvents(i).t_start, swrEvents(i).t_end);
        
                    % Accumulate total frequency and duration for averages
                    total_frequency = total_frequency + swrEvents(i).internal_frequency;
                    total_duration = total_duration + swrEvents(i).duration;
                    total_animal_velocity = total_animal_velocity + swrEvents(i).animal_velocity;
                end

                % Store modified events in obj.swr_events for this tetrode
                obj.swr_events{tetrode} = swrEvents;
                
                % Track the number of ripples detected on this tetrode
                ripple_count_per_tetrode(tetrode) = length(swrEvents);
                total_ripples = total_ripples + length(swrEvents);
            end

            % Print confirmation that i was finished
            avg_frequency = total_frequency / total_ripples;
            avg_duration = total_duration / total_ripples;
            avg_speed = total_animal_velocity / total_ripples;
            fprintf('Total Number of Ripple Events Detected: %d\n', total_ripples);
            for tetrode = 1:obj.num_tetrodes
                fprintf('  Tetrode %d: %d ripples\n', tetrode, ripple_count_per_tetrode(tetrode));
            end
            fprintf('Average Internal Frequency: %.2f Hz\n', avg_frequency);
            fprintf('Average Duration: %.2f ms\n', avg_duration*1000);
            fprintf('Average animal speed during event: %.2f cm/s\n', avg_speed);
        end


        function obj = mergeSWR_Events(obj)
            % Merges ripples together on multiple tetrodes if their
            % peaks overlap by peak_tolerance_ms
            % populates the class property merged_swr_events   % Cell array to store events which occur simultaneously on more than 1 tetrode
            % Properties of the merged event can be inferred from the first
            % event found
            
            tolerance_seconds = obj.merge_peak_tolerance_ms / 1000;   

            obj.merged_swr_events = {};  % cell array to store merged events
            event_count = 0;  

            % iterate over tetrode 1 as base, compare events from other
            % tetrodes, remove from list of available if merged
            available_ripples = obj.swr_events;  % Copy of the original SWR events
            
            for base_tetrode = 1:obj.num_tetrodes
                base_ripples = available_ripples{base_tetrode};  % Ripples from base tetrode
                for i = 1:length(base_ripples)
                    base_ripple = base_ripples(i);
                    merged_event_ripples = base_ripple;

                    for other_tetrode = base_tetrode + 1:obj.num_tetrodes
                        other_ripples = available_ripples{other_tetrode}; 
                        to_remove = [];  % indices of ripples that have been merged. Remove AFTER iterating or bugs

                        for j = 1:length(other_ripples)
                            other_ripple = other_ripples(j);
                            % Check if the events overlap within the tolerance
                            if (base_ripple.t_start <= other_ripple.t_end + tolerance_seconds) && ...
                               (other_ripple.t_start <= base_ripple.t_end + tolerance_seconds)
                                merged_event_ripples = [merged_event_ripples, other_ripple];  % Merge the ripple
                                to_remove = [to_remove, j];  % Mark this ripple as merged
                            end
                        end
                    
                    % Remove merged ripples from the available list for this tetrode
                    available_ripples{other_tetrode}(to_remove) = [];
                    end

                    % Increment event counter and add merged ripples as an array to cell array
                    event_count = event_count + 1;
                    obj.merged_swr_events{event_count} = merged_event_ripples;
                end
            end

        % Print for confirmation
        total_ripples = sum(cellfun(@length, obj.swr_events));
        disp(['Merged ', num2str(total_ripples), ' SWRs on different tetrodes into ', num2str(event_count), ' simultaneous events'])
        % Draw boxes for each event
        end


        function drawMergedSWREventBoxes(obj, axesHandle, yOffset)
            for event_idx = 1:length(obj.merged_swr_events)
                merged_event = obj.merged_swr_events{event_idx};
                base_ripple = merged_event(1);  % Representative ripple in merged event
                %disp(base_ripple)
                start_time = base_ripple.t_start;
                end_time = base_ripple.t_end;
                y_start = -500;
                y_end = yOffset * obj.num_tetrodes;
                
                % Draw the green box around the event in all tetrodes
                draw_green_box(axesHandle, start_time, end_time, y_start, y_end, event_idx);
                    
                % For each swr event in the merged events, draw red box
                % around it
                for t = 1:length(merged_event)
                    this_event = merged_event(t);
                    %disp(this_event)
                    tetrode_num = this_event.tetrode_num;  % Use the tetrode property of SWR_Event
                    %disp(tetrode_num)
                    y_offset_tetrode = (tetrode_num - 1) * yOffset;  % Offset for this tetrode
                    swr_y_start = y_offset_tetrode - yOffset / 2;  % Bottom of the box
                    swr_y_end = y_offset_tetrode + yOffset / 2;    % Top of the box

                    swr_start_time = this_event.t_start;
                    swr_end_time = this_event.t_end;
                    draw_red_box(axesHandle, swr_start_time, swr_end_time, swr_y_start, swr_y_end, t);

                end
                % Print event number
                %fprintf('Event %d:\n', event_idx);
                
                % Print the base tetrode information
                %fprintf('  Tetrode: %d\n', merged_event.tetrodes(1));
                %fprintf('  Tetrodes: %s\n', num2str(merged_event.tetrodes));
                %fprintf('  Peak Time (s): %.4f\n', base_ripple.rp_event / obj.sampling_freq);
                %fprintf('  Start Time (s): %.4f\n', base_ripple.ES / obj.sampling_freq);
                %fprintf('  End Time (s): %.4f\n', base_ripple.EE / obj.sampling_freq);
                %fprintf('  Duration (s): %.4f\n', base_ripple.duration);
                %fprintf('  Internal Frequency (Hz): %.4f\n\n', base_ripple.internal_frequency);
                %fprintf('  Animal Velocity (cm/s): %.4f\n\n', base_ripple.animal_velocity);
            end
        end
        function displayMergedEvent(obj, axesHandle, event_idx)
            % Displays the selected ripple on the axes, along with its
            % properties
            merged_event = obj.merged_swr_events{event_idx};
            base_ripple = merged_event(1);  % Representative ripple in merged event

            base_ripple.plotRippleEvent(axesHandle)  % use built in func on the event itself
        end
    end
end