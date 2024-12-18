function obj = getLfpDataFromFile(obj, filepath, lfp_struct_name, time_struct_name)
%% Description
% - Loads the lfp data from a .mat file at "filepath"
% - The .mat file should contain the continuous lfp data (concatenated 
% together if necessary) from a single tetrode, recorded over a single
% session, and formatted as a matlab struct with the lfp data contained in
% struct_name, and time vector in struct called time_struct_name
% - If the lfp data is of shape 4 x N or N x 4 where N is number of recorded
% samples, this function will assume these are recordings from multiple
% electrodes, and will take only the lfp from the highest power electrode.

% Sets the lfp_data, time_vector and sampling frequency of the
% LFPExperiment object


%% Function private variables
% Frequency range for power calculation, when selecting "best" electrode
f_range = [1, 512];
% vars for electrode selection
max_power = -Inf;
chosen_electrode_data = [];

%& Default outputs in case of errors
num_tetrodes = 1;
obj.lfp_data = cell(num_tetrodes, 1);  % Initialize cell array for one tetrode
obj.time_vec= [];
obj.sf = NaN;

try
    %% Load file into memory
    if ~isfile(filepath)
        fprintf('Error: File "%s" does not exist.\n', filepath);
        return;
    end
    data = load(filepath);
    
    %% Extract LFP data and time vector
    if ~isfield(data, lfp_struct_name)
        fprintf('Error: The LFP struct "%s" is not found in the file "%s".\n', lfp_struct_name, filepath);
        return;
    end
    if ~isfield(data, time_struct_name)
        fprintf('Error: The time struct "%s" is not found in the file "%s".\n', time_struct_name);
        return;
    end
    
    % Extract and convert LFP data to double
    lfp_data_struct = double(data.(lfp_struct_name));

    % Extract and convert time vector to double
    obj.time_vec = double(data.(time_struct_name));
    
    if ~isvector(obj.time_vec)
        fprintf('Error: The time vector "%s" is not a valid 1D array in the file "%s".\n', time_struct_name, filepath);
        return;
    end

    %% Calculate sampling frequency for pwelch
    time_step = mean(diff(obj.time_vec));  % average time step
    obj.sf = 1 / time_step; 
    obj.total_time = obj.time_vec(length(obj.time_vec)) - obj.time_vec(1);

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
            [psd, freqs] = pwelch(lfp_data_elt, 2048, [], [], obj.sf);  
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


    obj.lfp_data{1} = chosen_electrode_data;  % assumes only 1 tetrode input for now
    
    % Print the final message including the best electrode and its power
    fprintf('LFP data successfully loaded from %s.\n with length: %d samples.\n', filepath, length(obj.lfp_data{1}));
    if exist('best_electrode', 'var')
        fprintf('Best electrode: %d with power: %.2f dB\n', best_electrode, max_power);
    end

catch ME
    fprintf('Error occurred while loading LFP data:\n%s\n', ME.message);
end

%% Set other data for the experiment object
% Populate the properties with the provided data
obj.num_tetrodes = num_tetrodes;
obj.num_samples = length(obj.lfp_data{1});  % assume all tetrode recordings are same length
%obj.pos_data = pos_data;

% Initialize SWR events cell array
obj.swr_events = cell(obj.num_tetrodes, 1);


%% Generate the FIR filtered trace
% Apply FIR band-pass filter to the LFP signal in the ripple frequency range (e.g., 110-250 Hz)
filter_order = 100;  % Order of the FIR filter (higher order -> sharper transition)
freq_band = [110 250];

fir_coefficients = fir1(filter_order, freq_band / (obj.sf / 2), 'bandpass');

% Apply the FIR filter to the signal using filtfilt for zero-phase filtering
obj.lfp_fir_filtered = cell(obj.num_tetrodes, 1);
for tet_id = 1:obj.num_tetrodes
    obj.lfp_fir_filtered{tet_id} = filtfilt(fir_coefficients, 1, obj.lfp_data{tet_id});  % Zero-phase filtering
end


%% Generate the amplitude envelope w hilbert transoform
for tet_id = 1:obj.num_tetrodes
    obj.lfp_amp_envelope{tet_id} = abs(hilbert(obj.lfp_fir_filtered{tet_id}));
end

%% Find where the fir filtered trace crosses zero line
for tet_id = 1:obj.num_tetrodes
    zero_crossings = find(diff(sign(obj.lfp_fir_filtered{tet_id})) ~= 0);

    % Adjust zero crossings to ensure valid indices for plotting
    % (Offset by +1 to correct for the shift introduced by diff)
    %zero_crossings = zero_crossings - 1;

    % Store the adjusted zero crossings
    obj.lfp_zero_crossings{tet_id} = zero_crossings;
    
    
    % % different method
    % signal = obj.lfp_fir_filtered{tet_id};
    % zero_crossings = [];
    % 
    % % Loop through the signal to find intervals where the sign changes
    % for k = 1:length(signal) - 1
    %     if (signal(k) > 0 && signal(k + 1) < 0) || (signal(k) < 0 && signal(k + 1) > 0)
    %         % Linear interpolation to find the zero-crossing point
    %         zero_crossing_time = k + (0 - signal(k)) / (signal(k + 1) - signal(k));
    %         zero_crossings = [zero_crossings, zero_crossing_time];
    %     end
    % end
    % 
    % obj.lfp_zero_crossings{tet_id} = round(zero_crossings);
end



end