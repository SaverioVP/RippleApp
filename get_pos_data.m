function pos_data = get_pos_data(animal_name, task_name)
% Takes an animal name, ie HPa, HPb, and a task name from dropdown menu and
% returns the mouse position data for x-y plotting
% task_name looks like this: Day1_Task4: 'run - wtr1'

% Get Filepath
tokens = regexp(task_name, 'Day(\d+)_Task(\d+)', 'tokens');
dayNum = str2double(tokens{1}{1});
epochNum = str2double(tokens{1}{2});

dayStr = sprintf('%02d', dayNum);
filePath = sprintf('%spos%s', animal_name, dayStr);
data = load(filePath);
% Extract the data from the file
pos_data_struct = data.pos{dayNum};  % Access data for the specific day
pos_epoch_data = pos_data_struct{epochNum};  % Access data for the specific task (epoch)

% Extract the relevant position data (x, y, time, velocity)
pos_matrix = pos_epoch_data.data;

% Assign x, y, time (t), and velocity (v)
x = pos_matrix(:, 2);
y = pos_matrix(:, 3);
t = pos_matrix(:, 1);
v = pos_matrix(:, 5);

% Filter out invalid data points (where x, y, t, or v is NaN)
valid_indices = ~isnan(x) & ~isnan(y) & ~isnan(t) & ~isnan(v);

% Extract valid data points
x_valid = x(valid_indices);
y_valid = y(valid_indices);
t_valid = t(valid_indices);
v_valid = v(valid_indices);

% Normalize the time to start from 0
t_normalized = t_valid - t_valid(1);

% Create a struct to hold the valid position data with normalized time
pos_data.x = x_valid;
pos_data.y = y_valid;
pos_data.t = t_normalized;
pos_data.v = v_valid;
end