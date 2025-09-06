# EDEN: Electrocardiographic Deep Emulator of Noise

This repository focuses on the generation of synthetic BSPM noise signals using a Wasserstein Generative Adversarial Network with Gradient Penalty (WGAN-GP). The project is structured to guide you through the process from the model training to the validation of the generated samples.

## 🚀 Project Overview

This project aims to leverage deep learning, specifically WGAN-GP, to synthesize realistic noise signals. The overall workflow covers data preparation, transformation into a suitable representation (Laplace-Beltrami coefficients), and finally, the training of a generative model. However, the code provided only includes the last part mentioned due to privacy policies.

## 📁 Project Structure

The repository is organized into two main top-level directories: `code` and `data`.

### `code/`
This is the core of the generative modeling. It includes the code for training the **WGAN-GP (Wasserstein Generative Adversarial Network with Gradient Penalty)** architecture to synthesize noise signals. This model learns to generate new, realistic noise patterns from a latent space.

A `main` Python script is provided with the complete workflow of this implementation. All necessary functions and dependencies are included in the `functions` and `utils` subfolder. 

A `validation` Python script is included to verify the generated images and reconvert them into temporal noise signals. All necessary functions and dependencies are included in the `functions` and `utils` subfolder, the latter one including the conversion matrix to accomplish the conversion from LB coefficients to signals. 

In the ``environment.yml`` file, the environment used for the training of the generative model is proposed for easier Anaconda configuration. 


### `data/`
This directory is where all the necessary data for the project must reside. However, due to privacy policies, sensible data from patietns cannot be publicly shared, so you must add your own files to this folder.


## 🏁 Getting Started

To run the code, please note the following:

* **Directory Paths**: You will need to modify directory paths within the scripts to match your local file system. Look for variables like `dir_dataset`, `dir_functions`, `model_path`, etc.
* **Data Availability**: Due to privacy policies, some files cannot be publicly shared.
    * If you intend to execute the `main.py` script to  **train the WGAN-GP model**, you **must first place a Laplace-Beltrami coefficients dataset** into the `data/` folder. 
    * If you intend to execute the `validation.py` script to **validate the generated samples**, you **must first place a trained generator** into a new `models/` folder. 
