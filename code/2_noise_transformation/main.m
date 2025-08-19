% main.m
%
% Principal script for the Laplace-Beltrami transformation of the noise signals.
%
%Last edited: 23/07/2025, Sabrina Strazzeri (sstrmui@itaca.upv.es)
%-------------------------------------------------------------------------


for i=1:length(files)

    %% Interpolate noise signals
    cd('..\..\data\noise_signals')
    files = dir('*.mat');
    signal= interpolate_signals(files);

    %% Transform the interpolated signals to Laplace-Beltrami coefficients

    % Load torso and heart geometry
    load('data_demo.mat');
    clear bspm

    % Torso.bspmCoord must have 128 coordinates
    vertices = double(Torso.vertices);
    pts_BSPM_base = vertices(Torso.bspmCoord, :);
    params.num_modes_total = 128; % Number of LB modes to calculate

    % Calculate LB base
    [Lc_full, ~] = mesh_tufted_laplacian_free(pts_BSPM_base);
    opts.isreal = true; opts.issym = true;
    [V_eig_full, D_eig_full] = eigs(Lc_full, params.num_modes_total, 'smallestabs', opts);

    % Organize and select modes
    eigen_values = abs(diag(D_eig_full));
    [~, sort_idx] = sort(eigen_values);
    Psi_lb_full = V_eig_full(:, sort_idx);

    % Calculate LB coefficients
    [coeffs_lb] = transform_to_LBcoeffs(signal, Torso, vertices, Psi_lb_full);

    %% Save LB coefficients

    cd('..\..\data\LBcoeffs')
    signal.coeffs_lb = coeffs_lb;
    signal.Psi_lb = Psi_lb_full;
    save(files(i).name, "signal");

    disp('--------------------------------------------------------')
    disp('Case ' + string(files(i).name) + ' has been saved.')
    disp('--------------------------------------------------------')
    disp(' ')

end