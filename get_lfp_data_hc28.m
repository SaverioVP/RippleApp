function lfp_data_hc28 = get_lfp_data_hc28(animal_name, task_name, num_tetrodes)
% Takes an animal name, ie HPa, HPb, and a task name from dropdown menu and
% returns the LFP data from tetrodes 1-7 for that task
% task_name looks like this: Day1_Task4: 'run - wtr1'

% initialize cell to store data
lfp_data_hc28 = cell(1, num_tetrodes);
% Get day and epoch number from task_name
tokens = regexp(task_name, 'Day(\d+)_Task(\d+)', 'tokens');
dayNum = str2double(tokens{1}{1});
epochNum = str2double(tokens{1}{2});

for tetrode = 1:num_tetrodes   % Only first 7 tetrodes are inside CA1
    % Construct the file path and load data
    dayStr = sprintf('%02d', dayNum);      % Format day as 0X
    epochStr = sprintf('%d', epochNum);    % Epoch number (X)
    tetrodeStr = sprintf('%02d', tetrode); % Format tetrode as 0X
    filePath = sprintf('%seeg%s-%s-%s', animal_name, dayStr, epochStr, tetrodeStr);
    data = load(filePath);

    % Access the nested EEG signal
    eegCell = data.eeg{dayNum};    % Access the day
    eegCell2 = eegCell{epochNum};     % Access the epoch
    eegCell3 = eegCell2{tetrode};    % Access the tetrode number
    eegCell4 = eegCell3.data;           % Get the signal data
    lfp_data_hc28{tetrode} = eegCell4;  % add it to cell
end