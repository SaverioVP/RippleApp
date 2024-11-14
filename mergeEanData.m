% Define the path to the folder containing the .mat files
dataFolder = 'D:\Desktop\Shonali project\ean_data';  % Update this to your folder path
outputFolder = 'D:\Desktop\Shonali project\ean_data\conc_output';  % Folder to save the concatenated data
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Get a list of all .mat files in the folder
fileList = dir(fullfile(dataFolder, '*.mat'));

% Initialize cell arrays to hold concatenated data for each tetrode
conc_lfp_data = cell(1, 6);
conc_time_vec = [];

% Loop over each file in the folder
for i = 1:length(fileList)
    % Load the .mat file
    filePath = fullfile(dataFolder, fileList(i).name);
    loadedData = load(filePath);

    % Extract the LFP data and timestamps
    lfp_data = loadedData.tetrode_data_downsampleNotch;  % 4x6x300000
    time_vec = loadedData.timestamps_downsample;        % 1x300000

    % Concatenate the time vector
    conc_time_vec = [conc_time_vec, time_vec];

    % Loop over each of the 6 tetrodes to concatenate the data
    for tetrode = 1:6
        % Extract the data for the current tetrode (4x300000)
        tetrode_data = squeeze(lfp_data(:, tetrode, :));
        
        % Concatenate the data along the second dimension
        if isempty(conc_lfp_data{tetrode})
            conc_lfp_data{tetrode} = tetrode_data;
        else
            conc_lfp_data{tetrode} = [conc_lfp_data{tetrode}, tetrode_data];
        end
    end
end

% Save the concatenated data for each tetrode into separate .mat files
for tetrode = 1:6
    % Construct the output file name
    outputFileName = sprintf('ean005_tetrode_%d_data.mat', tetrode);
    outputFilePath = fullfile(outputFolder, outputFileName);

    % Create a struct with the fields to save
    dataToSave.conc_lfp_data = conc_lfp_data{tetrode};
    dataToSave.conc_time_vec = conc_time_vec;

    % Save the data to a .mat file
    save(outputFilePath, '-struct', 'dataToSave');
end

disp('Data concatenation and saving completed successfully.');