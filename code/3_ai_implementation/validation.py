"""
This script implements a validation pipeline for a Wasserstein Generative Adversarial Network (WGAN)
with Gradient Penalty (GP) for generating synthetic noise BSPM signals.
"""

#%% ---- Libraries and Environment Setup ----

import numpy as np
import os
from tensorflow.keras.models import load_model
import scipy.io as sio
import warnings
warnings.filterwarnings("ignore")

# Define  directories
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
MODELS_DIR = os.path.join(SCRIPT_DIR, 'models')
DATA_DIR = os.path.join(SCRIPT_DIR, 'utils')


# %% ---- Load the generator model ----
# NOTE: due to privacy policies, the trained generator cannot be shared publicly. 

model_path = os.path.join(MODELS_DIR, 'generator.h5')
if not os.path.exists(model_path):
    raise FileNotFoundError(f"Model not found in: {model_path}")
model = load_model(model_path)


# %% ---- Load conversion matrix ----

mat_file = os.path.join(DATA_DIR, 'Psi_lb.mat')
if not os.path.exists(mat_file):
    raise FileNotFoundError(f"Conversion matrix not found in: {mat_file}")
mat_contents = sio.loadmat(mat_file)
Psi_lb = np.array(mat_contents['Psi_lb'])


# %% ---- Generate noise using the generator ----

# Define the noise dimension and the random latent vector.
NOISE_DIM = 128
rnd_latent_vec = np.random.normal(0, 1, (100, NOISE_DIM))

# Generate noise samples (Laplace-Beltrami coefficients)
samples = model(rnd_latent_vec, training=False)
idx = np.random.randint(0, samples.shape[0])
samples = np.squeeze(np.array(samples[idx]))
samples_dn = (samples - 0.5) * 2

# Convert the LB coefficients to temporal signals using the conversion matrix
signal = Psi_lb @ np.squeeze(samples_dn)

# Visualize the obtained signal
plot_temporal_signal(signal, idx, SCRIPT_DIR, save_mode=0)

