function swrEvents = RP_DETECT_CSP(lfp_signal, sf, std_cutoff, freq_band, window_size, min_event_duration)
% Detects sharp-wave ripple events on the provided LFP signal from a single tetrode
%
% Inputs:
% - lfp_signal: 1xN array of doubles: continuous LFP signal
% - sampling_freq_hz: Sampling frequency in Hz 
% - std_cutoff: num of standard deviations above the mean ripple band power 
%   used as the threshold for detecting ripple events.
% - freq_band: 1x2 array: frequency range (Hz) for detection. eg. [110 250]
% - window_size: (int) The number of samples around the ripple peak to extract the waveform. 
%                defines the length of the extracted waveform, centered on the peak.
% - min_event_duration: (int) The minimum duration for a valid ripple event, specified in samples. 
%                       Events shorter than this duration are ignored.
%
% Returns: an array of SWR_Event objects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

swrEvents = SWREvent.empty();  % Initialize an empty array of SWR_Event objects
avg_spw = zeros(1, 2 * window_size + 1);  % Initialize variable to hold average sharp wave

% Filter the signal in the ripple band
lfp_rp = eegfilt(lfp_signal, sf, freq_band(1), freq_band(2));  
lfp_rp_hil = abs(hilbert(lfp_rp));  % Envelope of the ripple band signal using Hilbert transform
lfp_rp_power = smoothdata(lfp_rp_hil, 'gaussian', 10);  % Smooth the ripple band envelope  
lfp_spw = mybutter(lfp_signal, sf, 8, 40);  % Filter in the sharp wave band (8-40 Hz)

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

        if peak_ripple_amplitude > (rp_power_mean + std_cutoff * rp_power_std) && (ripple_peak_index - window_size) > 0 && (ripple_peak_index + window_size) < length(lfp_signal) && (ripple_peak_index + window_size) < length(lfp_spw)
            avg_spw = avg_spw + lfp_spw(ripple_peak_index - window_size:ripple_peak_index + window_size);  % Update average sharp wave
            spw_waveform = lfp_spw(ripple_peak_index - window_size:ripple_peak_index + window_size);  % Store sharp wave for this event
            rp_waveform = lfp_rp(ripple_peak_index - window_size:ripple_peak_index + window_size);  % Store ripple for this event
            rp_event = ripple_peak_index;  % Store ripple event peak

            % Create and store a SWR_Event object in the array
            swrEvent = SWREvent(avg_spw, rp_event, spw_waveform, rp_waveform, event_start, event_end);
            
            swrEvents = [swrEvents, swrEvent];  % Append new SWR_Event object
        end
    end
end



end

