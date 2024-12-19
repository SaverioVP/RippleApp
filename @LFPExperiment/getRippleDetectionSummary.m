function summary = getRippleDetectionSummary(obj)
    % Returns a formatted summary of ripple detection parameters and results
    
    % Header
    summary = sprintf('Finding ripples with:\n');
    
    % Ripple detection parameters
    summary = [summary, sprintf('  Standard Deviation Cutoff: %.2f\n', obj.std_cutoff)];
    summary = [summary, sprintf('  Frequency Band: [%d, %d] Hz\n', obj.freq_band(1), obj.freq_band(2))];
    summary = [summary, sprintf('  Window Size: %d samples\n', obj.window_size)];
    summary = [summary, sprintf('  Minimum Event Duration: %d samples\n', obj.min_event_duration)];
    
    % Ripple detection results
    summary = [summary, sprintf('Total Number of Ripple Events Detected: %d\n', obj.total_ripples)];
    if obj.total_ripples > 0
        summary = [summary, sprintf('Average Internal Frequency: %.2f Hz\n', obj.avg_frequency)];
        summary = [summary, sprintf('Average Duration: %.2f ms\n', obj.avg_duration * 1000)];
    else
        summary = [summary, sprintf('No ripple events detected.\n')];
    end
    
    % Tetrode-specific results
    %for tetrode = 1:obj.num_tetrodes
    %    summary = [summary, sprintf('  Tetrode %d: %d ripples\n', tetrode, obj.ripple_count_per_tetrode(tetrode))];
    %end
end