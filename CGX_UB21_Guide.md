# CGX Visualization Guide: UB21 Beam Element Results in CalculiX GraphiX

This guide provides complete instructions and command syntax for post-processing and visualizing **UB21 (2-node 3D Timoshenko / Euler-Bernoulli user beam element)** results using **CalculiX GraphiX (CGX 2.23)**.

---

## 1. Quick Overview

When CCX completes a finite element solution with UB21 beam elements, it outputs field results into a standard `.frd` file (`<jobname>.frd`). CGX parses this file to render element geometries, node displacements, internal section forces/moments, and stress components.

---

## 2. Launching CGX

### Interactive GUI Mode (Window Stays Open)
To open CGX in interactive graphical mode and keep the window open for user interaction:

```bash
cgx <jobname>.frd
```
*(Or specify full path: `/home/pierre/CCX-CB/cgx_2.23.all/CalculiX/cgx_2.23/src/cgx <jobname>.frd`)*

> [!NOTE]
> Running CGX with `-b script.fbd` executes commands in batch mode and **automatically closes the window** once finished. For interactive visualization, launch CGX directly on the `.frd` file.

---

## 3. Core CGX Commands for UB21 Beams

Once CGX is open (or inside a batch `.fbd` script):

### Load and Display Mesh
```cgx
read <jobname>.frd       # Load the FRD result deck
view elem                # Show element boundaries
plot elem                # Render element mesh
```

### Viewing Displacements & Deformed Shapes
```cgx
ds 1 e 1                 # Select Dataset 1 (Displacement D1 / UX)
ds 1 e 2                 # Select Dataset 1 (Displacement D2 / UY)
ds 1 e 3                 # Select Dataset 1 (Displacement D3 / UZ)
ds 1 e 4                 # Select Dataset 1 (Total Displacement Magnitude ALL)
plot f                   # Plot field contours on elements
view disp                # Toggle deformed mesh view
scal d 50                # Scale deformation magnitude display (e.g. 50x)
```

> [!IMPORTANT]
> In CGX, the command to scale displacement deformation is **`scal d <scale_factor>`** (e.g., `scal d 50`). Using `scale <val>` scales geometry bounding boxes, not displacement mode shapes!

### Viewing Beam Stresses & Section Forces
```cgx
ds 2 e 1                 # Select Dataset 2 (Direct Axial Stress / Force)
ds 2 e 2                 # Select Bending Stress / Moment My
ds 2 e 3                 # Select Bending Stress / Moment Mz
plot f                   # Display color contour maps
```

---

## 4. Selecting Time Steps & Datasets in CGX

In transient dynamic time-history simulations (`*DYNAMIC`), CCX writes multiple time steps into the `.frd` file as separate **Datasets**.

### Interactive GUI Selection
1. Right-click anywhere in the main graphics window.
2. Navigate to **Datasets** in the drop-down menu.
3. Select the desired **Time Step** or **Load Case** from the list.
4. Select the field entity to plot (e.g. `D1`, `D2`, `D3`, `ALL`).

### Command Line / Batch Selection Syntax

- **Query / List All Datasets & Time Steps**:
  ```cgx
  ds q                       # Queries and prints all available datasets and time values
  ```
  *(Note: Running `ds` alone returns `ERROR: Parameter: not recognized.`. Always use `ds q` to list datasets).*

- **Select a Specific Time Step / Dataset Index**:
  ```cgx
  ds 1                       # Activate Dataset 1 (Required before navigating +/-)
  ds 2                       # Activate Dataset 2
  ```

- **Select a Specific Field Entity/Component**:
  ```cgx
  ds 1 e 2                   # Select Dataset 1, Component 2 (UY)
  ds 1 e 4                   # Select Dataset 1, Component 4 (ALL magnitude)
  ```

- **Step-by-Step Time Step Navigation**:
  *(Note: You must first select an active dataset, e.g. `ds 1 e 2`, before using `+` or `-`)*
  ```cgx
  ds +                       # Jump to NEXT dataset
  ds -                       # Jump to PREVIOUS dataset
  ```

- **Select Range / Sequence of Datasets**:
  ```cgx
  ds 1 1 20                  # Select sequence from dataset #1 to #20 with increment 1
  ds 1 1 20 e 2              # Select dataset range #1 to #20 specifically for entity D2 (UY)
  ```

---

## 5. Sequence Loop Animation across Time Steps

To animate the **actual time-history sequence across consecutive time steps (Time-History Movie Loop)**:

### Interactive GUI Selection
1. Right-click in the graphics window.
2. Navigate to **`Datasets`** $\rightarrow$ **`Sequence`**.
3. Click **`Start`** (or **`Toggle`**).
4. CGX will cycle sequentially through all saved time steps in a continuous loop.

### Command Line Animation Commands

| Command | Action |
| :--- | :--- |
| **`anim seq`** | Start continuous sequence animation loop through selected datasets |
| **`anim seq +`** | Step forward continuously through time steps |
| **`anim real`** | Animate time using real physics time intervals |
| **`anim tune 10`** | Set animation playback frame rate to 10 FPS |
| **`anim start`** | Resume playback loop |
| **`anim stop`** | Pause playback loop on current time step |
| **`anim off`** | Turn off animation |

---

## 6. Complete Dynamic Bending Loop Workflow Example

To open a dynamic beam model and run a smooth continuous loop animation:

1. Launch CGX:
   ```bash
   /home/pierre/CCX-CB/cgx_2.23.all/CalculiX/cgx_2.23/src/cgx testcase/cantilever_bending_smooth.frd
   ```

2. Enter these commands in CGX prompt:
   ```cgx
   ds 1 1 50 e 2    # Select Uy displacement for datasets 1 to 50
   view disp        # Enable deformed shape display
   scal d 50        # Scale displacement by 50x
   anim seq         # Start continuous loop animation
   ```

---

## 7. Understanding CGX Warnings & Notes

- **`WARNING: unallocated component:7 "..."`**:
  - When beam elements with rotational DOFs ($UX, UY, UZ, RX, RY, RZ$) output displacement results, CCX includes a 7th summary component (`ALL`).
  - CGX outputs this warning when reading the 7th component into its 6-DOF internal array.
  - **This is a non-fatal info warning that does NOT affect results or animation playback.**

- **Exporting Hardcopy Screenshot**:
  ```cgx
  hard png         # Saves a high-res PNG image as hcopy_1.png
  ```
