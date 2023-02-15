% -------------------------------------------------------------------------
% 01 Code - MED in TAICHI - All markers
%
%
% This code applies the MED on a set of three-dimensional motion data for
% different rotations of the Cartesian coordinate system.
%
%
% Code authors: Silva, M.S.; Miranda, J.G.V.
% -------------------------------------------------------------------------

addpath('src');

%% Setting filter parameters

min_D = 0.003;                                                             % Minimum displacement threshold
min_T = 0.1;                                                               % Minimum duration threshold
min_V = 0.01;                                                              % Minimum velocity threshold

lp = 10;                                                                   % Low pass filter
order = 4;                                                                 % Filter order

min_N = 10;                                                                % Minimum number of elements per marker (to be in the output file), to not apply this filter put []
min_r2_alfa = [];                                                          % Minimum value of r2 of the MED scaling (to be in the output file), to not apply this filter put []

%% Configuring

folder = strcat('.', filesep, 'data', filesep);                            % Folder with the database

mkSup = ["RUA1"; "LUA1"; "LF1"; "RF1"; "L_HM1"; "R_HM1"];   		       % Markers of Upper appendicular

mkAx  = ["STRN"; "LFHD"; "L_IAS"; "R_IAS"];				                   % Markers of Axial

mkInf = ["L_TH1"; "R_TH1"; "L_SK1"; "R_SK1"; "L_FM2"; "R_FM2"];	           % Markers ofLower appendicular

%% Starting the function that will apply the MED method to the data

files = dir(fullfile(folder, '**/*.c3d*'));                                % Lists all c3d files in the folder

number_files = length(files);

mkdir(strcat('.', filesep, 'temp', filesep));                              % Make a temporary folder to save the output files of the parfor

var_names = {'P', 'T', 'C', 'G', 'D', 'S', 'bodySegment', ...
    'skill','Mark', 'w', 'r2', 'peak', 'nt', 'n', 'r2_alpha'};
var_types = {'string', 'string', 'string', 'string', 'string', ...
    'string', 'double', 'double','string', 'double', 'double', ...
    'double', 'double', 'double', 'double'};

parfor i = 1 : number_files
    
    file_path = [files(i).folder filesep files(i).name];
    name = files(i).name;
    
    btk_acq = btkReadAcquisition([files(i).folder filesep files(i).name]);
    btk_data = btkGetMarkers(btk_acq);
    unit = btkGetPointsUnit(btk_acq, 'marker');
    sample_rate = btkGetPointFrequency(btk_acq);
    
    name_markers = fieldnames(btk_data);
    
    output = table('Size', [16 length(var_types)], ...
        'VariableTypes', var_types, 'VariableNames', var_names);

    m = 1;

    for mkcategory = 1 : 3

        if mkcategory == 1
            name_markers = mkSup;
        elseif mkcategory == 2
            name_markers = mkAx;
        else
            name_markers = mkInf;
        end
        for j=1:length(name_markers)
            j_marker = string(name_markers(j));
            r = btk_data.(j_marker);
            
            [r, v, t] = treat_MED(r, unit, sample_rate, lp, order);
            
            [j_output] = MED(name, r, v, t, min_D, min_T, min_V, min_N, min_r2_alfa);
            
            if isempty(j_output)
                output(m,:) = [];
                continue;
            end

            for k = 1 : 6
                output(m, k) = cellstr(name(3*k - 1 : 3*k));
            end
            
            output(m, 7) = {mkcategory};
            output(m, 8) = {5-ceil(str2double(name(2 : 3))/3)};
            output(m, 9) = {j_marker};
            output(m, 10 : end) = j_output(1, 2 : end);
            m=m+1;
        end
    end
    
    if ~isempty(output)
        writetable(output, ...
            strcat('.', filesep, 'temp', filesep, string(i), '_MED.csv'));
    end
end

output_file = ...
    strcat('.', filesep, 'output', filesep, 'TAICHI_allMarkers_MED.csv');  % Joining temp files from the parfor iterations
directory = './temp/';
file_type = '*.csv';
joinFilesParfor(output_file, directory, file_type)