import numpy as np
import tensorflow as tf
import time
import matplotlib.pyplot as plt
import os
from IPython.display import clear_output
from visualization import *
from generators import *
from discriminators import *

def train_wgan(
        X_train, type_gan, rows, cols, latent_dim,
        epochs,  batch_size, steps_per_epoch, num_training_samples,  optimizer_d, optimizer_g,
        BASE_DIR,
        sample_interval=5, 
        n_critic=5, lambda_gp=10, 
        start_epoch=0,
        scheduler=1):
    
    """
    Trains a Wasserstein Generative Adversarial Network with Gradient Penalty (WGAN-GP).

    This function implements the training loop for a WGAN-GP, including
    discriminator (critic) and generator updates, gradient penalty calculation,
    learning rate scheduling, model saving, and visualization of training progress.

    Args:
        X_train (tf.Tensor or np.ndarray): The training data (real images/samples).
                                           Expected to be normalized to [0, 1].
        type_gan (str): A string indicating the type of GAN, used for directory naming
                        (in this case, only 'wgan' is considered valid. Previous versions
                        of the code also accepted 'dcgan' as an option).
        rows (int): The number of rows in the generated/real images.
        cols (int): The number of columns in the generated/real images.
        latent_dim (int): The dimension of the latent space (noise vector)
                          input to the generator.
        epochs (int): The total number of training epochs to run.
        batch_size (int): The number of samples per training batch.
        steps_per_epoch (int): The number of training steps (batches) per epoch.
        num_training_samples (int): The total number of samples in the training dataset.
        optimizer_d (tf.keras.optimizers.Optimizer): The optimizer for the discriminator (critic).
        optimizer_g (tf.keras.optimizers.Optimizer): The optimizer for the generator.
        sample_interval (int, optional): The frequency (in epochs) at which to
                                         generate and save sample images. Defaults to 5.
        n_critic (int, optional): The number of discriminator updates per generator update.
                                  Defaults to 5.
        lambda_gp (float, optional): The gradient penalty coefficient. Defaults to 10.
        start_epoch (int, optional): The epoch number to start training from. Useful for
                                     resuming training. Defaults to 0.
        scheduler (int, optional): Flag to enable (1) or disable (0) the
                                   manual learning rate scheduler for the generator.
                                   Defaults to 1.

    Returns:
        tuple: A tuple containing lists of average losses per epoch:
            - avg_disc_real_losses (list): Average critic loss for real samples (Wasserstein term).
            - avg_gen_losses (list): Average generator loss.
            - avg_gp_losses (list): Average gradient penalty loss.
    """
    
    start_time = time.time()
    print("Training WGAN...")

    # Store original data range for visualization purposes (assuming 0-1 normalization)
    original_data_min = np.min(X_train)
    original_data_max = np.max(X_train)
    X_train = X_train.astype(np.float32)

    # Setup directories for saving trained models and generated figures
    models_path = os.path.join(BASE_DIR, 'models')
    os.makedirs(models_path, exist_ok=True) # Create if doesn't exist
    specific_models_path = os.path.join(models_path, type_gan)
    os.makedirs(specific_models_path, exist_ok=True) # Create if doesn't exist
    print(f"Model directory '{specific_models_path}' ready!")

    # Initialize generator and discriminator models
    generator = gen_model_wcgan(latent_dim)
    discriminator = disc_model_critic(rows, cols)

    # Initialize variable to keep track of the best generator loss for saving
    best_gen_loss = float('inf')    

    # Initialize lists to store average metrics for the entire training duration
    avg_disc_real_losses = [] # Stores average critic loss for each epoch
    avg_gen_losses = []       # Stores average generator loss for each epoch
    avg_gp_losses = []        # Stores average GP loss for each epoch

    # Manual Learning Rate scheduler parameters
    lr_history = []
    PATIENCE_LIMIT = 70  # Number of epochs with no improvement before reducing LR
    DELTA = 1e-4  # Minimum change to qualify as improvement
    MIN_LR = 1e-5  # Lower bound for LR
    previous_loss = float('inf')  # Initialize with infinity to ensure first epoch is an improvement
    patience_counter = 0 # Counter for non-improving epochs


    for epoch in range(start_epoch, start_epoch + epochs): 
        print(f"###### @ Epoch {epoch + 1}/{epochs}")

        # Initialize lists to store metrics for the current epoch's batches.
        epoch_disc_losses_local = [] 
        epoch_gen_losses_local = []  
        epoch_gp_losses_local = []   

        # Shuffle the indices of the dataset for random batching at the start of each epoch
        shuffled_indices = np.random.permutation(num_training_samples)

        # Iterate over batches for the current epoch.
        for step in range(steps_per_epoch):
            # Get indices for the current batch.
            batch_indices = shuffled_indices[step * batch_size : (step + 1) * batch_size]

            # Handle potential empty last batch
            if len(batch_indices) == 0:
                continue 
            real_images_batch = tf.constant(X_train[batch_indices]) 

            # ## Train the Critic (n_critic times per batch)
            for _ in range(n_critic): 
                # Generate new noise for each critic update
                noise_for_critic = tf.random.normal(shape=(tf.shape(real_images_batch)[0], latent_dim)) 

                with tf.GradientTape() as tape: 
                    # Generate fake images using the generator
                    generated_imgs = generator(noise_for_critic, training=True) 
                    
                    # Get predictions from discriminator for real and fake images
                    real_predictions = discriminator(real_images_batch, training=True) 
                    fake_predictions = discriminator(generated_imgs, training=True) 

                    # Calculate critic loss (Wasserstein distance term)
                    critic_loss = tf.reduce_mean(fake_predictions) - tf.reduce_mean(real_predictions)

                    # Calculate gradient penalty
                    gp = gradient_penalty(discriminator, real_images_batch, generated_imgs, lambda_gp)

                    # Total critic loss is Wasserstein disance term plus Gradient Penalty
                    critic_loss_total = critic_loss + gp

                # Compute and apply gradients to the critic's trainable variables
                critic_grads = tape.gradient(critic_loss_total, discriminator.trainable_variables)
                optimizer_d.apply_gradients(zip(critic_grads, discriminator.trainable_variables))
                
                # Store losses for this critic update
                epoch_disc_losses_local.append(critic_loss.numpy()) 
                epoch_gp_losses_local.append(gp.numpy())

            # ## Train the Generator (once per batch, after n_critic critic updates)
            # Generate new noise for the generator update
            noise_for_generator = tf.random.normal(shape=(tf.shape(real_images_batch)[0], latent_dim)) 

            with tf.GradientTape() as tape: 
                generated_imgs = generator(noise_for_generator, training=True)
                fake_predictions = discriminator(generated_imgs, training=True)
                # Generator loss: the generator wants to maximize the discriminator's output
                # for fake images, so it minimizes the negative of this value
                gen_loss = -tf.reduce_mean(fake_predictions)

            # Compute and apply gradients to the generator's trainable variables
            gen_grads = tape.gradient(gen_loss, generator.trainable_variables)
            optimizer_g.apply_gradients(zip(gen_grads, generator.trainable_variables)) # Prevents exploding gradients
            
            # Store loss for this generator update
            epoch_gen_losses_local.append(gen_loss.numpy())

        # ## Show and Store Metrics (once per epoch)
        avg_disc_loss_epoch = np.mean(epoch_disc_losses_local)
        avg_gen_loss_epoch = np.mean(epoch_gen_losses_local)
        avg_gp_loss_epoch = np.mean(epoch_gp_losses_local)

        # ## Apply learning rate scheduler if enabled
        if scheduler:
            current_lr = float(tf.keras.backend.get_value(optimizer_g.lr))

            # Check if the generator's loss has improved
            if avg_gen_loss_epoch > previous_loss - DELTA: 
                patience_counter += 1 
            else:
                patience_counter = 0
                previous_loss = avg_gen_loss_epoch 

            # If patience limit is reached, reduce learning rate
            if patience_counter >= PATIENCE_LIMIT: 
                new_lr = max(current_lr * 0.9, MIN_LR) 
                tf.keras.backend.set_value(optimizer_g.lr, new_lr) 
                print(f"Generator learning rate reduced to {new_lr:.6f}")
                patience_counter = 0  

        # Save the weights of the best generator based on its loss
        # Only start saving after a certain number of epochs to allow for initial convergence
        if avg_gen_loss_epoch < best_gen_loss and epoch > 1500:
            best_gen_loss = avg_gen_loss_epoch
            generator.save(os.path.join(specific_models_path, 'best_generator.h5'))
        
        # Print current epoch's average losses
        print(f"Epoch {epoch + 1}/{epochs} - Losses: "
              f"Critic: {avg_disc_loss_epoch:.4f}, "
              f"Generator: {avg_gen_loss_epoch:.4f}, "
              f"Gradient Penalty: {avg_gp_loss_epoch:.4f}")
        
        # Append the calculated epoch averages to the overall lists for plotting later
        avg_disc_real_losses.append(avg_disc_loss_epoch)
        avg_gen_losses.append(avg_gen_loss_epoch)
        avg_gp_losses.append(avg_gp_loss_epoch)

        # Save the loss history per epoch to a file
        results_path = os.path.join(BASE_DIR, 'results')
        os.chdir(results_path)
        np.savez('loss_history.npz',
                disc_loss=np.array(avg_disc_real_losses),
                gen_loss=np.array(avg_gen_losses),
                gp_loss=np.array(avg_gp_losses)
                )

        # ## Monitor Results (sample generation and saving)
        if (epoch + 1) % sample_interval == 0:
            clear_output(wait=True) # Clears output in notebooks for cleaner display
            print(f"Generating sample images at Epoch {epoch + 1}...")
            # Generate sample images using a new random noise for visualization
            sample_noise = tf.random.normal(shape=(4, latent_dim)) # Using new noise for now
            generated_samples = generator.predict(sample_noise, verbose=0)
            generated_samples_display = generated_samples 
            
            # Plot and save generated samples
            plt.figure(figsize=(10, 8))
            for i in range(generated_samples_display.shape[0]):
                plt.subplot(2, 2, i + 1)
                plt.imshow(generated_samples_display[i, :, :, 0], cmap='turbo', origin='lower', aspect='auto', 
                           vmin=original_data_min, vmax=original_data_max) 
                plt.title(f"Generated (Epoch {epoch + 1})")
                plt.colorbar() 
                plt.xlabel("Tiempo (s)")
                plt.ylabel("Modo LB")
            plt.tight_layout()
            plt.savefig(os.path.join(specific_models_path, f'generated_epoch_{epoch+1:04d}.png'))
            plt.show() 

        # Save curent state of generator and discriminator models after each epoch
        generator.save(os.path.join(specific_models_path, 'generator.h5'))
        discriminator.save(os.path.join(specific_models_path, 'discriminator.h5'))

        # Check and save updated generator learning rate
        current_lr = float(tf.keras.backend.get_value(optimizer_g.lr))
        lr_history.append(current_lr) 
        print(f"Generator LR after epoch {epoch+1}: {current_lr:.6f}")

    # Save the history of generator learning rates across all epochs
    np.save(os.path.join(specific_models_path, 'lr_history.npy'), np.array(lr_history))

    final_end_time = time.time() 
    print(f"Training done in {final_end_time - start_time:.2f} seconds")

    # ## Visualize Results (Loss Plots)
    # Setup directory for saving figures
    figures_path = os.path.join(BASE_DIR, 'figures')
    os.makedirs(figures_path, exist_ok=True)
    
    # Plot all losses on a single graph
    plt.figure(figsize=(10, 5))
    plt.plot(avg_disc_real_losses, label="Critic Loss (Wasserstein)") 
    plt.plot(avg_gen_losses, label="Generator Loss")
    plt.plot(avg_gp_losses, label="Gradient Penalty")
    plt.ylabel("Loss")
    plt.title("WGAN-GP Losses During Training (Per Epoch)")
    all_losses = avg_disc_real_losses + avg_gen_losses + avg_gp_losses
    if all_losses: 
        min_loss = np.min(all_losses)
        max_loss = np.max(all_losses)
        plt.ylim([min_loss - abs(min_loss * 0.1), max_loss + abs(max_loss * 0.1)])
    else:
        plt.ylim([-5, 5]) 
    plt.xlabel("Epoch")
    plt.legend()
    plt.savefig(os.path.join(figures_path, 'losses_per_epoch.png'))
    plt.show()

    # Separate plot for critic loss
    plt.figure(figsize=(8, 4))
    plt.plot(avg_disc_real_losses, label="Critic Loss (Wasserstein)", color='red')
    plt.ylabel("Loss")
    plt.xlabel("Epoch")
    plt.title("Critic Loss During Training (Per Epoch)")
    plt.grid(True)
    plt.savefig(os.path.join(figures_path, 'critic_loss.png'))
    plt.close()

    # Separate plot for geenrator loss
    plt.figure(figsize=(8, 4))
    plt.plot(avg_gen_losses, label="Generator Loss", color='blue')
    plt.ylabel("Loss")
    plt.xlabel("Epoch")
    plt.title("Generator Loss During Training (Per Epoch)")
    plt.grid(True)
    plt.savefig(os.path.join(figures_path, 'generator_loss.png'))
    plt.close()

    # Separate plot for gradient penalty
    plt.figure(figsize=(8, 4))
    plt.plot(avg_gp_losses, label="Gradient Penalty", color='green')
    plt.ylabel("Loss")
    plt.xlabel("Epoch")
    plt.title("Gradient Penalty During Training (Per Epoch)")
    plt.grid(True)
    plt.savefig(os.path.join(figures_path, 'gradient_penalty.png'))
    plt.close()


    # Return the accumulated epoch-wise losses for potential further analysis
    return avg_disc_real_losses, avg_gen_losses, avg_gp_losses
