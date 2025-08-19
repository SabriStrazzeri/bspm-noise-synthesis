function [signal] = interpolate_signals(files)
%interpolate_signals: Interpolates the 2D BSPM of a signal and applies inpainting using regionfill.
%
%Inputs:
% - files: Array of file structures containing the signal data. Easy way to obtain it is to use dir('*.mat').
%
%Outputs:
% - signal: Structure containing the interpolated noise signals, ECG, lead status, and torso.
%
%Last edited: 23/07/2025, Sabrina Strazzeri (sstrmui@itaca.upv.es)
%-------------------------------------------------------------------------

clear signal

%% Load data
noise = load(files(i).name).signal.noise;
lead_status = load(files(i).name).signal.leadStatus;
ecg = load(files(i).name).signal.ECG;
torso = load(files(i).name).signal.torso;


%% Convert to 2D and obtain bspm indices

% Definition of the variables
rows = 9; columns = 18; frames = 10000;

% Convert BSPM to 2D image
[noise_norm, indices_bspm] = bspmTo2D(noise, frames);

% Estimate original indices
indices_validity_map = reshape(indices_bspm, [rows, columns]);
indices_validity_map = flipud(indices_validity_map);

% Apply inpainting to the 2D image
[new_noise, lead_validity_map, ~] = adapted_inpainting(noise_norm, indices_bspm, lead_status);

disp('Case ' + string(i) + ' completed.')
disp('---------------------------------------');
disp(' ');


%% Re-convert to matrix

% Filter valid leads (162 leads to 128 leads)
new_noise_mat = reshape(new_noise, [], length(new_noise));  % 162 x 10000
valid_mask = (lead_validity_map == 1) | (lead_validity_map == 0);  % Logical mask 9x18

% Obtain signals corresponding to those valid leads
interpolated_noise = new_noise_mat(valid_mask(:), :);  % Only the 128 valid ones

% indices_validity_map contains the number of the original lead
lead_numbers_valid = indices_validity_map(valid_mask);


%% Save new data
cd('\data_inpainting')
signal.noise = interpolated_noise;
signal.ECG = ecg;
signal.leadStatus = lead_status;
signal.torso = torso;