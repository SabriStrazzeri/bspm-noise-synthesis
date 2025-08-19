import os
import numpy as np
import time
# Don't forget to change directory to the MATLAB engine path to ensure it can be imported.
import matlab.engine

def load_data(dataset_path): 
    """
    Loads BSPM noise signals data from .mat files within a specified directory
    using a MATLAB engine.

    This function iterates through all .mat files in the given directory,
    loads each file using a MATLAB engine instance, and extracts specific
    noise signals and coefficients.

    Args:
        dataset_path (str): The path to the directory containing the .mat data files.

    Returns:
        tuple: A tuple containing five lists of NumPy arrays:
            - coeffs_lb (list of np.ndarray): List of Laplace-Beltrami coefficients.
            - noise (list of np.ndarray): List of noise temporal signals.
            - ecg (list of np.ndarray): List of ECG signals.
            - lead_status (list of np.ndarray): List of lead status arrays.
            - torso (list of np.ndarray): List of torso data.
    """

    start_time = time.time()
    print("Loading data...")

    # Initialize MATLAB engine
    eng = matlab.engine.start_matlab()

    # Create lists to store data
    noise = []
    ecg = []
    lead_status = []
    torso = []
    coeffs_lb = []

    # Load all data files
    for files in os.listdir(dataset_path):
        if files.endswith('.mat'):
            # Load the .mat file using MATLAB engine
            mat = eng.load(files)
            # Extract the relevant data from the loaded .mat file
            noise.append(np.array(mat['signal']['noise']))
            ecg.append(np.array(mat['signal']['ECG']))
            lead_status.append(np.array(mat['signal']['leadStatus']))
            torso.append(np.array(mat['signal']['torso']))
            coeffs_lb.append(np.array(mat['signal']['coeffs_lb']))

    print("Data loaded in %s seconds" % (time.time() - start_time))
    
    
    return coeffs_lb, noise, ecg, lead_status, torso