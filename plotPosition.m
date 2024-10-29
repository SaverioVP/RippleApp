function plotPosition(axesHandle, pos_data)
    % plotPositionWithDataTips plots x vs y data with time and velocity displayed in data tips
    % axesHandle: The axes where the plot should be made (e.g., app.UIAxes2)
    % pos_data: Struct containing x, y, t (time), and v (velocity) data for plotting

    % Clear the axes before plotting
    cla(axesHandle, 'reset');

    % Plot x vs y
    hPlot = plot(axesHandle, pos_data.x, pos_data.y, '-.');  % Dotted line with circles at points

    % Set labels and title
    xlabel(axesHandle, 'X Position');
    ylabel(axesHandle, 'Y Position');
    title(axesHandle, 'Mouse Position');

    % Enable data cursor mode for interactivity
    dcm = datacursormode(ancestor(axesHandle, 'figure'));  % Get the data cursor mode object from the figure
    
    % Set the UpdateFcn only if this axes is being used
    set(dcm, 'UpdateFcn', @(obj, event_obj) displayDataTipForAxes(obj, event_obj, pos_data, axesHandle));
end

% Custom function for displaying time and velocity in the data tip for a specific axes
function output_txt = displayDataTipForAxes(~, event_obj, pos_data, axesHandle)
    % Check if the hovered object is part of the correct axes
    if event_obj.Target.Parent == axesHandle
        % Get the index of the data point being hovered/clicked on
        pos = get(event_obj, 'Position');  % Get x and y position of the point
        
        % Calculate the index of the closest point in the data set
        [~, idx] = min(sqrt((pos_data.x - pos(1)).^2 + (pos_data.y - pos(2)).^2));

        if ~isempty(idx) && idx <= length(pos_data.t)
            % Retrieve the time and velocity for the hovered point
            time_val = pos_data.t(idx);
            velocity_val = pos_data.v(idx);

            % Set the data tip text
            output_txt = {
                ['X: ', num2str(pos(1))], ...
                ['Y: ', num2str(pos(2))], ...
                ['Time: ', num2str(time_val)], ...
                ['Velocity: ', num2str(velocity_val)]
            };
        else
            % Default text if no match is found
            output_txt = {['X: ', num2str(pos(1))], ['Y: ', num2str(pos(2))]};
        end
    else
        % If not the correct axes, do nothing
        output_txt = {};
    end
end
