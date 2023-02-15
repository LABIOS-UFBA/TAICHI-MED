function [variable_table] = MED(name, r, v, t, min_D, min_T, min_V, min_N, min_r2alpha)
% -------------------------------------------------------------------------
% The MED.m function is responsible for calculating the MED variables to an
% n-dimensional file and exporting as output
%
% Input:
%     name = name of the file
%     flag = any flag that you want to put inside the table
%     r = position time series
%     v = velocity time series
%     t = vector with time count
%     min_D = minimum displacement of a valid element
%     min_T = minimum duration of a valid element
%     min_V = velocity corresponding to the instrumental error capture
%
% Output:
%     variable_table = table with MED variables for output
% -------------------------------------------------------------------------

variable_table = table;

dim = size(r, 2);                                                          % Number of dimensions of the data

n = zeros(dim, 1); nt = n; w = n; r2 = n; peak = n;

for i = 1 : dim
    ME_i = segment_MED(t, r(:, i), v(:, i), min_D, min_T, min_V);          % Finds the frames that occur valid motion elements in the i-dimension

    if isempty(ME_i)
        continue
    end

    [n(i), nt(i), D{i}, V{i}, ~, waux, r2aux, ...                    % Check the MED variables for this i-dimension
        peakaux] = analyze_elements_MED(r(:, i), v(:, i), t, ME_i);
    w(i) = mean(waux);
    r2(i) = mean(r2aux);
    peak(i) = mean(peakaux);
end

if isempty(min_N)
    min_N = 1;
end

if isempty(min_r2alpha)
    min_r2alpha = -1;
end

if sum(n) >= min_N
   
    D = cell2mat(D);
    V = cell2mat(V);
    r2alpha = (corr(log10(D)', log10(V)'))^2;

    if r2alpha >= min_r2alpha
        nt_mean = sum(nt.*n) / sum(n);                                         % Calculating mean of the MED variables of each dimension
        w_mean = sum(w.*n) / sum(n);
        r2_mean = sum(r2.*n) / sum(n);
        peak_mean = sum(peak.*n) / sum(n);
    else
        return;
    end

else
    return;
end

variable_table.ind = name;                                                 % Filling in the variables table
variable_table.w = w_mean;
variable_table.r2 = r2_mean;
variable_table.peak = peak_mean;
variable_table.nt = nt_mean;
variable_table.n = sum(n);
variable_table.r2_alpha = r2alpha;
end
