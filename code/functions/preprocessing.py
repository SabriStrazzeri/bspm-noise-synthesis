import numpy as np


def split_data(coeffs, seed=42):
    """
    Splits input coefficient matrices into smaller batches, discards
    zero-padded entries, and normalizes the data.

    This function takes a list of coefficient matrices, splits each
    matrix horizontally into four smaller segments, filters out segments
    that are predominantly zero-padded, normalizes the remaining segments
    to a [0, 1] range, and then shuffles the entire dataset.

    Args:
        coeffs (list of np.ndarray): A list of original coefficient matrices,
                                     each expected to be of shape (128, 10000).
        seed (int, optional): Seed for the random number generator to ensure
                              reproducible shuffling. Defaults to 42.

    Returns:
        np.ndarray: A NumPy array containing the processed, normalized,
                    and shuffled coefficient segments, each of shape (128, 2500).
    """

    # Split data into smaller batches (e.g., 128x10000 --> 128x2500)
    coeffs2 = []

    for mat in np.array(coeffs):
        split_matrices = np.array_split(mat, 4, axis=1)
        coeffs2.extend(split_matrices)
    coeffs2 = np.array(coeffs2)

    # Discard cases with more than 5% zero-padding (represented as 0.5 after
    # an initial normalization, if applicable, or actual zeros) and normalize
    # each valid matrix to a [0, 1] range
    # This step helps to avoid training on predominantly empty data
    data = []

    for mat in coeffs2:
        proportion_of_zeros = np.sum(mat == 0) / mat.size
        if proportion_of_zeros <= 0.05:
            # Normalize data to a [0, 1] range
            mat = mat / np.max(abs(mat)) / 2 + 0.5 * np.ones(mat.shape)
            data.append(mat)
    data = np.array(data)

    # Convert to a NumPy array and shuffle the dataset
    np.random.seed(seed)
    shuffled_indices = np.random.permutation(len(data))
    data = data[shuffled_indices]

    return data


def decimate_data(coeffs, seed=42):
    """
    Trims zero-padding from coefficient matrices, decimates them, splits
    them into smaller fixed-size samples, and normalizes the data.

    This function processes raw coefficient matrices by first removing
    zero-padded sections based on the first row, then downsampling (decimating)
    the data by a factor of 2. Finally, it splits the longer decimated
    matrices into fixed-size chunks (128x2500), normalizes each chunk
    to a [0, 1] range, and shuffles the resulting dataset.

    Args:
        coeffs (list of np.ndarray): A list of original coefficient matrices.
                                     Expected to be of shape (128, N) where N
                                     can vary, but typically includes padding.
        seed (int, optional): Seed for the random number generator to ensure
                              reproducible shuffling. Defaults to 42.

    Returns:
        np.ndarray: A NumPy array containing the processed, decimated, normalized,
                    and shuffled coefficient samples, each of shape (128, 2500).
    """

    trimmed_coeffs = []

    # Delete zero padding: identify and remove leading/trailing zeros
    # This assumes zero-padding is indicated by zeros in the first row
    for mat in np.array(coeffs):
        first_row = mat[0, :]

        # Search for the first and last non-zero indices in the first row
        nonzero_indices = np.where(first_row != 0)[0]

        if nonzero_indices.size == 0:
            # If the matrix is entirely zero-padded, discard it
            continue

        start_idx = nonzero_indices[0]
        end_idx = nonzero_indices[-1] + 1  # Include the last non-zero index

        trimmed_mat = mat[:, start_idx:end_idx]
        trimmed_coeffs.append(trimmed_mat)

    # Decimation: downsample the trimmed matrices by a factor of 2
    coeffs2 = [m[:, ::2] for m in trimmed_coeffs]

    # Split into smaller samples (e.g., 128xN --> 128x2500) and normalize
    data = []
    for mat in coeffs2:
        total_cols = mat.shape[1]  # Total number of columns in the matrix
        num_chunks = total_cols // 2500  # Number of 2500-column chunks
        for i in range(num_chunks):
            # Extract a chunk of 2500 columns
            chunk = mat[:, i*2500: (i+1)*2500]
            # Normalize data to a [0, 1] range
            chunk = chunk / np.max(abs(chunk)) / 2 + 0.5 * np.ones(chunk.shape)
            data.append(chunk)

    # Convert to a NumPy array and shuffle the dataset
    np.random.seed(seed)
    shuffled_indices = np.random.permutation(len(data))
    data = np.array(data)
    data = data[shuffled_indices]

    return data
