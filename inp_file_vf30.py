import numpy as np
import json
import os

# Define the list of .npy files and corresponding directories
structs = [
    ('vf_30/F30_6700_structs.npy', 'inp_files/inp_F30', 'F30'),
    ('vf_30/FA30_6700_structs.npy', 'inp_files/inp_FA30', 'FA30'),
    ('vf_30/FAAA30_6700_structs.npy', 'inp_files/inp_FAAA30', 'FAAA30'),
    ('vf_30/FC30_6700_structs.npy', 'inp_files/inp_FC30', 'FC30'),
    ('vf_30/FCCC30_6700_structs.npy', 'inp_files/inp_FCCC30', 'FCCC30')
]

# Constants
size = (256, 256)
E0 = 3.45e9
P0 = 0.35
E1 = 276e9
E2 = 26e9
G12 = 20.7e9
G23 = 7.55e9
P1 = 0.292

# Read the template file once
with open("sve_mp_stress.i", "r") as f:
    base_template = f.read()

# Process each .npy file and structure
for struct_path, directory, outdirectory in structs:
    # Load the .npy file using memory mapping for efficiency
    microstructures = np.load(struct_path, mmap_mode='r')
    microstructures = microstructures[:5] # just take the first five structures per class
    # Process each structure in the file
    for i in range(microstructures.shape[0]):
        arr = microstructures[i]
        # Compute black and white pixel counts
        black_pixels = np.sum(arr == 1)
        white_pixels = np.sum(arr == 0)
        # Compute volume fractions
        volume_fraction_black = black_pixels / (256 * 256)
        volume_fraction_white = white_pixels / (256 * 256)
        print(f"Processing structure {i} in {directory}:")
        print("Volume Fraction of Black Phase:", volume_fraction_black)
        print("Volume Fraction of White Phase:", volume_fraction_white)
        # Prepare subdomain IDs for the template
        nx, ny = arr.shape
        subdomain_ids = "'" + json.dumps(arr.tolist()).replace("[", "").replace("],", "\n").replace("]", "").replace(",", "") + "'"

        # Modify the template with structure-specific values
        customized_template = base_template.replace(r"{{nx}}", str(nx))
        customized_template = customized_template.replace(r"{{ny}}", str(ny))
        customized_template = customized_template.replace(r"{{E0}}", str(E0))
        customized_template = customized_template.replace(r"{{P0}}", str(P0))
        customized_template = customized_template.replace(r"{{E1}}", str(E1))
        customized_template = customized_template.replace(r"{{P1}}", str(P1))
        customized_template = customized_template.replace(r"{{E2}}", str(E2))
        customized_template = customized_template.replace(r"{{G12}}", str(G12))
        customized_template = customized_template.replace(r"{{G23}}", str(G23))
        customized_template = customized_template.replace(r"{{base_name}}", f"arr_{i}")
        customized_template = customized_template.replace(r"{{subdomain_ids}}", subdomain_ids)
        customized_template = customized_template.replace(r"{{out_dir}}", outdirectory)
        # Define the output file path for the current structure
        output_file_path = os.path.join(directory, f"arr_{i}.i")

        # Write the customized input file
        with open(output_file_path, "w") as f:
            f.writelines(customized_template)

        print(f"Created {output_file_path}")
