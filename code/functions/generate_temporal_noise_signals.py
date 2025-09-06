import numpy as np


def generate_temporal_noise_signals(model, Psi_lb, noise_dim, selected_case=1, seed=42, N=30):
    """
    Generates synthetic temporal noise signals and their corresponding
    coefficient samples using a trained GAN generator.

    This function takes a trained generator model and a conversion matrix
    (Psi_lb) to produce new, synthetic data. It generates random latent
    vectors, feeds them to the generator to create coefficient samples,
    denormalizes these coefficients, and then transforms them into
    temporal noise signals using the provided conversion matrix.

    Args:
        model (tf.keras.Model): The trained generator model (e.g., from a WGAN-GP).
        Psi_lb (np.ndarray): The Laplace-Beltrami conversion matrix
                             used to transform coefficient space data into
                             temporal signal space.
        selected_case (int, optional): The index of the specific generated sample
                                       to extract from the batch of N generated samples.
                                       Defaults to 1.
        seed (int, optional): Seed for the random number generator to ensure
                              reproducible generation of latent vectors. Defaults to 42.
        N (int, optional): The number of latent vectors (and thus samples) to
                           generate in a single batch from the generator. Defaults to 30.

    Returns:
        tuple: A tuple containing two NumPy arrays:
            - generated_noise (np.ndarray): The generated temporal noise signal
                                            for the `selected_case`.
            - generated_sample (np.ndarray): The generated coefficient sample
                                             for the `selected_case`.
    """

    # Generate random latent vectors from a standard normal distribution
    # These vectors serve as input to the generator
    np.random.seed(seed)
    random_latent_vectors = np.random.normal(
        0, 1, (N, noise_dim))  # Ruido en distribución normal

    # Use the generator model to create synthetic coefficient samples from the latent vectors
    # `training=False` ensures that batch normalization layers (if any) use their
    # population statistics, and dropout layers are inactive
    generated_samples = model(random_latent_vectors, training=False)

    # Extract the specific generated sample indicated by `selected_case`
    # The shape changes from (N, 128, 2500, 1) to (128, 2500, 1
    generated_samples = np.array(generated_samples[selected_case])

    # Remove the singleton dimension (e.g., (128, 2500, 1) becomes (128, 2500))
    # for easier matrix multiplication and plotting
    generated_sample = np.squeeze(generated_samples)

    # Denormalize the generated coefficient sample
    # Assuming the generator outputs values in [0, 1], this scales them to [-1, 1]
    generated_sample_desnorm = (generated_sample - 0.5) * 2

    # Convert the denormalized coefficient sample into a temporal noise signal
    # using the provided conversion matrix (Psi_lb)
    generated_noise = Psi_lb @ generated_sample_desnorm

    return generated_noise, generated_sample
