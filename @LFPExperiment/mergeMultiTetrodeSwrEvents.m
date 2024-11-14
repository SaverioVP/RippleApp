function obj = mergeMultiTetrodeSwrEvents(obj)
    % Merges ripples together on multiple tetrodes if their
    % peaks overlap by peak_tolerance_ms
    % populates the class property merged_swr_events   % Cell array to store events which occur simultaneously on more than 1 tetrode
    % Properties of the merged event can be inferred from the first
    % event found   
    % Ripples array for each tetrode can be accessed by obj.swr_events{T} where T is the tetrode
    % number. eg disp(length(obj.merged_swr_events{1}))


    % Check if only one tetrode's worth of SWR events is provided
    % just copy the array and exit out 
    if obj.num_tetrodes == 1
        obj.merged_swr_events = obj.swr_events;
        disp('Only one tetrode detected; merged_swr_events set to swr_events.');
        return;
    end

    tolerance_seconds = obj.merge_peak_tolerance_ms / 1000;   

    obj.merged_swr_events = {};  % cell array to store merged events
    event_count = 0;  

    % iterate over tetrode 1 as base, compare events from other
    % tetrodes, remove from list of available if merged
    available_ripples = obj.swr_events;  % Copy of the original SWR events
    
    for base_tetrode = 1:obj.num_tetrodes
        base_ripples = available_ripples{base_tetrode};  % Ripples from base tetrode
        % Skip if there are no ripples in the base tetrode
        disp(size(base_ripples))
        if isempty(base_ripples)
            continue;
        end
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
            
                % Remove the merged ripples from the available list (in reverse order to avoid indexing issues)
                if ~isempty(to_remove)
                    available_ripples{other_tetrode}(to_remove) = [];
                end
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