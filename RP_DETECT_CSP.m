function swrEvents = RP_DETECT_CSP(lfp_signal, sampling_freq_hz, std_cutoff, freq_band, window_size, min_event_duration)
% Detects sharp-wave ripple events on lfp (csc) from a single tetrode
% Returns an array of SWR_Event objects

% csc: Continuous LFP signal.
% n: Number of parts the signal is divided into to handle memory limitations.
% Fs: Sampling frequency.
% Cutoff: The number of standard deviations above the mean ripple band power used as a threshold for ripple event detection.
% freq_band: Frequency range for ripple detection (e.g., [150 250] Hz)
% window_size: Number of samples around the ripple peak to extract
% min_event_duration: Minimum duration for ripple events in samples

swrEvents = SWR_Event.empty();  % Initialize an empty array of SWR_Event objects
avg_spw = zeros(1, 2 * window_size + 1);  % Initialize variable to hold average sharp wave


% Filter the signal in the ripple band (150-250 Hz)
lfp_rp = eegfilt(lfp_signal, sampling_freq_hz, freq_band(1), freq_band(2));  
lfp_rp_hil = abs(hilbert(lfp_rp));  % Envelope of the ripple band signal using Hilbert transform
lfp_rp_power = smoothdata(lfp_rp_hil, 'gaussian', 10);  % Smooth the ripple band envelope  
lfp_spw = mybutter(lfp_signal, sampling_freq_hz, 8, 40);  % Filter in the sharp wave band (8-40 Hz)

% Calculate mean and std of ripple band power        
rp_power_mean = mean(lfp_rp_power);
rp_power_std = std(lfp_rp_power);


% Set threshold for ripple detection as mean + (Cutoff * standard deviation)
rp_power_threshold = rp_power_mean + std_cutoff * rp_power_std; 

% Find ripple events that exceed the threshold
rp_event_trim = find(lfp_rp_power > rp_power_threshold);


% Grouping Ripple Events
temp = find(diff(rp_event_trim) ~= 1);  % Identify gaps between consecutive points in ripple events
if ~isempty(temp)
    rp_event_candidate = zeros(length(temp), 2);  % Pairs of start and end points for candidate ripple events
    rp_event_candidate(:, 2) = rp_event_trim(temp);
    rp_event_candidate(:, 1) = rp_event_trim([1 temp(1:end - 1) + 1]);
    valid_event = find((rp_event_candidate(:, 2) - rp_event_candidate(:, 1)) > min_event_duration);  % Only events that last longer than L_threshold

    n_event = size(valid_event, 1);
    for i = 1:n_event
        event_start = rp_event_candidate(valid_event(i), 1);
        event_end = rp_event_candidate(valid_event(i), 2);

        [peak_ripple_amplitude, relative_peak_index] = max(lfp_rp_hil(event_start:event_end));  % Find the maximum amplitude of the ripple event within the current window and index of the peak within the event window (relative to the window start)
        ripple_peak_index = relative_peak_index + event_start - 1;
        if peak_ripple_amplitude > (rp_power_mean + 3 * rp_power_std) && (ripple_peak_index - window_size) > 0 && (ripple_peak_index + window_size) < length(lfp_signal) && (ripple_peak_index + window_size) < length(lfp_spw)
            avg_spw = avg_spw + lfp_spw(ripple_peak_index - window_size:ripple_peak_index + window_size);  % Update average sharp wave
            spw_waveform = lfp_spw(ripple_peak_index - window_size:ripple_peak_index + window_size);  % Store sharp wave for this event
            ripple_waveform = lfp_rp(ripple_peak_index - window_size:ripple_peak_index + window_size);  % Store ripple for this event
            
            rp_event = ripple_peak_index;  % Store ripple event peak

            % Add 50 ms window to each side of the ripple event
            window_size_ms = 50;  % in ms
            extra_samples = round((window_size_ms / 1000) * sampling_freq_hz);  % Convert to samples
            raw_lfp_waveform = lfp_signal(ripple_peak_index - window_size - extra_samples:ripple_peak_index + window_size + extra_samples);
            
            %raw_lfp_waveform = lfp_signal(ripple_peak_index - window_size:ripple_peak_index + window_size);
            
            % Create and store a SWR_Event object in the array
            event_start_s = event_start / sampling_freq_hz;
            event_end_s = event_end / sampling_freq_hz;
            swrEvent = SWR_Event(avg_spw, rp_event, spw_waveform, ripple_waveform, raw_lfp_waveform, event_start_s, event_end_s, sampling_freq_hz);
            swrEvents = [swrEvents, swrEvent];  % Append new SWR_Event object
        end
    end
end



end

