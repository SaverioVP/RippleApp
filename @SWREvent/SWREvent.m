classdef SWREvent
    %% Class for a Sharp Wave Ripple Event on a single tetrode LFP data
    properties
        % Properties given by rp detect function
        avg_spw             % Average sharp wave for this event
        rp_event            % Ripple event (peak time)
        spw_waveform        % Sharp wave waveform for this event
        ripple_waveform     % Ripple waveform for this event from the detection method
        event_start         % Event start time in samples index
        event_end           % Event end time in samples index
        time_start          % Event start time in seconds
        time_end            % Event end time in seconds

        % SWR Events set or calculated after detection
        tetrode_num         % Which tetrode LFP was this event found on?
        raw_lfp_waveform    % Raw LFP waveform during event window
        time_vector         % the x axis, in seconds
        sf                  % sampling frequency
        total_samples
        duration            % duration in seconds
        fir_filtered_lfp    % raw_lfp filtered inside this class
        internal_frequency  % internal frequency of the swr event
        zero_crossings      % Zero crossings in the ripple waveform
        %ripple_envelope     % idk

        % Properties for murine experiments
        animal_velocity     % average animal velocity during ripple
    end
    
    methods
        function obj = SWREvent(avg_spw, rp_event, spw_waveform, ripple_waveform, event_start, event_end)          
            if nargin > 0
                obj.avg_spw = avg_spw;
                obj.rp_event = rp_event;
                obj.spw_waveform = spw_waveform;
                obj.ripple_waveform = ripple_waveform;
                obj.event_start = event_start;
                obj.event_end = event_end;
            end
        end

        function obj = setEventProperties(obj, tetrode_number, full_lfp_waveform, full_time_vector, sampling_frequency)
            obj.tetrode_num = tetrode_number;
            obj.sf = sampling_frequency;

            % Extract the LFP waveform and time vector using event_start and event_end
            obj.raw_lfp_waveform = full_lfp_waveform(obj.event_start:obj.event_end);
            obj.time_vector = full_time_vector(obj.event_start:obj.event_end);
            obj.time_start = full_time_vector(obj.event_start);
            obj.time_end = full_time_vector(obj.event_end);
            obj.duration = obj.time_end - obj.time_start;
                        
            obj.total_samples = length(obj.raw_lfp_waveform);
            
            % Detect zero crossings and calculate the internal
            % frequency using ripple waveform provided by detection
            % func
            %obj.zero_crossings = obj.detectZeroCrossings(obj.ripple_waveform);
            %obj.internal_frequency = obj.calculateInternalFrequency();

            % Filter the waveform including the window. This is used
            % for plotting
            %obj.fir_filtered_lfp = obj.filterLFP_FIR(obj.raw_lfp_waveform, sampling_frequency);

            % Calculate the envelope of the whole trace
            %obj.ripple_envelope = abs(hilbert(obj.fir_filtered_lfp));

            % Uncomment this line if you want to print the ripple envelope information
            % fprintf('Ripple Envelope: [%.4f, ... , %.4f]\n', obj.ripple_envelope(1), obj.ripple_envelope(end));
        end
        
        function fir_filtered_lfp = filterLFP_FIR(~, raw_lfp, fs)
            % Apply FIR band-pass filter to the LFP signal in the ripple frequency range (e.g., 110-250 Hz)            low_cutoff = 8;
            filter_order = 100;  % Order of the FIR filter (higher order -> sharper transition)
            freq_band = [110 250];

            fir_coefficients = fir1(filter_order, freq_band / (fs / 2), 'bandpass');

            % Apply the FIR filter to the signal using filtfilt for zero-phase filtering
            fir_filtered_lfp = filtfilt(fir_coefficients, 1, raw_lfp);  % Zero-phase filtering
        end

        function zero_crossings = detectZeroCrossings(~, waveform)
            zero_crossings = find(diff(sign(waveform)) ~= 0);
        end

        function internal_frequency = calculateInternalFrequency(obj)
            % Calculate as ripple length divided by full oscillations
            num_oscillations = floor(length(obj.zero_crossings) / 2);  % Count full oscillations
            if num_oscillations > 0
                internal_frequency = num_oscillations / obj.duration;  % Internal ripple frequency
            else
                internal_frequency = 0;
            end
        end

        function [swr_x_start, swr_x_end, swr_y_start, swr_y_end] = getBoxExtents(obj)
            % Returns the outline of a box to be plotted that outlines this
            % ripple
            swr_y_start = max(obj.raw_lfp_waveform);  % Bottom of the box
            swr_y_end = min(obj.raw_lfp_waveform);    % Top of the box
            
            swr_x_start = obj.time_start; % in seconds
            swr_x_end = obj.time_end;
        end

        function printProperties(obj)
        % Method to print all properties of the SWR_Event object
            fprintf('SWR_Event Properties:\n');
            fprintf('  avg_spw: %.4f\n', obj.avg_spw);
            fprintf('  rp_event: %.4f\n', obj.rp_event);
            fprintf('  spw_waveform: [1x%d double]\n', length(obj.spw_waveform));
            fprintf('  ripple_waveform: [1x%d double]\n', length(obj.ripple_waveform));
            fprintf('  raw_lfp_waveform: [1x%d double]\n', length(obj.raw_lfp_waveform));
            fprintf('  t_start (s): %.8f\n', obj.time_start);
            fprintf('  t_end (s): %.8f\n', obj.time_end);
            fprintf('  fs (Hz): %.0f\n', obj.sf);
            fprintf('  duration (s): %.8f\n', obj.duration);
            fprintf('  time_vector: [1x%d double]\n', length(obj.time_vector));
            fprintf('  zero_crossings: [1x%d double]\n', length(obj.zero_crossings));
            fprintf('  internal_frequency (Hz): %.4f\n', obj.internal_frequency);
            fprintf('  fir_filtered_lfp: [1x%d double]\n', length(obj.fir_filtered_lfp));
            fprintf('  ripple_envelope: [1x%d double]\n', length(obj.ripple_envelope));
            fprintf('  animal velocity (cm/s): %.1f\n', obj.animal_velocity);
        end

        function props = getProperties(obj)
            % returns the output of a text box describing this ripple, as a
            % string
            props = sprintf(['SWR_Event Properties:\n', ...
                 '  t_start (s): %.3f\n', ...
                 '  t_end (s): %.3f\n', ...
                 '  duration (ms): %.1f\n', ...
                 '  internal_frequency (Hz): %.1f\n', ...
                 '  animal velocity (cm/s): %.1f\n'], ...
                 obj.time_start, ...
                 obj.time_end, ...
                 obj.duration*1000, ...
                 obj.internal_frequency, ...
                 obj.animal_velocity);
        end
    end
end