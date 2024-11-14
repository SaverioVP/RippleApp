function lfp_data_cg = get_lfp_data_cg(animal_name)
% Loads the calegari lab data

% Define which tetrodes are in CA1 layer for each animal
animal_tetrodes = struct( ...
    'EAN005', [4, 5], ...
    'EAN006', [5, 6], ...
    'EAN007', [1, 2], ...
    'EAN008', [], ...
    'EAN009', [1, 5], ...
    'EAN010', [1, 2, 6], ...
    'EAN011', [1, 3, 6], ...
    'EAN012', [1, 2], ...
    'EAN013', [1, 5], ...
    'EAN014', [1, 5, 6], ...
    'EAN015', [1, 5, 6], ...
    'EAN016', [3, 4, 5], ...
    'EAN017', [1, 2, 3, 4, 5, 6], ...
    'EAN018', [1, 4, 5, 6], ...
    'EAN019', [1, 4, 5, 6], ...
    'EAN020', [1, 4, 5, 6] ...
    );

% Find the maximum tetrode number across all animals
all_tetrodes_cell = struct2cell(animal_tetrodes);
all_tetrodes = [all_tetrodes_cell{:}];
max_tetrode_number = max(all_tetrodes); 

% init arrays
lfp_data_cg = cell(1, max_tetrode_number);
relevant_tetrodes = animal_tetrodes.(animal_name);

% Work on a pre-curated folder for now
data_folder = fullfile('ean_data');
mat_files = dir(fullfile(data_folder, [animal_name, '-baseline_*.mat']));
% Error if no files found
if isempty(mat_files)
    error('No files found for the specified animal: %s', animal_name);
end

for idx = 1:length(relevant_tetrodes)
    % Each file contains a 4x6x300000 double of downsampled data at 1000 Hz, 
    % 4 electrodes x 6 tetrodes, 1 file for every 5 minutes of recording
    % concatenate it all together
    concatenated_tet_data = [];
    tetrode_idx = relevant_tetrodes(idx);
    for file_idx = 1:length(mat_files)
        file_path = fullfile(data_folder, mat_files(file_idx).name);
        data_struct = load(file_path, 'tetrode_data_downsampleNotch');
        
        % Extract the data from the first electrode of the current tetrode
        tetrode_data = data_struct.tetrode_data_downsampleNotch(1, tetrode_idx, :);
        concatenated_tet_data = [concatenated_tet_data, reshape(tetrode_data, 1, [])];
    end
    
    lfp_data_cg{tetrode_idx} = concatenated_tet_data;
    % Debugging
    %fprintf('Tetrode %d: Number of samples = %d\n', tetrode_idx, numel(concatenated_tet_data));
end
end