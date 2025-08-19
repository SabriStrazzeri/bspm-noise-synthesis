# 🎛️ BSPM Noise Synthesis with WGAN-GP

This repository focuses on the generation of synthetic BSPM noise signals using a Wasserstein Generative Adversarial Network with Gradient Penalty (WGAN-GP). The project is structured to guide you through the process from raw signal processing to advanced AI-driven synthesis.

## 🚀 Project Overview

This project aims to leverage deep learning, specifically WGAN-GP, to synthesize realistic noise signals. The overall workflow covers data preparation, transformation into a suitable representation (Laplace-Beltrami coefficients), and finally, the training of a generative model.

## 📁 Project Structure

The repository is organized into two main top-level directories: `code` and `data`.

### `code/`
This directory contains all the MATLAB and Python scripts organized by their specific function within the project pipeline.

* #### `1_noise_extraction/` 
    This subfolder contains the code responsible for extracting noise components from raw BSPM signals. This initial step is crucial for isolating the target noise characteristics for subsequent processing. 

    The complete cardiac activity (PQRST) was eliminated thanks to the implementation of the canceller, which is avaiable on the `canceller`subfolder. All necessary functions are included in the `functions` subfolder. 

* #### `2_noise_transformation/` 
    Once noise signals are extracted, the code in this directory transforms them into **Laplace-Beltrami (LB) coefficients**. This transformation provides a more meaningful representation of the signals, keeping their spatial-coherence, which is essential for noise characterization. 

    A `main` MATLAB script is provided with the complete workflow of this implementation. All necessary functions and dependencies are included in the `functions` and `utils` subfolder. 

* #### `3_ai_implementation/` 
    This is the core of the generative modeling. It includes the code for training the **WGAN-GP (Wasserstein Generative Adversarial Network with Gradient Penalty)** architecture to synthesize noise signals. This model learns to generate new, realistic noise patterns from a latent space.

    A `main` Python script is provided with the complete workflow of this implementation. All necessary functions and dependencies are included in the `functions` and `utils` subfolder. 

    In the ``environment.yml`` file, the environment used for the training of the generative model is proposed for easier Anaconda configuration. 


### `data/`
This directory is where all the necessary data for the project must reside. 



## 🏁 Getting Started

To run the code, please note the following:

* **Directory Paths**: You will need to modify directory paths within the scripts to match your local file system. Look for variables like `dir_dataset`, `dir_functions`, `model_path`, etc.
* **Data Availability**:
    * If you intend to use the `1_noise_extraction` and `2_noise_transformation` codes, you **must first place a BSPM dataset** into the `data/` folder. These initial steps are dependent on having the raw BSPM signals available.
    * If you intend to use the `3_ai_implementation` folder to  **train the WGAN-GP model**, you **must first place a Laplace-Beltrami coefficients dataset** into the `data/` folder. These initial steps are dependent on having the Laplace-Beltrami coefficients signals available.
    * If you would like to use the same datasets that were used for the project, these will be available on NextCloud. 



---
Made by Sabrina Strazzeri (sstrmui@itaca.upv.es).