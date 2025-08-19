function [bspm_noise_interpolated, lead_validity_map, interpolated_leads] = adapted_inpainting(BSPMs_norm, indices_bspm, leadStatus)
%adapted_inpainting: Interpolates the 2D BSPM of a signal and applies inpainting using regionfill.
%
%Inputs:
% - BSPMs_norm: 2D BSPM matrix with normalized values.
% - indices_bspm: 1D array with the indices of the leads in the BSPM matrix.
% - leadStatus: 1D array with the status of each lead (1 for valid, 0 or -1 for invalid).
%
%Outputs:
% - bspm_noise_interpolated: 2D BSPM matrix with interpolated values.
% - lead_validity_map: 2D matrix with the validity of each lead (1 for valid, 0 for invalid).
% - interpolated_leads: 2D matrix with the coordinates of the interpolated leads.
%
%Last edited: 07/05/2025, Sabrina Strazzeri (sstrmui@itaca.upv.es)
%-------------------------------------------------------------------------

%% Variable initialization

% Defines the size of the BSPM matrix
[rows, cols, num_frames] = size(BSPMs_norm);
num_leads = 128;

% Convert leadStatus to a binary mask
leadStatus(leadStatus == -1) = 0;


%% Image processing: Create lead validity map 
% Create a 2D mask that is 'true' where data is invalid
% A point is invalid if:
% 1. indices_bspm(k) is not 0 (no electrode mapped here
% 2. OR leadStatus(indices_bspm(k)) is 0 (the mapped electrode is not valid)

disp(' ');
disp('---------------------------------------');
disp('----- Mask -----')

fill_mask_invalid_leads_only = false(rows, cols); % Mask for regionfill
k = 1;
for j = 1:cols
    for i = rows:-1:1
        if k > numel(indices_bspm)
            break;
        end

        lead_index = indices_bspm(k);
        if lead_index == 0
            % Sin sensor: dejamos como NaN
            lead_validity_map(i,j) = NaN;
        elseif lead_index > 0 && lead_index <= num_leads
            if leadStatus(lead_index) == 1
                lead_validity_map(i,j) = 1; % Válido
            else
                lead_validity_map(i,j) = 0; % Inválido
            end
        else
            lead_validity_map(i,j) = NaN;
        end
        k = k + 1;
    end
end

k = 1;
num_points_to_fill = 0;
num_unmapped_points = 0;

for j = 1:cols
    for i = rows:-1:1
        if k > numel(indices_bspm)
            warning('Index k (%d) exceeds length of indices_bspm (%d). Stopping mask creation.', k, numel(indices_bspm));
            break;
        end
        lead_index = indices_bspm(k);

        if lead_index == 0
            % No sensor mapped here, leave as NaN
            num_unmapped_points = num_unmapped_points + 1;
        elseif lead_index > 0 && lead_index <= num_leads
            if leadStatus(lead_index) == 0
                % Sensor mapped but invalid, mark for filling
                fill_mask_invalid_leads_only(i, j) = true;
                num_points_to_fill = num_points_to_fill + 1;
            end
            % If leadStatus is 1, it's valid and we don't fill it
        else
            warning('Índice de lead (%d) fuera de rango [1, %d] encontrado en indices_bspm en k=%d. Tratado como no mapeado.', lead_index, num_leads, k);
            num_unmapped_points = num_unmapped_points + 1;
        end
        k = k + 1;
    end
    if k > numel(indices_bspm); break; end % Salir también del bucle externo
end

fprintf('Mask created:\n');
fprintf(' - Points to interpolate (mapped sensor, but invalid): %d\n', num_points_to_fill);
fprintf(' - Not mapped points (without sensor, not interpolated): %d\n', num_unmapped_points);

if num_points_to_fill == 0
    disp('No invalid leads mapped. No interpolation will be performed.');
end

if num_unmapped_points + num_points_to_fill == rows*cols && num_points_to_fill > 0
    warning('All mapped points are invalid. Interpolation will rely on unmapped edges, which may not be meaningful.');
end


%% Image processing: Inpainting
disp('---------------------------------------');
disp('----- Inpainting -----')

% Initialize the output with the original data
bspm_noise_interpolated = BSPMs_norm;

% Create a mask for unmapped points
k = 1;
unmapped_mask = false(rows, cols);
for j = 1:cols
    for i = rows:-1:1
        if k > numel(indices_bspm); break; end
        if indices_bspm(k) == 0
            unmapped_mask(i,j) = true;
        end
        k = k + 1;
    end
    if k > numel(indices_bspm); break; end
end

% Initialize the list of interpolated leads
interpolated_leads = [];

% Interpolate if there are points to fill
if num_points_to_fill > 0
    fprintf('Iniciando interpolación para %d instantes de tiempo (solo para leads inválidos)...\n', num_frames);
    tic; % Start timer

    for t = 1:num_frames
        % Obtain the 2D map for time instant 't'
        current_slice_raw = BSPMs_norm(:, :, t);

        % Interpolate only the points that are invalid leads
        interpolated_slice = regionfill(current_slice_raw, fill_mask_invalid_leads_only);

        % Save the interpolated slice
        bspm_noise_interpolated(:, :, t) = interpolated_slice;

        % Save the coordinates of the interpolated leads
        [fill_rows, fill_cols] = find(fill_mask_invalid_leads_only);
        interpolated_leads = [interpolated_leads; fill_rows, fill_cols];

    end
    elapsed_time = toc; % Stop timer
    fprintf('Inpainting completed. Total time: %.2f seconds.\n', elapsed_time);
else
    fprintf('Inpainting was not required (num_points_to_fill = 0). Output is the same as input.\n');
end
disp('---------------------------------------');

end
