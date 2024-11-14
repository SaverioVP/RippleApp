classdef LFPExperiment
    properties
        lfp_data        % lfp_data = cell(num_tetrodes, N);
        sf              % Sampling frequency in Hz
        lfp_fir_filtered
        lfp_amp_envelope
        lfp_zero_crossings

        pos_data        % Position data object
        total_time      % How long (from 0 to t) the data was measured (in s)
        time_vec        % 1D array: Time array (duration / sampling freq)
        num_tetrodes    % num simultaneous tetrode recordings
        num_samples     % Number of samples recorded

        % For plotting LFP data
        yOffset = 500;  % How staggered the LFP signals are on single axis

        % For detection and plotting SWR events
        swr_events      % Cell array to store SWR_Event objects for each tetrode individually
        merged_swr_events   % Cell array to store events which occur simultaneously on more than 1 tetrode
        merge_peak_tolerance_ms = 10

        % For storing information related to each tetrode
        % SWR durations: histogram
    end
    
    methods
        % Constructor to create an empty LFPExperiment object
        function obj = LFPExperiment()
            % Initialize empty properties
            obj.lfp_data = {};
            obj.sf = 0;
            obj.pos_data = [];
            obj.total_time = 0;
            obj.time_vec = [];
            obj.num_tetrodes = 0;
            %obj.tetrode_ids = [];
            obj.merged_swr_events = {};
        end

        % Method to populate and load the data
        function obj = loadData(obj, lfp_data, time_vec,pos_data)
            % Populate the properties with the provided data
            obj.lfp_data = lfp_data;
            obj.time_vec = time_vec; 
            obj.num_tetrodes = length(lfp_data);
            obj.num_samples = length(lfp_data{1});  % assume all tetrode recordings are same length
            obj.pos_data = pos_data;

            % Calculate sampling frequency
            time_step = mean(diff(time_vec));  % average time step
            obj.sf = 1 / time_step; 

            % Calculate total time
            obj.total_time = time_vec(length(time_vec)) - time_vec(1);

            % Initialize SWR events cell array
            obj.swr_events = cell(obj.num_tetrodes, 1);

            % Print the number of samples for each tetrode
            %for tetrode_idx = 1:obj.num_tetrodes
            %    num_samples = length(lfp_data{tetrode_idx});
            %    fprintf('  Tetrode %d: %d samples\n', tetrode_idx, num_samples);
            %end
            %if isempty(obj.pos_data)
            %    fprintf('  Position Data: Not provided\n');
            %else
            %    fprintf('  Position Data: Provided\n');
            %end
            disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');


            %% Generate the FIR filtered trace
            % Apply FIR band-pass filter to the LFP signal in the ripple frequency range (e.g., 110-250 Hz)            low_cutoff = 8;
            filter_order = 100;  % Order of the FIR filter (higher order -> sharper transition)
            freq_band = [110 250];

            fir_coefficients = fir1(filter_order, freq_band / (obj.sf / 2), 'bandpass');

            % Apply the FIR filter to the signal using filtfilt for zero-phase filtering
            obj.lfp_fir_filtered = cell(obj.num_tetrodes, 1);
            for tet_id = 1:obj.num_tetrodes
                obj.lfp_fir_filtered{tet_id} = filtfilt(fir_coefficients, 1, obj.lfp_data{tet_id});  % Zero-phase filtering
            end

            %% Generate the amplitude envelope w hilbert transoform
            for tet_id = 1:obj.num_tetrodes
                obj.lfp_amp_envelope{tet_id} = abs(hilbert(obj.lfp_fir_filtered{tet_id}));
            end
           
            %% Find where the fir filtered trace crosses zero line
            for tet_id = 1:obj.num_tetrodes
                zero_crossings = find(diff(sign(obj.lfp_fir_filtered{tet_id})) ~= 0);
    
                % Adjust zero crossings to ensure valid indices for plotting
                % (Offset by +1 to correct for the shift introduced by diff)
                %zero_crossings = zero_crossings - 1;
            
                % Store the adjusted zero crossings
                obj.lfp_zero_crossings{tet_id} = zero_crossings;
                
                
                % % different method
                % signal = obj.lfp_fir_filtered{tet_id};
                % zero_crossings = [];
                % 
                % % Loop through the signal to find intervals where the sign changes
                % for k = 1:length(signal) - 1
                %     if (signal(k) > 0 && signal(k + 1) < 0) || (signal(k) < 0 && signal(k + 1) > 0)
                %         % Linear interpolation to find the zero-crossing point
                %         zero_crossing_time = k + (0 - signal(k)) / (signal(k + 1) - signal(k));
                %         zero_crossings = [zero_crossings, zero_crossing_time];
                %     end
                % end
                % 
                % obj.lfp_zero_crossings{tet_id} = round(zero_crossings);
            end

            % Print details about the experiment
            disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
            fprintf('LFP Experiment object populated with:\n');
            fprintf('  Number of Tetrodes: %d \n', obj.num_tetrodes);
            fprintf('  Length of LFP: %d Samples\n', obj.num_samples);
            fprintf('  Time Vector with: %d time points\n', length(obj.time_vec));
            fprintf('  Sampling Frequency: %.2f Hz\n', obj.sf);
            fprintf('  Total Time: %.3f seconds\n', obj.total_time);
            fprintf('  Time Step: %.2f ms\n', (obj.time_vec(2) - obj.time_vec(1)) * 1000.0);
        end

        
        function displayMergedEvent(obj, axesHandle, event_idx)
            % Displays the selected ripple on the axes, along with its
            % properties
            %merged_event = obj.mergedswr_events{event_idx};
            base_ripple = obj.swr_events{1}(event_idx);  % Representative ripple in merged event
            %disp(class(base_ripple));  % This should print 'SWREvent'
            base_ripple.plotSwrEvent(axesHandle)  % use built in func on the event itself
        end
    end
end