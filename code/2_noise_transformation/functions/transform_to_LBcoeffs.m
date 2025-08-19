function [coeffs_lb] = transform_to_LBcoeffs(signal, Torso, vertices, Psi_lb_full)
%transform_to_LBcoeffs: 
%
%Inputs:
% - signal: Structure containing the interpolated noise signals, ECG, lead status, and torso.
%
%Outputs:
% - coeffs_lb: Laplace-Beltrami coefficients. 
%
%Code created by: Ismael Hernández (isherro@itaca.upv.es)
%Last edited: 23/07/2025, Sabrina Strazzeri (sstrmui@itaca.upv.es)

%-------------------------------------------------------------------------

% Initialize variables
bspmCoord = Torso.bspmCoord;
noise = signal.noise;
interpolation = 0;

if interpolation == 1 % If the signals are interpolated, all leads are valid
    leadStatus = ones(1,128); 
else % If the signals were not interpolated, then the lead status is considered to determine which leads are valid
    leadStatus = signal.leadStatus;
end

bspm_input_full = double(noise(leadStatus==1, :));
bspm_coords_indices = bspmCoord(leadStatus==1);
pts_BSPM_current = vertices(bspm_coords_indices, :);

% Get the rows of the LB base that correspond to the valid leads
Psi_lb_reduced = Psi_lb_full(leadStatus == 1, :);  % (N_valid_leads x 128)

% Projection
AA_lb = pinv(Psi_lb_reduced);
coeffs_lb = AA_lb * bspm_input_full;


%% Visualize LB coefficients (optional)

%  Define parameters
coeff_plot_modes = 1:params.num_modes_total;
coeff_colormap = 'turbo';

% Represent the LB coefficients
figure('Name', 'Comparación Coeficientes LB: Original vs Estimado', 'Visible','off');
% Plot LB coefficients
ax_orig = subplot(211);
imagesc(coeffs_lb(coeff_plot_modes, :));
set(gcf,"Position", [749 224.2000 396.8000 391.2000])
set(ax_orig, 'YDir', 'normal');
colormap(ax_orig, coeff_colormap);
caxis('auto');
title(sprintf('LB coefficients (Mode %d-%d)', coeff_plot_modes(1), coeff_plot_modes(end)));
ylabel('LB mode');
xlabel('Time (s)');
colorbar east ;
grid on;
% Plot temporal signal
subplot(212);
plot(noise(leadStatus==1, :)')
xlabel('Time (s)');
ylabel('Amplitude')
grid on;
axis tight
ylim([-1, 1])
title(sprintf('Temporal signal'));


end