function drawSwrEvents(obj, axesHandle)
% Plots the red boxes around swr events for each tetrode

for tetrode_id = 1:length(obj.swr_events)  % iterating over each tetrode's events
    for event_id = 1: length(obj.swr_events{tetrode_id})
        this_event = obj.swr_events{tetrode_id}(event_id);
        [swr_x_start, swr_x_end, swr_y_start, swr_y_end] = this_event.getBoxExtents();

        % For debugging: % Print the extents to the console
        % fprintf('Tetrode: %d, Event: %d, X Start: %.2f, X End: %.2f, Y Start: %.2f, Y End: %.2f\n', ...
        %         tetrode_id, event_id, swr_x_start, swr_x_end, swr_y_start, swr_y_end);

        draw_green_box(axesHandle, swr_x_start-0.5, swr_x_end+0.5, swr_y_start-1000, swr_y_end+1000, event_id);
        draw_red_box(axesHandle, swr_x_start, swr_x_end, swr_y_start, swr_y_end);
    end
end
