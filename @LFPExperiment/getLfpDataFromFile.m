function [lfp_data, time_vector, sf] = getLfpDataFromFile(obj, filepath, lfp_struct_name, time_struct_name)
%% Description
% - Loads the lfp data from a .mat file at "filepath"
% - The .mat file should contain the continuous lfp data (concatenated 
% together if necessary) from a single tetrode, recorded over a single
% session, and formatted as a matlab struct with the lfp data contained in
% struct_name, and time vector in struct called time_struct_name
% - If the lfp data is of shape 4 x N or N x 4 where N is number of recorded
% samples, this function will assume these are recordings from multiple
% electrodes, and will take only the lfp from the highest power electrode.

% RETURNS: 
% lfp_data: txN array where t is num tetrodes.
% time_vector: 1xN array, time at each sample
% sf: sampling frequency in Hz

% Example usage: [lfp_data_1d, time_vector, sf] = get_lfp_data_from_file('path_to_file.mat', 'lfpStructName', 'timeStructName');

%% Function private variables
% Frequency range for power calculation, when selecting "best" electrode
f_range = [1, 512];
% vars for electrode selection
max_power = -Inf;
chosen_electrode_data = [];

%% Load file into memory
data = load(filepath);

%% Find struct with lfp data and check its dimension
% Check if the specified struct names exist in the loaded data
if ~isfield(data, lfp_struct_name) || ~isfield(data, time_struct_name)
    error('Specified struct names not found in the .mat file.');
end

lfp_data_struct = data.(lfp_struct_name);
time_vector = data.(time_struct_name);

%% Calculate sampling frequency for pwelch
time_step = mean(diff(time_vector));  % average time step
sf = 1 / time_step; 

%% If multiple electrodes, choose highest power
% Check the dimensions of the LFP data
[rows, cols] = size(lfp_data_struct);

% Check if the LFP data has multiple electrodes
if rows == 4 || cols == 4
    for elt = 1:4
        % Extract LFP data for the current electrode
        if rows == 4
            lfp_data_elt = lfp_data_struct(elt, :);
        else
            lfp_data_elt = lfp_data_struct(:, elt);
        end

        % Compute the power spectral density using pwelch
        % syntax: pwelch(x, window, noverlap, nfft, fs)
        [psd, freqs] = pwelch(lfp_data_elt, 2048, [], [], sf);  
        indices_in_range = freqs >= f_range(1) & freqs <= f_range(2);
        % Number of frequency components in range (Should be N/2 + 1 
        % where N is window size). Use disp(sum(indices_in_range)); to check  
        power_in_range = sum(10 * log10(psd(indices_in_range)));  % Convert power to decibels

        % Select the electrode with the highest power
        if power_in_range > max_power
            chosen_electrode_data = lfp_data_elt;
            max_power = power_in_range;
            best_electrode = elt;  % Store the best electrode number
        end
    end
else
    % If the LFP data is already 1D, use it directly
    chosen_electrode_data = lfp_data_struct;
end
num_tetrodes = 1;
lfp_data = cell(num_tetrodes, 1);  % Initialize cell array for one tetrode
lfp_data{1} = chosen_electrode_data;  % assumes only 1 tetrode input for now

% Print the final message including the best electrode and its power
fprintf('LFP data successfully loaded from %s.\n with length: %d samples.\n', filepath, length(lfp_data{1}));
fprintf('Best electrode: %d with power: %.2f dB\n', best_electrode, max_power);

end