from keras.models import Sequential
from keras.layers import Conv2DTranspose, Dense, Reshape, LeakyReLU, Conv2DTranspose, BatchNormalization, Conv2D, Activation, Cropping2D


def gen_model_wcgan(latent_dim):
    """
    Constructs a generator model for a WGAN (Wasserstein Generative Adversarial Network).

    This generator model takes a latent vector as input and upsamples it through
    a series of transposed convolutional layers to generate synthetic images (or
    data representations) with a target shape of (128, 2500, 1). The architecture
    includes Dense, Reshape, Conv2DTranspose, BatchNormalization, LeakyReLU,
    Cropping2D, Conv2D, and Activation layers.

    Args:
        latent_dim (int): The dimensionality of the input latent vector (noise).

    Returns:
        keras.Model: A Keras Sequential model representing the generator.
    """

    model = Sequential()

    # Initial Dense layer to transform the latent vector into a suitable shape
    # for the first transposed convolutional layer.
    model.add(Dense(16 * 320, activation="relu", input_dim=latent_dim))
    model.add(Reshape((16, 320, 1)))  

    # First transposed convolutional block: Upsamples to 32x640
    model.add(Conv2DTranspose(128, kernel_size=5, strides=2, padding="same"))
    model.add(BatchNormalization(momentum=0.8)) # Stabilizes training
    model.add(LeakyReLU(alpha=0.2)) # Non-linear activation

    # Second transposed convolutional block: Upsamples to 64x1280
    model.add(Conv2DTranspose(64, kernel_size=5, strides=2, padding="same"))
    model.add(BatchNormalization(momentum=0.8)) # Stabilizes training
    model.add(LeakyReLU(alpha=0.2)) # Non-linear activation

    # Third transposed convolutional block: Upsamples to 128x2560
    model.add(Conv2DTranspose(32, kernel_size=3, strides=2, padding="same"))
    model.add(BatchNormalization(momentum=0.8)) # Stabilizes training
    model.add(LeakyReLU(alpha=0.2)) # Non-linear activation

    # Fourth transposed convolutional block: Maintains spatial dimensions (128x2560)
    model.add(Conv2DTranspose(16, kernel_size=3, strides=1, padding="same"))
    model.add(LeakyReLU(alpha=0.2)) # Non-linear activation

    # Fifth transposed convolutional block: Maintains spatial dimensions (128x2560)
    model.add(Conv2DTranspose(8, kernel_size=3, padding="same"))
    model.add(LeakyReLU(alpha=0.2)) # Non-linear activation

    # Cropping layer to adjust the width from 2560 to the target 2500.
    model.add(Cropping2D(cropping=((0, 0), (0, 60))))

    # Final convolutional layer to output a single channel image.
    model.add(Conv2D(1, kernel_size=1, padding="same"))

    # Sigmoid activation to scale output values to [0, 1], suitable for
    # generating data that was normalized to this range.
    model.add(Activation("sigmoid")) 


    # Prints a summary of the model's architecture, including layer types,
    # output shapes, and number of parameters.
    print(f"######### Generator Summary #########")
    model.summary()


    return model