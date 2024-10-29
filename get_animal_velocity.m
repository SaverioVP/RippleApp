function velocity = get_animal_velocity(pos_data, time_start, time_end)
% Returns the avg velocity of the animal during a time period. ie, during
% swr event
% pos data looks liek this
%pos_data.x = x_valid;
%pos_data.y = y_valid;
%pos_data.t = t_normalized; time in ms, starting from 0
%pos_data.v = v_valid;

% Extract the time and velocity from pos_data
indices_in_window = pos_data.t >= time_start & pos_data.t <= time_end;
%disp(time_start)
%disp(time_end)
velocity = mean(pos_data.v(indices_in_window));
%disp(velocity)

%if any(indices_in_window)
    % Calculate the average velocity within the time window
    %velocity = mean(pos_data.v(indices_in_window));
%else
    % If no valid data points are found in the window, return NaN
    %velocity = NaN;

    %warning('No data points found within the specified time window.');
%end

end