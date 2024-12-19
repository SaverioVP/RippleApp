classdef LFPExperiment
    properties
        lfp_data                    % cell(num_tetrodes, N);
        sf                          % Sampling frequency in Hz
        lfp_fir_filtered            % cell(num_tetrodes, N);
        lfp_ripple_band_filtered    % cell(num_tetrodes, N);
        lfp_sharp_wave_filtered     % cell(num_tetrodes, N);
        lfp_amp_envelope            % cell(num_tetrodes, N);
        lfp_zero_crossings          % cell(num_tetrodes, N);
        
        % Ripple Algorithm args
        std_cutoff
        det_threshold               %cell(obj.num_tetrodes, 1);  Computed power for detection based on std_cutoff
        freq_band
        window_size
        min_event_duration

        % Ripple Algorithm Summary
        total_ripples
        avg_frequency
        avg_duration

        pos_data                    % Position data object
        total_time                  % How long (from 0 to t) the data was measured (in s)
        time_vec                    % 1D array: Time array (duration / sampling freq)
        num_tetrodes                % num simultaneous tetrode recordings
        num_samples                 % Number of samples recorded


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