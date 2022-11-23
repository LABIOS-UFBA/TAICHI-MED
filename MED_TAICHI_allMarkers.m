%------------------------------------------------------------------------
% 01 Code - MED in TAICHI - All markers
%
%
% This code applies the MED on a set of three-dimensional motion data for
% different rotations of the Cartesian coordinate system.
%
%
% Authors: Silva, M.S.; Miranda, J.G.V.
% November 22, 2022
%--------------------------------------------------------------------------

addpath('src');

%% Setting filter parameters

min_D = 0.003;                                                             % Minimum displacement threshold
min_T = 0.1;                                                               % Minimum duration threshold
min_V = 0.01;                                                              % Minimum velocity threshold

lp = 10;                                                                   % Low pass filter
order = 4;                                                                 % Filter order

%% Configuring

folder = strcat('.', filesep, 'data', filesep);                            % Folder with the database

%% Starting the function that will apply the MED method to the data

files = dir(fullfile(folder, '**/*.c3d*'));                                % Lists all c3d files in the folder

number_files = length(files);

mkdir(strcat('.', filesep, 'temp', filesep));                              % Make a temporary folder to save the output files of the parfor

var_names = {'P', 'T', 'C', 'G', 'D', 'S', ...
    'marker', 'w', 'r2', 'peak', 'nt', 'n'};
var_types = {'string', 'string', 'string', 'string', 'string', ...
    'string', 'string', 'double', 'double', 'double', 'double', 'double'};

parfor i = 1 : number_files
    
    file_path = [files(i).folder filesep files(i).name];
    name = files(i).name;
    
    btk_acq = btkReadAcquisition([files(i).folder filesep files(i).name]);
    btk_data = btkGetMarkers(btk_acq);
    unit = btkGetPointsUnit(btk_acq, 'marker');
    sample_rate = btkGetPointFrequency(btk_acq);
    
    name_markers = fieldnames(btk_data);
    num_markers = length(name_markers);
    
    output = table('Size', [num_markers length(var_types)], ...
        'VariableTypes', var_types, 'VariableNames', var_names);
    
    for j = 1 : num_markers
        
        j_marker = string(name_markers(j));
        r = btk_data.(j_marker);
    
        [r, v, t] = treat_MED(r, unit, sample_rate, lp, order);

        [j_output] = MED(name, [], r, v, t, min_D, min_T, min_V);
        
        for k = 1 : 6
            output(j, k) = cellstr(name(3*k - 1 : 3*k));
        end
        output(j, 7) = name_markers(j);
        output(j, 8 : end) = j_output(1, 2 : end);
        
    end
    
    writetable(output, strcat('.', filesep, 'temp', filesep, string(i), '_MED.csv'));
end

output_file = ...
    strcat('.', filesep, 'output', filesep, 'TAICHI_allMarkers_MED.csv');   % Joining temp files from the parfor iterations
directory = './temp/';
file_type = '*.csv';
joinFilesParfor(output_file, directory, file_type)