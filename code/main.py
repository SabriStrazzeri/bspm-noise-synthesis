"""
This script implements a training pipeline for a Wasserstein Generative Adversarial Network (WGAN)
with Gradient Penalty (GP) for generating synthetic noise BSPM signals.

The pipeline includes:
1.  **Libraries and Environment Setup**: Imports necessary libraries (TensorFlow, NumPy, Matplotlib, SciPy, MATLAB engine)
    and custom utility functions for data loading, preprocessing, training, and visualization.
2.  **Dataset Loading and Preprocessing**: Loads coefficient data and noise signals from MATLAB .mat files.
    It applies either decimation or simple splitting to the data based on a configuration flag,
    preparing it for training.
3.  **Hyperparameter Definition**: Defines key parameters for the GAN training, including:
    -   Number of training epochs.
    -   Batch size.
    -   Optimizers (Adam) for both the generator and discriminator.
    -   Type of GAN ('wgan').
    -   Dimensions of the input data and the latent noise vector.
4.  **Model Training**: Initializes and trains the WGAN-GP model using the preprocessed data and defined hyperparameters.
    It includes configurations for the number of critic updates per generator update, gradient penalty lambda,
    and a learning rate scheduler.
"""

#%% ---- Libraries and Environment Setup ----
# Import necessary libraries for TensorFlow, numerical operations,
# file system interactions, plotting, and signal processing.

import tensorflow as tf
import numpy as np
from tensorflow.keras.optimizers import Adam
import os
import sys

# Don't forget to change directory to the MATLAB engine path to ensure it can be imported.
os.chdir(r'C:\Users\ITACA_2025_1\anaconda3\Lib\site-packages\matlabengine-24.2-py3.12.egg')
import matlab.engine

# Define directories
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
FUNCTIONS_DIR = os.path.join(BASE_DIR, 'functions')

# Load customized functions
sys.path.append(FUNCTIONS_DIR)
from training import *
from load_data import load_data
from visualization import *
from preprocessing import *


#%% ---- Load dataset ----
# Load the dataset using a custom function. The function returns LB 
# coefficients, noise, and lead status information.

# Define seed for reproducibility
seed = 42

# Path where the data files are located
dataset_path = os.path.join(BASE_DIR, 'data', 'LBcoeffs')
os.chdir(dataset_path)

# Load the coefficients, noise signal, and lead status variables
coeffs, noise, _, leadStatus, _ = load_data(dataset_path)

# Determine preprocessing technique based on the decimation flag
decimate = 1

if decimate: 
    data = decimate_data(coeffs, seed)
    noise_2 = decimate_data(noise, seed)
else:
    data = split_data(coeffs, seed)

# Adapt the dimension of the data samples
data = np.expand_dims(data, axis=-1)


#%% ---- Hyperparameters ----

# Number of epochs for training
EPOCHS = 2500 

# Batch size for training
BATCH_SIZE = 32

# Calculate the number of steps per epoch
steps_per_epoch = len(coeffs) // BATCH_SIZE
if steps_per_epoch == 0 and coeffs.shape[0] > 0 :
    steps_per_epoch = 1

# Optimizers for the generator and discriminator
optimizer_g = Adam(learning_rate=1e-4, beta_1=0.5, clipvalue=1.0)
optimizer_d = Adam(learning_rate=1e-4, beta_1=0.5, clipvalue=1.0)

# Dfine the type of GAN to be used ('wgan')
TYPE_GAN = 'wgan'

# Define input data and latent noise vector dimensions 
ROWS, COLS = 128,  2500
NOISE_DIM = 128 


#%% ---- Training ----

tf.keras.backend.clear_session()

sample_interval = 10

# Train the model
avg_disc_real_losses, avg_disc_fake_losses, avg_gen_losses, avg_gp_losses = train_wgan(
    data, TYPE_GAN, ROWS, COLS, NOISE_DIM,
    EPOCHS, BATCH_SIZE, steps_per_epoch, len(data), optimizer_d, optimizer_g, 
    BASE_DIR,
    sample_interval=sample_interval, 
    n_critic = 5, lambda_gp = 5,
    start_epoch = 0, 
    scheduler = 1
)
    