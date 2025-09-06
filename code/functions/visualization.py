from matplotlib import pyplot as plt
import numpy as np
import os


def plot_LB_coefficients(coeffs, case_index, BASE_DIR, save_mode=0):
    """
    Plot LB (Laplacian Basis) coefficients as a heatmap over time and modes.

    Parameters:
    -----------
    coeffs : ndarray
        2D array of LB coefficients with shape (modes, time).
    case_index : int
        Identifier for the case, used in figure naming and time axis definition.
    BASE_DIR : str
        Base directory where the 'figures' folder is located for saving plots.
    save_mode : int, optional (default=0)
        If set to 1, the figure is saved as a PNG in the 'figures' folder.

    Returns:
    --------
    None
        Displays the plot and optionally saves it to disk.
    """

    # Define modes and time array
    modes = np.linspace(1, 128, 128)
    t = np.linspace(1, 5, coeffs.shape[case_index])

    # Plot figure
    plt.figure(figsize=(7, 5))
    plt.imshow(coeffs, aspect='auto', extent=[
               t[0], t[-1], modes[0], modes[-1]], origin='lower', cmap='turbo')
    plt.colorbar(label='Amplitude')
    plt.xlabel("Duration (s)", fontsize=18, fontweight='bold')
    plt.ylabel("LB mode", fontsize=18, fontweight='bold')
    plt.title("LB Coefficients", fontsize=20, fontweight='bold')
    plt.xticks(fontsize=16)
    plt.yticks(fontsize=16)
    plt.grid(True)

    # Save figure
    if save_mode:
        figures_dir = os.path.join(BASE_DIR, 'figures')
        fig_name = "Case_" + str(case_index) + "_LBcoeffs.png"
        plt.savefig(os.path.join(figures_dir, fig_name))

    plt.tight_layout()
    plt.show()


def plot_temporal_signal(signal, case_index, BASE_DIR, save_mode=0):
    """
    Plot a normalized temporal signal over a time axis for a given case.

    Parameters:
    -----------
    signal : ndarray
        2D array containing temporal signal data.
    case_index : int
        Identifier for the case, used in figure naming and time axis definition.
    BASE_DIR : str
        Base directory where the 'figures' folder is located for saving plots.
    save_mode : int, optional (default=0)
        If set to 1, the figure is saved as a PNG in the 'figures' folder.

    Returns:
    --------
    None
        Displays the plot and optionally saves it to disk.
    """

    # Renormalization to [-1, 1]
    min_val = np.min(signal)
    max_val = np.max(signal)
    signal_norm = 2 * (signal - min_val) / (max_val - min_val) - 1

    # Define time array
    t = np.linspace(1, 5, signal_norm.shape[case_index])

    # Plot
    plt.figure(figsize=(11.5, 4.2))
    plt.plot(t, signal_norm.T)
    plt.ylim([-1, 1])
    plt.xlabel("Duration (s)", fontsize=18, fontweight='bold')
    plt.ylabel("Amplitude", fontsize=18, fontweight='bold')
    plt.title("Generated signal", fontsize=20, fontweight='bold')
    plt.xticks(fontsize=16)
    plt.yticks(fontsize=16)
    plt.grid(True)

    # Save figure
    if save_mode:
        figures_dir = os.path.join(BASE_DIR, 'figures')
        fig_name = "Case_" + str(case_index) + "_temporalSignal.png"
        plt.savefig(os.path.join(figures_dir, fig_name))

    plt.tight_layout()
    plt.show()
