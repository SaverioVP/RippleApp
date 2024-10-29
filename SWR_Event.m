classdef SWR_Event
    properties
        tetrode_num     % Which tetrode LFP was this event found on?
        avg_spw         % Average sharp wave for this event
        rp_event        % Ripple event (peak time)
        spw_waveform    % Sharp wave waveform for this event
        ripple_waveform % Ripple waveform for this event from the detection method
        raw_lfp_waveform % Raw LFP waveform for this event window from the detection, has 50 ms window added to each side
        t_start              % Event start time in seconds
        t_end                % Event end time in seconds
        duration        % duration in ms
        fs              % sampling frequency
        time_vector     % the x axis, in seconds
        % Calculated properties
        fir_filtered_lfp   % raw_lfp filtered inside this class
        internal_frequency       % internal frequency of the swr event
        zero_crossings  % Zero crossings in the ripple waveform
        ripple_envelope

        % Properties for murine experiments
        animal_velocity   % average animal velocity during ripple
    end
    
    methods
        function obj = SWR_Event(avg_spw, rp_event, spw_waveform, ripple_waveform, raw_lfp_waveform, event_start_s, event_end_s, sampling_frequency)
            % Constructor to initialize the SWR_Event properties
            % ES and EE are sample index; convert them to time
            if nargin > 0
                obj.avg_spw = avg_spw;
                obj.rp_event = rp_event;
                obj.spw_waveform = spw_waveform;
                obj.ripple_waveform = ripple_waveform;
                obj.raw_lfp_waveform = raw_lfp_waveform;
                obj.t_start = event_start_s;
                obj.t_end = event_end_s;
                obj.fs = sampling_frequency;

                obj.duration = obj.t_end - obj.t_start;  % Calculate duration based on start and end indices
                
                total_samples = length(obj.raw_lfp_waveform);
                obj.time_vector = linspace(obj.t_start, obj.t_end, total_samples);

                % Detect zero crossings and calculate the internal
                % frequency using ripple waveform provided by detection
                % func
                obj.zero_crossings = obj.detectZeroCrossings(obj.ripple_waveform);
                obj.internal_frequency = obj.calculateInternalFrequency();

                % Filter the waveform including the window. This is used
                % for plotting
                obj.fir_filtered_lfp = obj.filterLFP_FIR(raw_lfp_waveform, sampling_frequency);

                % Calculate the envelope of the whoel trace
                obj.ripple_envelope = abs(hilbert(obj.fir_filtered_lfp));

            end
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


        function plotRippleEvent(obj, axesHandle)
            % Create the time vector in ms
            disp(obj.fs);  % Check if obj.fs is a scalar
        
            % Clear the axes before plotting
            cla(axesHandle);
        
            % Plot the raw LFP trace
            hold(axesHandle, 'on');
            plot(axesHandle, obj.time_vector, obj.raw_lfp_waveform, 'Color', [0 0 1], 'LineWidth', 1.5);  % Blue - Raw trace
            
            % Plot the filtered LFP trace (ripple waveform)
            plot(axesHandle, obj.time_vector, obj.fir_filtered_lfp, 'Color', [1 0.5 0], 'LineWidth', 1.5);  % Orange - FIR filtered trace
            
            % Plot the shaded area under the envelope
            fill(axesHandle, [obj.time_vector, fliplr(obj.time_vector)], ...
                 [obj.ripple_envelope, fliplr(zeros(size(obj.ripple_envelope)))], ...
                 [0.3 1 0.3], 'FaceAlpha', 0.3, 'EdgeColor', 'none');  % Green shaded area
            
            % Mark the zero crossings
            % Calculate the extra samples due to the 50 ms window on each side
            extra_samples = round(50 / 1000 * obj.fs);  % Convert 50 ms to samples
        
            % Calculate ripple window start and end indices relative to raw_lfp_waveform
            ripple_window_start = extra_samples + 1;  % Start after the first 50 ms
            ripple_window_end = extra_samples + length(obj.ripple_waveform);  % End after the ripple waveform duration
            ripple_window_time = obj.time_vector(ripple_window_start:ripple_window_end);
        
            % Plot the zero crossings within the ripple window only
            scatter(axesHandle, ripple_window_time(obj.zero_crossings), ...
                    obj.fir_filtered_lfp(ripple_window_start + obj.zero_crossings - 1), ...
                    50, 'r', 'filled');  % Red dots - Zero crossings
            
            % Add labels and formatting
            xlabel(axesHandle, 'Time (s)');
            ylabel(axesHandle, 'Amplitude');
            title(axesHandle, 'Ripple Event: Filtered Trace, Oscillation Amplitude, and Zero Crossings');
            legend(axesHandle, 'Raw Trace', 'FIR - Filtered Trace', 'Oscillation Amplitude', 'Zero Crossings');
            yline(axesHandle, 0, '--k', 'LineWidth', 1);  % Add a black dashed line at y = 0
            hold(axesHandle, 'off');
        end

        function printProperties(obj)
        % Method to print all properties of the SWR_Event object
        
            fprintf('SWR_Event Properties:\n');
            fprintf('  avg_spw: %.4f\n', obj.avg_spw);
            fprintf('  rp_event: %.4f\n', obj.rp_event);
            fprintf('  spw_waveform: [1x%d double]\n', length(obj.spw_waveform));
            fprintf('  ripple_waveform: [1x%d double]\n', length(obj.ripple_waveform));
            fprintf('  raw_lfp_waveform: [1x%d double]\n', length(obj.raw_lfp_waveform));
            fprintf('  t_start (s): %.8f\n', obj.t_start);
            fprintf('  t_end (s): %.8f\n', obj.t_end);
            fprintf('  fs (Hz): %.0f\n', obj.fs);
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
                 '  t_start (s): %.8f\n', ...
                 '  t_end (s): %.8f\n', ...
                 '  duration (s): %.8f\n', ...
                 '  internal_frequency (Hz): %.4f\n', ...
                 '  animal velocity (cm/s): %.1f\n'], ...
                 obj.t_start, ...
                 obj.t_end, ...
                 obj.duration, ...
                 obj.internal_frequency, ...
                 obj.animal_velocity);
        end
    end
end