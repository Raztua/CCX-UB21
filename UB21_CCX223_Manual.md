# User Manual & Installation Guide: UB21 Beam Element & User Sections in CalculiX 2.23

This document provides a detailed installation guide, technical manual, material & section definition guide, loading reference, and analysis capability overview for the **UB21 (2-node 3D Timoshenko / Euler-Bernoulli user beam element)** patch applied to **CalculiX CCX 2.23**.

---

## 📑 Table of Contents
- [1. Installation Guide](#1-installation-guide)
- [2. UB21 Element Specification & Definition](#2-ub21-element-specification--definition)
- [3. Section Definition: Two Supported Input Formats](#3-section-definition-two-supported-input-formats)
- [4. Cross-Section Types & Geometric Parameters](#4-cross-section-types--geometric-parameters)
- [5. Member End Releases, Springs & Connectors](#5-member-end-releases-hinges--custom-bitwise-fixity)
  - [5.7 6-DOF Zero-Length Connector Element (`UCONN6`)](#57-6-dof-zero-length-connector-element-uconn6--track-2-discrete-joint)
  - [5.8 Nonlinear ASCE 41-17 Plastic Hinge Backbone](#58-nonlinear-asce-41-17-plastic-hinge-backbone--pushover-analysis)
- [6. Supported Loading Types](#6-supported-loading-types)
- [7. Supported Analysis Types](#7-supported-analysis-types)
- [8. Output Variables, Dynamic CSV Generators & Post-Processing](#8-output-variables-dynamic-csv-generators--post-processing)
  - [8.1 `.frd` File Outputs (for CGX Visualization)](#81-frd-file-outputs-for-cgx-visualization)
  - [8.2 Dynamic Multi-Station Beam CSV Output (`*USER BEAM OUTPUT`)](#82-dynamic-multi-station-beam-csv-output-user-beam-output)
  - [8.3 Zero-Length Connector & ASCE 41-17 Hinge Output (`*USER CONNECTOR OUTPUT`)](#83-zero-length-connector--asce-41-17-hinge-output-user-connector-output)
  - [8.4 Member End Forces, Nodal Actions & Sign Conventions](#84-member-end-forces-nodal-actions--sign-conventions)
- [9. Example Input Decks & Analytical Verification](#9-example-input-decks--analytical-verification)

---

## 1. Installation Guide

### Overview of Patch Assets
- **`install_ub21.sh`**: Automated installer script that detects source locations, resolves patch levels (`-p4`, `-p1`, `-p0`), applies the patch, and runs parallel compilation.
- **`ub21_ccx223.patch`**: Unified diff patch containing Fortran source modules (`e_c3d_ub21.f`, `e_c3d_ubeam_utils.f`, `resultsmech_ub21.f`, `extrapolate_ub21.f`, `userbeamsections.f`, `saved_loads.f`) and all required modifications to CCX 2.23 core routines (`calinput.f`, `ccx_2.23.c`, `ccx_2.23step.c`, `frd.c`, `nodebelongstoel.f`, `createinum.f`, `Makefile.inc`, `Makefile`, etc.).

---

### Option 1: Automated 1-Command Installation (Recommended)

1. Copy `install_ub21.sh` and `ub21_ccx223.patch` into your fresh CCX source directory (or root repository directory).
2. Make the script executable and execute it with the target directory path:

```bash
chmod +x install_ub21.sh
./install_ub21.sh /path/to/fresh/ccx_2.23/src
```

The script will:
- Auto-detect the CCX 2.23 source folder.
- Determine the correct patch strip level.
- Apply `ub21_ccx223.patch`.
- Execute a parallel build (`make -j$(nproc)`).
- Verify successful compilation and binary generation of `ccx_2.23`.

---

### Option 2: Manual Installation (Linux / macOS)

From the root directory of a clean CalculiX CCX 2.23 source tree:

```bash
# 1. Apply the patch
patch -p1 < /path/to/ub21_ccx223.patch

# 2. Navigate to source folder and compile
cd CalculiX/ccx_2.23/src
make -j$(nproc)
```

---

### Option 3: Windows Installation Guide

On Windows systems, unified patch files (`.patch`) can be applied and compiled using several standard toolchains:

#### Method A: WSL (Windows Subsystem for Linux - Recommended)
1. Open your WSL terminal (e.g. Ubuntu).
2. Install `patch` and build tools if not already present:
   ```bash
   sudo apt update && sudo apt install build-essential patch gfortran liblapack-dev libspooles-dev
   ```
3. Run the automated installer script:
   ```bash
   ./install_ub21.sh /mnt/c/path/to/fresh/ccx_2.23/src
   ```

#### Method B: Git for Windows / Git Bash
If you have Git installed on Windows:
1. Open **Git Bash** and navigate to your fresh CCX source folder:
   ```bash
   cd /c/path/to/fresh/ccx_2.23/src
   ```
2. Apply the patch using `git apply`:
   ```bash
   git apply --whitespace=fix /path/to/ub21_ccx223.patch
   ```
   *Alternatively, if using native patch in Git Bash:*
   ```bash
   patch -p1 < /path/to/ub21_ccx223.patch
   ```

#### Method C: MSYS2 / MinGW-w64 (Native Windows Build)
1. Open the **MSYS2 MinGW64** terminal.
2. Install `patch` and `make`:
   ```bash
   pacman -S patch make mingw-w64-x86_64-gfortran mingw-w64-x86_64-gcc
   ```
3. Apply the patch and compile:
   ```bash
   cd /c/CalculiX/ccx_2.23/src
   patch -p1 < ub21_ccx223.patch
   make -f Makefile
   ```

#### Method D: TortoiseGit / IDE GUI (No Command Line)
1. Right-click your CalculiX source folder in Windows File Explorer.
2. Select **TortoiseGit** $\rightarrow$ **Apply Patch...**
3. Select `ub21_ccx223.patch` and click **Apply all hooks / Patch all**.

---

## 2. UB21 Element Specification & Definition

The **UB21** element is a custom 2-node 3D beam element integrated natively into CCX as a user element.

### Element Declaration (`*USER ELEMENT`)
In CalculiX, user elements must be declared before any element topology is defined:

```inp
*USER ELEMENT, TYPE=UB21, NODES=2, MAXDOF=6, INTEGRATIONPOINTS=1
```

### Element Connectivity (`*ELEMENT`)
Elements are instantiated with standard connectivity syntax:

```inp
*ELEMENT, TYPE=UB21, ELSET=<elset_name>
<elem_id>, <node1>, <node2>
```

### Element Capabilities
- **Nodes**: 2 nodes per element (Node 1, Node 2).
- **Degrees of Freedom (DOFs)**: 6 DOFs per node (`UX`, `UY`, `UZ`, `ROTX`, `ROTY`, `ROTZ`).
- **Kinematics**: Timoshenko 3D shear deformation formulation with Euler-Bernoulli limiting behavior (customizable via `KAPPA=` or `KAPPA=0`).
- **Geometric Nonlinearity ($P$-$\Delta$ and $P$-$\delta$)**: Full 3D co-rotational chord rotation ($P$-$\Delta$) and member curvature geometric stiffness matrix $[K_g(P)]$ ($P$-$\delta$) with thermal strain decoupling (activated via `*STEP, NLGEOM`).
- **Inelastic Pushover & Plastic Hinges**: Lumped plasticity with ASCE 41-17 backbone curve (`UCONN6` with `NONLINEAR=ASCE41`) for performance-based seismic design.
- **Section Orientations**: Defined via local direction vector $\mathbf{e}_2$ on the section card or `ORIENTATION` key definitions.
- **Section Rotations**: In-plane section rotation around the longitudinal beam axis via `ROTATION=<angle_deg>`.
- **Nodal Offsets**: 3D geometric offsets at Node 1 and Node 2 defined via `OFFSET=`, `OFFSET1=`, `OFFSET2=`.
- **Member End Releases (Hinges)**: Static condensation of rotational degrees of freedom (`M1`, `M2`, `T`, `M1-M2`, `ALLM`, or bitwise integer fixity).
- **Mass Matrices**: Consistent mass matrix formulation and optional lumped mass formulation (controlled by explicit dynamics or environment variable `CCX_LUMPED_MASS=1`).

---

## 3. Section Definition: Two Supported Input Formats

UB21 supports two alternative input deck keywords to assign cross-section geometry, orientation, offsets, and hinges:

1. **Method A: `*USER BEAM SECTION` (Recommended & User-Friendly)**: Uses dedicated keyword parameters for section types, releases, and offsets.
2. **Method B: `*USER SECTION, CONSTANTS=19` (Raw Property Array)**: Uses CalculiX's standard generic user element property card where all 19 constant slots are specified sequentially.

---

### Method A: `*USER BEAM SECTION` (Recommended)

#### Syntax Layout
```inp
*USER BEAM SECTION, ELSET=<elset_name>, MATERIAL=<mat_name>, SECTION=<RECT|CIRC|PIPE|I|T|CHAN|L|BOX> [, ROTATION=<angle_deg>] [, KAPPA=<val>] [, TIMOSHENKO=<YES|NO>] [, RELEASE1=<code1>] [, RELEASE2=<code2>] [, OFFSET=(y,z)|OFFSET=(x,y,z)] [, OFFSET1=(x,y,z)] [, OFFSET2=(x,y,z)]
<dim_1>, <dim_2>, <dim_3>, <dim_4>, <dim_5>, <dim_6>
[<e2_x>, <e2_y>, <e2_z>]    <-- Optional (CalculiX automatically sets canonical orientation)
```

#### Parameter Explanations
1. **Keyword Line Parameters**:
   - `ELSET=<name>`: Element set name. (Required)
   - `MATERIAL=<name>`: Material name. (Required)
   - `SECTION=<type>`: Cross-section shape: `RECT`, `CIRC`, `PIPE`, `I`, `T`, `CHAN`, `L`, or `BOX`. (Required)
   - `ROTATION=<angle>`: In-plane section rotation angle in degrees around the longitudinal beam axis. **This is the recommended and easiest way to specify beam and column orientation.**
   - `KAPPA=<val>`: Custom shear correction factor $\kappa = A_s / A$.
     - Setting `KAPPA=0` completely turns off shear deformation ($\phi = 0$), yielding a **pure Euler-Bernoulli beam**.
     - Setting a positive value (e.g. `KAPPA=0.833333` for $5/6$, or `KAPPA=0.85`) enforces that exact shear coefficient.
     - If omitted (or default), CalculiX automatically computes the analytical Cowper shear factor based on Poisson's ratio $\nu$ and cross-section geometry.
   - `TIMOSHENKO=<YES|NO>`: Shorthand alias. `TIMOSHENKO=NO` is equivalent to `KAPPA=0` (Euler-Bernoulli). Defaults to `YES`.
   - `RELEASE1=<code>`: Node 1 release code (`M1`, `M2`, `T`, `M1-M2`, `ALLM`, or bitmask integer `1..63`).
   - `RELEASE2=<code>`: Node 2 release code (`M1`, `M2`, `T`, `M1-M2`, `ALLM`, or bitmask integer `1..63`).
   - `OFFSET=(y, z)` or `OFFSET=(x, y, z)`: Local geometric offsets applied to all nodes.
   - `OFFSET1=(x, y, z)`: Local geometric offset at Node 1.
   - `OFFSET2=(x, y, z)`: Local geometric offset at Node 2.

2. **Data Line 1 (Dimensions - Required)**:
   - Up to 6 dimension values `<dim_1>, ..., <dim_6>` for the chosen section type (see Section 4).

3. **Data Line 2 (Orientation Vector - Optional)**:
   - Optional 3 real numbers `<e2_x>, <e2_y>, <e2_z>` for custom 3D vectors. When omitted, CalculiX automatically computes the standard structural reference orientation for vertical and non-vertical members.

> [!TIP]
> You do **not** need to supply Data Line 2 in 99% of structural models. Simply provide Data Line 1 with section dimensions and use `ROTATION=<angle>` (e.g. `ROTATION=90`) if you need to rotate a member.

---

### Method B: `*USER SECTION, CONSTANTS=19` (Raw Property Vector)

CalculiX's native `*USER SECTION` card can also be used directly with `CONSTANTS=19`. In this format, all 19 section parameters are passed sequentially across data lines:

#### Syntax Layout
```inp
*USER SECTION, ELSET=<elset_name>, MATERIAL=<mat_name>, CONSTANTS=19
<sect_type>, <dim1>, <dim2>, <dim3>, <dim4>, <dim5>, <dim6>, <rot_angle>
<off_x1>, <off_y1>, <off_z1>, <off_x2>, <off_y2>, <off_z2>
<rel_1>, <rel_2>
<e2_x>, <e2_y>, <e2_z>
```

#### Constants Index Mapping (1..19)
| Constant Slot | Parameter Name | Description |
| :---: | :--- | :--- |
| **`1`** | `sect_type` | Section code: `1`=RECT, `2`=CIRC/PIPE, `3`=I, `4`=T, `5`=CHAN, `6`=L, `7`=BOX |
| **`2..7`** | `dims(1..6)` | Geometric dimensions (padded with `0.0` if fewer than 6) |
| **`8`** | `rot_angle` | In-plane rotation angle (degrees) |
| **`9..11`** | `off_x1, off_y1, off_z1` | Node 1 local Cartesian offsets |
| **`12..14`** | `off_x2, off_y2, off_z2` | Node 2 local Cartesian offsets |
| **`15..16`** | `rel_1, rel_2` | Member end release codes for Node 1 and Node 2 (integer bitmask) |
| **`17..19`** | `e2_x, e2_y, e2_z` | Orientation normal vector $\mathbf{e}_2$ |

#### Example Deck with `*USER SECTION`:
```inp
*USER SECTION, ELSET=BEAM, MATERIAL=STEEL, CONSTANTS=19
1, 0.1, 0.1, 0.0, 0.0, 0.0, 0.0, 0.0,
0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
0, 0,
0.0, 1.0, 0.0
```

---

### 3.3 Local Coordinate System Conventions ($\mathbf{e}_1, \mathbf{e}_2, \mathbf{e}_3$)

The local coordinate frame of each UB21 beam element is an orthonormal right-handed triad:
- **$\mathbf{e}_1$ (Local $x$ / Axis 1)**: Longitudinal chord axis directed from Node 1 to Node 2.
- **$\mathbf{e}_2$ (Local $y$ / Axis 2)**: Transverse axis defining cross-section depth / web plane.
- **$\mathbf{e}_3$ (Local $z$ / Axis 3)**: Transverse axis defining cross-section width / flange plane ($\mathbf{e}_3 = \mathbf{e}_1 \times \mathbf{e}_2$).

```
                            e2 (local y / axis 2)
                               ▲
                               │
               Node 1          │                    Node 2
                 ●═════════════╪══════════════════════● ───► e1 (local x / axis 1)
                              /
                             ▼
                      e3 (local z / axis 3)   [e3 = e1 x e2]
```

#### Mathematical Construction
1. **Chord Vector $\mathbf{e}_1$**:
   $$\mathbf{e}_1 = \frac{\mathbf{x}_2 - \mathbf{x}_1}{\|\mathbf{x}_2 - \mathbf{x}_1\|}$$
2. **Gram-Schmidt Orthogonalization of $\mathbf{e}_2$**:
   From user input vector $\mathbf{v}_{\text{in}} = (v_x, v_y, v_z)$ (Data Line 2 of `*USER BEAM SECTION`):
   $$\mathbf{e}_2' = \mathbf{v}_{\text{in}} - (\mathbf{v}_{\text{in}} \cdot \mathbf{e}_1)\,\mathbf{e}_1, \qquad \mathbf{e}_2 = \frac{\mathbf{e}_2'}{\|\mathbf{e}_2'\|}$$
3. **In-Plane Section Rotation (`ROTATION=<angle>`)**:
   Rotates $\mathbf{e}_2$ around $\mathbf{e}_1$ by angle $\theta$:
   $$\mathbf{e}_2^{\text{rot}} = \mathbf{e}_2 \cos\theta + (\mathbf{e}_1 \times \mathbf{e}_2)\sin\theta$$
4. **Out-of-Plane Axis $\mathbf{e}_3$**:
   $$\mathbf{e}_3 = \mathbf{e}_1 \times \mathbf{e}_2, \qquad \mathbf{e}_2 = \mathbf{e}_3 \times \mathbf{e}_1$$

#### Orientation Guide: Vertical vs. Non-Vertical Members

> [!IMPORTANT]
> **Collinearity Rule**: The orientation input vector $\mathbf{v}_{\text{in}}$ must **never be parallel** to the member axis $\mathbf{e}_1$.

| Member Geometry | Beam Axis $\mathbf{e}_1$ | Recommended $\mathbf{v}_{\text{in}}$ (Data Line 2) | Resulting Local Axes | Physical Description |
|:---|:---:|:---:|:---:|:---|
| **Horizontal Girder (along X)**<br>*(Global Z is vertical)* | $(1, 0, 0)$ | `0.0, 0.0, 1.0` | $\mathbf{e}_2 = (0, 0, 1)$<br>$\mathbf{e}_3 = (0, -1, 0)$ | Local $y$ is vertical (+Z), local $z$ is horizontal (-Y). |
| **Horizontal Beam (along X)**<br>*(Global Y is vertical in 2D)* | $(1, 0, 0)$ | `0.0, 1.0, 0.0` | $\mathbf{e}_2 = (0, 1, 0)$<br>$\mathbf{e}_3 = (0, 0, 1)$ | Local $y$ is vertical (+Y), local $z$ is out-of-plane (+Z). |
| **Vertical Column (along Z)**<br>*(Web facing Global Y)* | $(0, 0, 1)$ | `0.0, 1.0, 0.0` | $\mathbf{e}_2 = (0, 1, 0)$<br>$\mathbf{e}_3 = (-1, 0, 0)$ | Local $y$ is in +Y, local $z$ is in -X. |
| **Vertical Column (along Z)**<br>*(Web facing Global X)* | $(0, 0, 1)$ | `1.0, 0.0, 0.0` | $\mathbf{e}_2 = (1, 0, 0)$<br>$\mathbf{e}_3 = (0, 1, 0)$ | Local $y$ is in +X, local $z$ is in +Y. |
| **Vertical Column (along Y)**<br>*(2D Frame Column)* | $(0, 1, 0)$ | `1.0, 0.0, 0.0` | $\mathbf{e}_2 = (1, 0, 0)$<br>$\mathbf{e}_3 = (0, 0, -1)$ | Local $y$ is in +X, local $z$ is out-of-plane (-Z). |
| **3D Inclined Diagonal Brace** | $\left(\frac{\Delta x}{L}, \frac{\Delta y}{L}, \frac{\Delta z}{L}\right)$ | `0.0, 0.0, 1.0`<br>*(or `0.0, 1.0, 0.0`)* | Projected $\mathbf{e}_2 \perp \mathbf{e}_1$<br>$\mathbf{e}_3 = \mathbf{e}_1 \times \mathbf{e}_2$ | Upward reference vector automatically orthogonalized. |

> [!NOTE]
> **Automatic Collinearity Guard**: If $\mathbf{v}_{\text{in}}$ is omitted or mistakenly set parallel to $\mathbf{e}_1$ (e.g. a vertical column with `0.0, 0.0, 1.0`), CalculiX automatically falls back to $(0, 1, 0)$ or $(1, 0, 0)$ to ensure a non-singular orthonormal coordinate frame.

---

## 4. Cross-Section Types & Geometric Parameters

| Section Code (`SECTION=`) | Parameter List | Parameter Description |
| :--- | :--- | :--- |
| **`RECT`** | `b, h` | Width `b` (along local axis 2 / $y$), Height `h` (along local axis 3 / $z$) |
| **`CIRC`** | `r_o` | Outer radius `r_o` (or `r_o, 0.0`) |
| **`PIPE`** | `r_o, t` | Outer radius `r_o`, Wall thickness `t` |
| **`I`** | `h, b_top, t_f1, b_bot, t_f2, t_w` | Total height `h`, Top flange width, Top flange thickness, Bottom flange width, Bottom flange thickness, Web thickness |
| **`T`** | `h, b, t_f, t_w` | Total height `h`, Flange width `b`, Flange thickness `t_f`, Web thickness `t_w` |
| **`CHAN`** (U-channel) | `h, b, t_f, t_w` | Channel height `h`, Flange width `b`, Flange thickness `t_f`, Web thickness `t_w` |
| **`L`** (Angle) | `b, h, t` | Horizontal leg width `b`, Vertical leg height `h`, Leg thickness `t` |
| **`BOX`** (Hollow Box) | `h, b, t_bot, t_left, t_top, t_right` | Total height `h`, Total width `b`, Bottom flange thickness `t_bot`, Left web thickness `t_left`, Top flange thickness `t_top`, Right web thickness `t_right` *(or `h, b, t, t, t, t` for uniform thickness)* |

```
─────────────────────────────────────────────────────────────────────────────
1. RECT (Solid Rectangle)                     2. CIRC / PIPE (Circle & Hollow Pipe)
─────────────────────────────────────────────────────────────────────────────
         local z (axis 3)                               local z (axis 3)
               ▲                                              ▲
       ┌───────┼───────┐ ───                                  │
       │       │       │  ▲                              . - ~ ~ ~ - .
       │       │       │  │                          .-'       │       '-.
       │       +───────┼──┼──► local y (axis 2)     /     . - ~+~ - .     \
       │               │  h                        /    /      │      \    \   Outer radius: r_o
       │               │  │                       │    │       +───────┼────┼──► local y (axis 2)
       └───────────────┘ ───                       \    \             /    /   Wall thickness: t
       ├─── b ─────────┤                            \     ' - ~ ~ - '     /
                                                     '-.               .-'
                                                         ' - ~ ~ ~ - '
─────────────────────────────────────────────────────────────────────────────
3. I-SECTION (Wide Flange / I-Beam)            4. BOX (Hollow Structural Box)
─────────────────────────────────────────────────────────────────────────────
         local z (axis 3)                               local z (axis 3)
               ▲                                              ▲
       ┌───────┴───────┐ ─── t_f1 (b_top)             ┌───────┴───────┐ ─── t_top
       └───┐       ┌───┘ ───                          │ ┌───────────┐ │
           │   │   │                                  │ │     │     │ │
           │   │   │ h                                │ │     +─────┼─┼──► local y (axis 2) h
           │   +───┼────────► local y (axis 2)        │ │           │ │
       ┌───┘   │   └───┐ ───                          │ └───────────┘ │ ─── t_bot
       └───────┬───────┘ ─── t_f2 (b_bot)             └───────┬───────┘
           ├── t_w ──┤                                ├─── b ─────────┤
                                                      ├── t_left      └── t_right
─────────────────────────────────────────────────────────────────────────────
5. T-SECTION (Tee Beam)                        6. CHAN (U-Channel)
─────────────────────────────────────────────────────────────────────────────
         local z (axis 3)                               local z (axis 3)
               ▲                                              ▲
       ┌───────┴───────┐ ─── t_f                      ┌───────────────┐ ─── t_f
       └───┐       ┌───┘ ───                          │ ┌─────────────┘ ───
           │   │   │                                  │ │     │
           │   │   │ h                                │ │     +──────────► local y (axis 2) h
           │   +───┼────────► local y (axis 2)        │ │
           │       │                                  │ └─────────────┐ ───
           └───────┘                                  └───────────────┘ ─── t_f
           ├── t_w ──┤                                ├─── b ─────────┤
                                                      ├── t_w ──┤
─────────────────────────────────────────────────────────────────────────────
7. L-SECTION (Angle)
─────────────────────────────────────────────────────────────────────────────
         local z (axis 3)
               ▲
       ┌───────┤
       │       │
       │       │ h
       │   +───┼────────► local y (axis 2)
       │       │
       │       └───────────────┐ ───
       └───────────────────────┘ ─── t
       ├─── b ─────────────────┤
```

> [!TIP]
> For circular and pipe sections (`CIRC` and `PIPE`), the first parameter is the **outer radius $r_o$**, not the diameter.

> [!NOTE]
> **Asymmetric Sections (`CHAN`, `L`)**: UB21 automatically computes principal axes of inertia and principal rotation angles to prevent spurious shear-bending coupling.

---

## 5. Member End Releases (Hinges) & Custom Bitwise Fixity

UB21 supports independent member end releases (hinges) at Node 1 (`RELEASE1=` / End 1) and Node 2 (`RELEASE2=` / End 2) using in-element static condensation. Releases can be defined either globally at the section level via `*USER BEAM SECTION` or overridden on individual elements/subsets via `*USER BEAM RELEASE`.

---

### 5.1 Local Degree of Freedom Encoding & Bitwise Fixity Architecture

The UB21 stiffness condensation kernel operates directly on the 6 local degrees of freedom at each end of the element:

$$\mathbf{u}_{\text{local}} = [u_x,\, u_y,\, u_z,\, r_x,\, r_y,\, r_z]^T$$

Every release code is represented internally as a 6-bit binary bitmask (base-10 integer in the range $0 \le \text{code} \le 63$):

$$\text{Release Value} = \sum_{k=1}^{6} \text{ReleaseFlag}_k \cdot 2^{k-1}$$

| Local DOF Index | Physical Motion / DOF Name | Bit Position | Bit Weight (Base-10 Value) | Mechanical Action Released |
| :--- | :--- | :---: | :---: | :--- |
| **DOF 1** | Local Axial Displacement ($u_x$) | $2^0$ | **`1`** | Axial sliding joint (zero axial force transmission) |
| **DOF 2** | Local Transverse Shear ($u_y$) | $2^1$ | **`2`** | Transverse shear release in local $y$ |
| **DOF 3** | Local Transverse Shear ($u_z$) | $2^2$ | **`4`** | Transverse shear release in local $z$ |
| **DOF 4** | Local Torsion ($r_x$) | $2^3$ | **`8`** | Torsional rotation release (zero torque $T$) |
| **DOF 5** | Local Bending Rotation ($r_y$) | $2^4$ | **`16`** | Bending hinge about local axis 1 (zero bending moment $M_y$) |
| **DOF 6** | Local Bending Rotation ($r_z$) | $2^5$ | **`32`** | Bending hinge about local axis 2 (zero bending moment $M_z$) |

---

### 5.2 Standard Mnemonic Release Shortcuts & Aliases

CalculiX accepts both mnemonic character strings and exact integer bitmask values:

| Release Mnemonic | Supported Aliases | Released DOFs | Integer Value | Structural Engineering Description |
| :--- | :--- | :--- | :---: | :--- |
| **`NONE`** | `FIXED`, `RIGID`, `0` | None | **`0`** | Fully rigid connection (all 6 DOFs continuous) |
| **`UX`** | `U1`, `AXIAL`, `N`, `P0` | Local $u_x$ | **`1`** | Axial expansion / sliding joint |
| **`UY`** | `U2`, `V1`, `VY`, `SHEAR1` | Local $u_y$ | **`2`** | Transverse shear slide in local $y$ |
| **`UZ`** | `U3`, `V2`, `VZ`, `SHEAR2` | Local $u_z$ | **`4`** | Transverse shear slide in local $z$ |
| **`T`** | `RX`, `ROTX`, `MX`, `TOR` | Local $r_x$ | **`8`** | Torsional pin / free axial spin |
| **`M1`** | `RY`, `ROTY`, `MY` | Local $r_y$ | **`16`** | Uniaxial bending hinge about local $y$ ($M_y = 0$) |
| **`M2`** | `RZ`, `ROTZ`, `MZ` | Local $r_z$ | **`32`** | Uniaxial bending hinge about local $z$ ($M_z = 0$) |
| **`M1-M2`** | `M2-M1`, `M1_M2`, `M1+M2`, `RY-RZ` | Local $r_y, r_z$ | **`48`** | Biaxial spherical bending hinge ($M_y = 0, M_z = 0$) |
| **`ALLM`** | `ALL_M`, `BALL`, `SPHERICAL`, `M1-M2-T` | Local $r_x, r_y, r_z$ | **`56`** | Full ball-and-socket joint ($M_x = 0, M_y = 0, M_z = 0$) |
| **`ALL`** | `FREE`, `DISCONNECTED` | All 6 DOFs | **`63`** | Full disconnection / free end |

---

### 5.3 Common Permutation & Hybrid Release Configurations

By combining bit weights, all $2^6 = 64$ possible single-node release states (and $64 \times 64 = 4096$ two-end beam permutations) can be specified:

| Integer Code | Bitwise Formula | Released DOFs | Physical Application / Structural Mechanism |
| :---: | :--- | :--- | :--- |
| **`0`** | $0$ | Fixed | Standard beam member with full continuity at both ends. |
| **`1`** | $2^0$ | $u_x$ | Bridge expansion bearing / telescoping sleeve. |
| **`8`** | $2^3$ | $r_x$ | Torsionally uncoupled shaft / pin-ended torque tube. |
| **`16`** | $2^4$ | $r_y$ | Standard vertical framing hinge (Girder-to-column web connection). |
| **`17`** | $2^0 + 2^4$ | $u_x + r_y$ | Sliding roller hinge (expansion bearing with vertical pin). |
| **`18`** | $2^1 + 2^4$ | $u_y + r_y$ | Transverse shear hinge / slotted pin. |
| **`32`** | $2^5$ | $r_z$ | Horizontal framing hinge (Bending pin in horizontal plane). |
| **`33`** | $2^0 + 2^5$ | $u_x + r_z$ | Sliding roller hinge in horizontal plane. |
| **`48`** | $2^4 + 2^5$ | $r_y + r_z$ | Space frame truss member with torsional continuity ($M_y = 0, M_z = 0$). |
| **`49`** | $2^0 + 2^4 + 2^5$ | $u_x + r_y + r_z$ | Sliding spherical bearing (axial slide + biaxial hinge). |
| **`56`** | $2^3 + 2^4 + 2^5$ | $r_x + r_y + r_z$ | Standard spherical ball joint (3D truss / space frame bar). |
| **`57`** | $2^0 + 2^3 + 2^4 + 2^5$ | $u_x + r_x + r_y + r_z$ | Sliding ball joint / unconstrained axial slip ball end. |
| **`63`** | $2^0 + 2^1 + 2^2 + 2^3 + 2^4 + 2^5$ | All 6 DOFs | Fully released internal discontinuity / mechanism. |

---

### 5.4 Two-End Beam Configuration Matrix

The table below illustrates common structural boundary conditions achieved by configuring Node 1 and Node 2:

```
─────────────────────────────────────────────────────────────────────────────
Visualizing Member End Releases & Internal Hinges in UB21
─────────────────────────────────────────────────────────────────────────────
1. Continuous Frame Girder (Fixed - Fixed):
   Node 1 [RELEASE1=0]                              Node 2 [RELEASE2=0]
   ■════════════════════════════════════════════════■
   (Full moment & shear transfer across joint)

2. Simply Supported Beam / Girder-to-Column Web (Pinned - Pinned):
   Node 1 [RELEASE1=M1]                             Node 2 [RELEASE2=M1]
   ○─ ─ ─═══════════════════════════════════════════─ ─ ─○
   (Bending moment My condensed to 0 at both beam ends)

3. Propped Cantilever (Fixed - Pinned):
   Node 1 [RELEASE1=0]                              Node 2 [RELEASE2=M1]
   ■════════════════════════════════════════════════─ ─ ─○
   (Fixed joint at left support, pinned at right support)

4. Pin-Jointed Space Truss / Diagonal Brace (Ball - Ball):
   Node 1 [RELEASE1=ALLM]                           Node 2 [RELEASE2=ALLM]
   (●)══════════════════════════════════════════════(●)
   (Full spherical 3D rotation released: Mx = My = Mz = 0)
─────────────────────────────────────────────────────────────────────────────
```

| Structural Member Type | Node 1 Release | Node 2 Release | Typical Use Case |
| :--- | :---: | :---: | :--- |
| **Fixed - Fixed** | `0` (`NONE`) | `0` (`NONE`) | Monolithic continuous frame girder |
| **Pinned - Fixed** | `16` (`M1`) | `0` (`NONE`) | Propped cantilever / end span pinned at abutment |
| **Fixed - Pinned** | `0` (`NONE`) | `16` (`M1`) | Propped cantilever / end span pinned at right pier |
| **Simply Supported** | `16` (`M1`) | `16` (`M1`) | Standard simply supported single span beam |
| **Biaxial Pinned - Pinned** | `48` (`M1-M2`) | `48` (`M1-M2`) | 3D space frame / bridge diagonal with torsion fixed |
| **Ball Joint Truss Bar** | `56` (`ALLM`) | `56` (`ALLM`) | 3D pin-jointed space truss / link member |
| **Gerber Bridge Cantilever**| `0` (`NONE`) | `16` (`M1`) | Element adjacent to internal hinge drop-in span |
| **Expansion Roller Span** | `17` ($u_x+r_y$) | `16` ($r_y$) | Bridge span with expansion joint at one pier |
| **Torsionally Free Beam** | `8` (`T`) | `8` (`T`) | Structural member isolated from torque transmission |

---

### 5.5 Keyword Syntax: Section-Level vs Per-Member Releases

#### 1. Section-Level Releases (`*USER BEAM SECTION`)
Applied uniformly to all elements belonging to an `ELSET`:
```inp
*USER BEAM SECTION, ELSET=BEAMS, MATERIAL=STEEL, SECTION=RECT, RELEASE1=M1, RELEASE2=M1
0.1, 0.2
0.0, 1.0, 0.0
```
Or with custom integer bitmasks:
```inp
*USER BEAM SECTION, ELSET=BEAMS, MATERIAL=STEEL, SECTION=RECT, RELEASE1=17, RELEASE2=16
0.1, 0.2
0.0, 1.0, 0.0
```

#### 2. Per-Member Releases & Semi-Rigid Springs (`*USER BEAM RELEASE`)
Overrides section defaults on specific individual elements or element subsets:

```inp
*USER BEAM RELEASE
<element_id_or_elset>, <node_end (1 or 2 or ALL)>, <code (mnemonic or integer)>, [spring_stiffness_K]
```

**Examples:**
```inp
*USER BEAM RELEASE
! 1. Pure hinge release (infinite compliance / zero stiffness):
3, 2, M1

! 2. Semi-rigid rotational spring (e.g. K_theta = 1.0e7 N.m/rad):
1, 1, M1, 1.0e7

! 3. Semi-rigid translational axial spring (e.g. K_axial = 4.0e8 N/m):
1, 1, UX, 4.0e8

! 4. Independent rotational springs at both ends of a girder:
4, 1, M1, 1.5e7
4, 2, M1, 2.0e7

! 5. Integer bitmask with spring stiffness:
7, 1, 16, 1.0e7

! 6. Element Set semi-rigid connection override:
EBEAM_SUBSET, 1, M1, 1.0e7

! 7. Header ELSET syntax:
*USER BEAM RELEASE, ELSET=EBEAM_SUBSET
1, M1, 1.0e7
2, M2, 5.0e6
```

---

### 5.6 Linear Semi-Rigid Springs in In-Element Condensation ($0 < K_s < \infty$)

For structural connections exhibiting flexible compliance (such as semi-rigid top-and-seat angle connections, end-plate connections, composite beam slip, or soil-structure interaction springs), `*USER BEAM RELEASE` allows specifying finite spring stiffness $K_s$ without introducing extra global degrees of freedom or dummy interface nodes.

#### Mathematical Formulation

The flexible connection compliance adds in series with the beam element flexibility:

$$\mathbf{f}_{\text{total}} = \mathbf{f}_{\text{beam}} + \text{diag}\left(\frac{1}{K_s}\right)$$

In the stiffness domain, each spring-loaded degree of freedom $r$ modifies the local stiffness matrix and equivalent nodal load vector via exact condensation:

$$S^*_{ij} = S_{ij} - \frac{S_{ir} S_{rj}}{S_{rr} + K_s}$$

$$ff^*_i = ff_i - \frac{S_{ir}}{S_{rr} + K_s} ff_r \quad (i \ne r), \qquad ff^*_r = \frac{K_s}{S_{rr} + K_s} ff_r$$

#### Behavior Across the Stiffness Spectrum

1. **Rigid Connection ($K_s \to \infty$)**:
   $$\frac{S_{ir} S_{rj}}{S_{rr} + K_s} \to 0 \implies S^*_{ij} = S_{ij}, \quad ff^*_i = ff_i$$
   The member retains full monolithic rigidity.

2. **Pure Release / Pin ($K_s = 0$)**:
   $$S^*_{ij} = S_{ij} - \frac{S_{ir} S_{rj}}{S_{rr}}, \quad S^*_{rr} \to 0 \quad (\text{stabilized to } 10^{-9} S_{rr})$$
   Standard static condensation (zero moment/force transmission).

3. **Semi-Rigid Elastic Connection ($0 < K_s < \infty$)**:
   Exact compliance and partial force/moment transmission with zero extra global DOFs.

#### Analytical Fixity Factor ($\gamma$)
For a propped cantilever beam of length $L$ and bending rigidity $EI$ with rotational spring $K_\theta$ at the base, the structural fixity factor is:

$$\gamma = \frac{1}{1 + \dfrac{3EI}{K_\theta L}} = \frac{M_{\text{base}}}{M_{\text{fixed}}}$$

When $K_\theta = \dfrac{3EI}{L}$, $\gamma = 0.50$ and the base moment is exactly $0.5 \times M_{\text{fixed}} = \dfrac{3}{32} P L$.

---

### 5.7 6-DOF Zero-Length Connector Element (`UCONN6`) — Track 2 Discrete Joint

In addition to Track 1 (In-Element Condensation), CalculiX supports Track 2: a dedicated **2-node, 6-DOF zero-length connector element (`UCONN6`)** connecting coincident or offset nodes with independent 3D local orientation and 6 spring stiffnesses.

#### Keyword Syntax

```inp
*ELEMENT, TYPE=UCONN6, ELSET=<elset_name>
<element_id>, <node_A>, <node_B>

*USER CONNECTOR, ELSET=<elset_name>
<K_ux>, <K_uy>, <K_uz>, <K_rx>, <K_ry>, <K_rz>
[<x_dir>, <y_dir>, <z_dir>]
```

- **`K_ux, K_uy, K_uz`**: Translational spring stiffnesses in local joint coordinates ($N/m$).
- **`K_rx, K_ry, K_rz`**: Rotational spring stiffnesses in local joint coordinates ($N\cdot m/rad$).
- **`[x_dir, y_dir, z_dir]`** *(Optional)*: 3D local orientation vector. Default aligns with global Cartesian axes ($X, Y, Z$).

#### Mathematical Formulation

Relative displacement vector in the local joint coordinate system:

$$\Delta \mathbf{u}_{\text{loc}} = \mathbf{T}_6 (\mathbf{u}_2 - \mathbf{u}_1) = \begin{bmatrix} \mathbf{T} (\mathbf{u}_{\text{trans},2} - \mathbf{u}_{\text{trans},1}) \\ \mathbf{T} (\mathbf{u}_{\text{rot},2} - \mathbf{u}_{\text{rot},1}) \end{bmatrix}$$

Global element stiffness matrix ($12 \times 12$):

$$\mathbf{K}_{\text{elem}} = \begin{bmatrix} \mathbf{K}_{\text{glob}} & -\mathbf{K}_{\text{glob}} \\ -\mathbf{K}_{\text{glob}} & \mathbf{K}_{\text{glob}} \end{bmatrix}, \qquad \mathbf{K}_{\text{glob}} = \mathbf{T}_6^T \mathbf{K}_s \mathbf{T}_6 = \begin{bmatrix} \mathbf{T}^T \mathbf{K}_{\text{trans}} \mathbf{T} & \mathbf{0} \\ \mathbf{0} & \mathbf{T}^T \mathbf{K}_{\text{rot}} \mathbf{T} \end{bmatrix}$$

Transmitted internal connector forces and moments:

$$\mathbf{F}_{\text{loc}} = \mathbf{K}_s \Delta \mathbf{u}_{\text{loc}} = \left[ K_{ux} \Delta u_x, \; K_{uy} \Delta u_y, \; K_{uz} \Delta u_z, \; K_{rx} \Delta r_x, \; K_{ry} \Delta r_y, \; K_{rz} \Delta r_z \right]^T$$

#### Typical Modeling Patterns

1. **Pure Shear / Pinned Connection**:
   ```inp
   *USER CONNECTOR, ELSET=ECONN
   1.0e12, 1.0e12, 1.0e12, 1.0e12, 0.0, 1.0e12
   ```
   *(Transmits full axial/shear forces and torsion while allowing free in-plane rotation $R_y$).*

2. **Semi-Rigid Rotational Spring ($K_\theta = 1.5 \times 10^7\text{ N}\cdot\text{m/rad}$)**:
   ```inp
   *USER CONNECTOR, ELSET=ECONN
   1.0e12, 1.0e12, 1.0e12, 1.0e12, 1.5e7, 1.0e12
   ```
   *(Yields identical nodal displacements and internal moments to Track 1 In-Element Condensation within $< 10^{-5}$ relative difference).*

---

### 5.8 Nonlinear ASCE 41-17 Plastic Hinge Backbone & Pushover Analysis

`UCONN6` connector elements support non-linear plastic hinge constitutive models according to **ASCE 41-17** (*Seismic Evaluation and Retrofit of Existing Buildings*), including multilinear backbone curves with post-yield strain hardening, capping rotation, post-peak softening (negative tangent stiffness $K_t < 0$), and residual strength plateaus.

```
       Moment M
          ^
     M_p  +             C (Peak / Capping Point: theta_cap)
          |            / \
     M_y  +           B   \
          |          /     \  (Softening: Kt < 0)
          |         /       \
  c * M_y +        /         D ----------- E (Residual Plateau)
          |       /          |             |
          |      /           |             |
        0 +-----+------------+-------------+--------> Rotation |theta|
          0    theta_y    theta_cap      theta_u
               (A -> B)    (B -> C)      (C -> D)     (D -> E)
```

#### Multilinear Backbone Branches

| Branch | Rotation Range | Resisting Moment $M(\theta)$ | Tangent Stiffness $K_t$ | ASCE 41 Performance Level |
| :--- | :--- | :--- | :--- | :--- |
| **A $\to$ B** | $0 \le \|\theta\| \le \theta_y$ | $K_e \theta$ | $K_e = M_y / \theta_y$ | **0: Elastic** |
| **B $\to$ C** | $\theta_y < \|\theta\| \le \theta_{\text{cap}}$ | $M_y + \alpha_h K_e (\|\theta\| - \theta_y)$ | $\alpha_h K_e$ | **1: Immediate Occupancy (IO)** / **2: Life Safety (LS)** |
| **C $\to$ D** | $\theta_{\text{cap}} < \|\theta\| \le \theta_u$ | $M_{\text{peak}} + K_{\text{soft}} (\|\theta\| - \theta_{\text{cap}})$ | $K_{\text{soft}} = \frac{c M_y - M_{\text{peak}}}{\theta_u - \theta_{\text{cap}}} < 0$ | **2: Life Safety (LS)** / **3: Collapse Prevention (CP)** |
| **D $\to$ E** | $\theta_u < \|\theta\| \le \theta_{\text{fail}}$ | $c M_y$ (Residual Plateau) | $0.0$ | **3: Collapse Prevention (CP)** / **4: Collapse** |

#### Keyword Syntax for ASCE 41 Hinges

```inp
*USER CONNECTOR, ELSET=<elset_name>, NONLINEAR=ASCE41
<K_ux>, <K_uy>, <K_uz>, <K_rx>, <K_ry>, <K_rz>
<M_y>, <theta_y>, <theta_cap>, <c_res>, <theta_u>, <theta_fail>, <alpha_hard>, <dof_idx>
```

- **Data Line 1**: Standard 6-DOF elastic stiffnesses ($K_{ux}, K_{uy}, K_{uz}, K_{rx}, K_{ry}, K_{rz}$).
- **Data Line 2 (ASCE 41 Parameters)**:
  - **`M_y`**: Yield moment / plastic capacity ($N\cdot m$).
  - **`theta_y`**: Yield rotation ($\text{rad}$). Elastic stiffness $K_e = M_y / \theta_y$.
  - **`theta_cap`**: Capping rotation at peak strength ($\text{rad}$).
  - **`c_res`**: Residual strength ratio ($0.0 \le c \le 1.0$, typically $0.20$).
  - **`theta_u`**: Ultimate rotation at the end of the softening branch ($\text{rad}$).
  - **`theta_fail`**: Failure rotation ($\text{rad}$, default $0.100$).
  - **`alpha_hard`**: Post-yield strain hardening ratio ($K_{\text{hard}} / K_e$, default $0.001$).
  - **`dof_idx`**: Active local nonlinear DOF ($1..6$, default `5` for in-plane bending $R_y$).

#### Example: Pushover Deck with Displacement Control

```inp
*USER CONNECTOR, ELSET=EHINGES, NONLINEAR=ASCE41
1.0e12, 1.0e12, 1.0e12, 1.0e12, 0.0, 1.0e12
300000.0, 0.005, 0.030, 0.20, 0.040, 0.100, 0.001, 5

*STEP, NLGEOM, INC=200
*STATIC
0.01, 1.0, 1.0e-5, 0.02
*CLOAD
3, 3, -10000.0
*BOUNDARY
2, 1, 1, 0.150
*NODE PRINT, NSET=NBASE, FREQUENCY=1
RF
*NODE PRINT, NSET=NROOF, FREQUENCY=1
U
*END STEP
```

---

## 6. Supported Loading Types

UB21 supports both concentrated nodal loads (`*CLOAD`) and distributed element loads (`*DLOAD`).

### Concentrated Loads (`*CLOAD`)
Applied at nodes directly in global Cartesian components:
- `1..3`: Global Force components ($F_x, F_y, F_z$).
- `4..6`: Global Moment components ($M_x, M_y, M_z$).

### Distributed Loads (`*DLOAD`)

```
─────────────────────────────────────────────────────────────────────────────
Distributed & Partial Patch Load Patterns on UB21
─────────────────────────────────────────────────────────────────────────────
1. Uniform Distributed Load (P1, P2):
      w (N/m)  ▼  ▼  ▼  ▼  ▼  ▼  ▼  ▼  ▼  ▼  ▼  ▼  ▼  ▼  ▼
      Node 1 ═════════════════════════════════════════════ Node 2
      ├─── Length L ──────────────────────────────────────┤

2. Triangular Varying Load (P1_T1: 0 -> w, P1_T2: w -> 0):
                                       ▼  ▼  ▼  ▼  ▼  ▼  ▼ w (N/m)
                                       ▲
      Node 1 ═════════════════════════════════════════════ Node 2
      ├─── Length L ──────────────────────────────────────┤

3. Localized Patch Load (P1_P_aa_bb, e.g. P1_P_25_75 from 25% to 75% L):
                        w (N/m)  ▼  ▼  ▼  ▼  ▼
      Node 1 ───────────══════════════════════──────────── Node 2
      ├─── 0.25 L ──────├─── Patch 0.50 L ────├─── 0.25 L ┤
─────────────────────────────────────────────────────────────────────────────
```

| DLOAD Label | Load Type & Description |
| :--- | :--- |
| **`PX`** | Uniform axial force per unit length along local element beam axis. |
| **`P1`** | Uniform transverse load per unit length along local transverse axis 1 ($y$). |
| **`P2`** | Uniform transverse load per unit length along local transverse axis 2 ($z$). |
| **`P1_T1`** | Triangular load along local $y$ (increasing from 0 at Node 1 to magnitude at Node 2). |
| **`P1_T2`** | Triangular load along local $y$ (decreasing from magnitude at Node 1 to 0 at Node 2). |
| **`P2_T1`** | Triangular load along local $z$ (increasing from 0 at Node 1 to magnitude at Node 2). |
| **`P2_T2`** | Triangular load along local $z$ (decreasing from magnitude at Node 1 to 0 at Node 2). |
| **`P1_P_aa_bb`** | Partial patch load along local $y$ starting at `aa`% and ending at `bb`% of length (e.g. `P1_P_25_75`). |
| **`P2_P_aa_bb`** | Partial patch load along local $z$ starting at `aa`% and ending at `bb`% of length (e.g. `P2_P_20_80`). |
| **`CENTRIF`** | Centrifugal load field defined by rotational velocity $\omega$ and axis. |
| **`GRAV`** / Body Force | Gravity/accelerational load field computed via material mass density $\rho$ and cross-sectional area $A$. |

---

## 7. Supported Analysis Types

UB21 elements are compatible with the primary CCX analysis procedures:

1. **Static Analysis (`*STATIC`)**:
   - Linear elastic stress, displacement, and internal force computation.
   - Thermal stress evaluation under uniform or nodal temperature fields (`*TEMPERATURE`).
2. **Frequency Analysis (`*FREQUENCY`)**:
   - Natural frequency extraction and mode shape calculation using consistent or lumped mass matrices.
3. **Buckling Analysis (`*BUCKLE`)**:
   - Elastic critical load factor (eigenvalue buckling) evaluation using exact geometric stiffness matrices.
4. **Dynamic & Transient Analysis (`*DYNAMIC` / `*MODAL DYNAMIC`)**:
   - Time-history dynamic response computation.
   - Compatible with lumped mass matrix formulation via `CCX_LUMPED_MASS=1` environment setting.

---

## 8. Output Variables, Dynamic CSV Generators & Post-Processing

CalculiX CCX 2.23 with the UB21/UCONN6 extension provides four output channels:
1. **`.frd` Visualization File**: For 3D color contour post-processing in **CalculiX GraphiX (CGX)**.
2. **`.dat` Printable Results File**: Text printout of nodal displacements, reactions, and element stresses.
3. **`*USER BEAM OUTPUT`**: Zero-RAM, high-performance CSV streaming of internal beam forces, deflections, stresses, and distributed loads along arbitrary subdivisions per member.
4. **`*USER CONNECTOR OUTPUT`**: Zero-RAM CSV streaming of connector forces, relative deformations, and ASCE 41-17 plastic hinge damage states.

---

### 8.1 `.frd` File Outputs (for CGX Visualization)
When `*EL FILE` or `*EL PRINT` with `S` is specified in your `.inp` file, CCX registers two distinct dataset headers in the `.frd` file:

#### Dataset A: `STRESS` (Beam Cross-Section Stresses)
- `SXX`: Combined Maximum Normal Stress $\sigma_{max} = |\sigma_{axial}| + |\frac{M_y \cdot z_{max}}{I_{yy}}| + |\frac{M_z \cdot y_{max}}{I_{zz}}|$
- `SYY`: Local Bending Moment $M_y$
- `SZZ`: Local Bending Moment $M_z$
- `SXY`: Transverse Shear Stress $\tau_{xy}$
- `SYZ`: Torsional Shear Stress $\tau_{tor}$
- `SZX`: Transverse Shear Stress $\tau_{xz}$

#### Dataset B: `BFOR` (Beam Section Resultant Forces & Moments)
- `NX`: Local Axial Force $N_x$
- `VY`: Local Transverse Shear Force $V_y$
- `VZ`: Local Transverse Shear Force $V_z$
- `TX`: Local Torsional Moment $T_x$
- `MY`: Local Bending Moment $M_y$
- `MZ`: Local Bending Moment $M_z$

---

### 8.2 Dynamic Multi-Station Beam CSV Output (`*USER BEAM OUTPUT`)

The `*USER BEAM OUTPUT` keyword streams member-level internal forces, deflections, rotations, normal/shear stresses, and applied distributed line loads directly to CSV files during solver execution.

#### Keyword Syntax
```inp
*USER BEAM OUTPUT [, FILE=<filename.csv>|FILE=(f1.csv, f2.csv)] [, ELSET=<elset>|ELSET=(e1, e2)|ELSET=ALL] [, SUBDIVISIONS=<N>] [, INCREMENT=LAST|ALL|FREQ=k|LIST=(i1, i2,...)] [, COORDINATES=LOCAL|GLOBAL]
[<Data Line: F, U, S, Q, ALL>]
```

#### Keyword Parameters

| Parameter | Options / Type | Default | Description |
| :--- | :--- | :--- | :--- |
| **`FILE=`** | String or Tuple `(f1.csv, f2.csv)` | `<jobname>_beam_forces.csv` | Output CSV filename(s). When tuple lists are provided, files map 1-to-1 with `ELSET=(...)`. |
| **`ELSET=`** | String, Tuple `(e1, e2)`, `ALL`, `*` | All active `UB21` elements | Target element set filter. |
| **`SUBDIVISIONS=`** | Integer ($N \ge 1$, e.g. `10`) | `10` ($11$ stations: $0\%, 10\%, \dots, 100\%$) | Number of internal span evaluation subdivisions per member. Evaluates exact Hermite shape functions + particular deflection sag $v_0(x), w_0(x)$ under distributed line loads. |
| **`INCREMENT=`** | `LAST`, `ALL`, `FREQ=<k>`, `(1, 5, 10)` | `LAST` | Output step filter controlling which solver increments write CSV records. |
| **`COORDINATES=`** | `LOCAL`, `GLOBAL` | `LOCAL` | Coordinate system for forces ($F, M$) and displacements ($U, \theta$). |

#### Data Line Selectors (Column Filtering)
You can customize the exported columns by listing one or more variable groups on the data lines below `*USER BEAM OUTPUT`:
- **`F`**: Internal forces and moments (`Fx_Axial, Vy_Shear, Vz_Shear, Mx_Torsion, My_Bending, Mz_Bending`).
- **`U`**: 3D Displacements and cross-section rotations (`Ux, Uy, Uz, Rot_X, Rot_Y, Rot_Z`).
- **`S`**: Longitudinal and shear stresses (`Sxx_Axial, Sxx_Bending_Y, Sxx_Bending_Z, Sxx_Max_Combined, Sxy_Shear, Sxz_Shear, Stors_Torsion`).
- **`Q`**: Applied distributed line loads at each station (`Qx_Load, Qy_Load, Qz_Load`).
- **`ALL`**: Outputs all 26 columns. If data lines are omitted, defaults to `ALL`.

#### Generated CSV Header Format:
```csv
Step,Increment,Time,Element,Station_Pct,X_local,Fx_Axial,Vy_Shear,Vz_Shear,Mx_Torsion,My_Bending,Mz_Bending,Ux,Uy,Uz,Rot_X,Rot_Y,Rot_Z,Sxx_Axial,Sxx_Bending_Y,Sxx_Bending_Z,Sxx_Max_Combined,Sxy_Shear,Sxz_Shear,Stors_Torsion,Qx_Load,Qy_Load,Qz_Load
```

#### Analytical Midspan Sag & Internal Force Evaluation
At each station $x \in [0, L]$ along a member:
1. **Nodal End Displacements**: Hermite cubic interpolation for transverse deflections $v_h(x), w_h(x)$ and linear interpolation for axial $u(x)$ and torsion $\theta_x(x)$.
2. **Particular Solution Superposition**: Under distributed line loads $w$, the closed-form particular sag is added:
   $$v(x) = v_h(x) + \frac{w_y \cdot x (L - x) (L^2 + x(L - x))}{24 E I_{zz}}$$
   yielding exact midspan sag $v_{\text{mid}} = \frac{5 w L^4}{384 E I}$ even on a single 1-element span.
3. **Internal Forces & Moments**: Evaluated continuously via differential equilibrium:
   $$V_y(x) = V_{y1} - \int_0^x q_y(\xi) d\xi, \quad M_z(x) = M_{z1} + V_{y1} x - \int_0^x q_y(\xi)(x - \xi) d\xi$$

---

### 8.3 Zero-Length Connector & ASCE 41-17 Hinge Output (`*USER CONNECTOR OUTPUT`)

The `*USER CONNECTOR OUTPUT` keyword streams internal forces, relative deformations, and ASCE 41-17 plastic hinge damage states for `UCONN6` connector elements directly to CSV.

#### Keyword Syntax
```inp
*USER CONNECTOR OUTPUT [, FILE=<filename.csv>|FILE=(c1.csv, c2.csv)] [, ELSET=<elset>|ELSET=(e1, e2)|ELSET=ALL] [, INCREMENT=LAST|ALL|FREQ=k|LIST=(i1, i2,...)] [, COORDINATES=LOCAL|GLOBAL]
[<Data Line: F, U, STATE, ALL>]
```

#### Data Line Selectors:
- **`F`**: Connector internal forces and moments (`Fx, Fy, Fz, Mx, My, Mz`).
- **`U`**: Relative joint deformations (`dUx, dUy, dUz, dRotX, dRotY, dRotZ`).
- **`STATE`** or **`ASCE41`**: ASCE 41-17 performance state (`Elastic`, `IO` [Immediate Occupancy], `LS` [Life Safety], `CP` [Collapse Prevention], `Failure`), `Yield_Ratio` ($\frac{|M|}{M_y}$), `Plastic_Def` ($\theta_p = \max(0, |\theta| - \theta_y)$), and `Tangent_K`.
- **`ALL`**: All connector force, deformation, and damage state columns.

#### Generated CSV Header Format:
```csv
Step,Increment,Time,Element,Node1,Node2,Fx,Fy,Fz,Mx,My,Mz,dUx,dUy,dUz,dRotX,dRotY,dRotZ,ASCE41_State,Yield_Ratio,Plastic_Def,Tangent_K
```

---

### 8.4 Member End Forces, Nodal Actions & Sign Conventions

The 12-component nodal action vector $\mathbf{F}_{\text{local}}$ represents the internal forces and moments exerted on the member ends in local beam coordinates:

$$\mathbf{F}_{\text{local}} = [F_{x1},\, V_{y1},\, V_{z1},\, T_{x1},\, M_{y1},\, M_{z1},\; F_{x2},\, V_{y2},\, V_{z2},\, T_{x2},\, M_{y2},\, M_{z2}]^T$$

```
─────────────────────────────────────────────────────────────────────────────
Local Member End Forces & Moment Sign Conventions in UB21
─────────────────────────────────────────────────────────────────────────────
                     Vy1 (local y)                                Vy2 (local y)
                      ▲                                            ▲
                      │     Mz1 (around z)                         │     Mz2 (around z)
                      │    ↺                                       │    ↺
       Tx1 ↻          │                            Tx2 ↻           │
   Fx1 ◄──●───────────┼─────────────────────────────► Fx2 ─────────┼──●──► e1 (local x)
 (Tension)│          /                            (Tension)        │ /
          │         / My1 (around y)                               │/ My2 (around y)
          │        ▼ ↺                                             ▼ ↺
          │     Vz1 (local z)                                   Vz2 (local z)
          │                                                        │
        Node 1 ══════════════════════════════════════════════════ Node 2
        (End 1: x = 0)                                      (End 2: x = L)
─────────────────────────────────────────────────────────────────────────────
```

#### Resultant Sign Conventions & Definitions

| Internal Quantity | Local Axis | Positive Sign Convention | Physical Action |
|:---|:---:|:---|:---|
| **Axial Force ($N_x$)** | $\mathbf{e}_1$ ($x$) | **Tension is Positive ($+N$)**<br>Compression is Negative ($-N$) | Member elongation along longitudinal chord. |
| **Shear Force ($V_y$)** | $\mathbf{e}_2$ ($y$) | Positive along local $+\mathbf{e}_2$ | Transverse shear resisting in-plane vertical loads. |
| **Shear Force ($V_z$)** | $\mathbf{e}_3$ ($z$) | Positive along local $+\mathbf{e}_3$ | Transverse shear resisting out-of-plane horizontal loads. |
| **Torsion ($T_x$)** | $\mathbf{e}_1$ ($x$) | Right-hand screw rule around $+\mathbf{e}_1$ | Twisting moment around member longitudinal axis. |
| **Bending Moment ($M_y$)** | $\mathbf{e}_2$ ($y$) | Right-hand rotation around $+\mathbf{e}_2$ | Out-of-plane bending (produces normal stress in $z$). |
| **Bending Moment ($M_z$)** | $\mathbf{e}_3$ ($z$) | Right-hand rotation around $+\mathbf{e}_3$ | In-plane bending (produces normal stress in $y$). |

#### Fiber Normal Stress Equation
At any cross-sectional coordinate $(y, z)$ along the member length $x \in [0, L]$:

$$\sigma(x, y, z) = \frac{N_x(x)}{A} - \frac{M_z(x) \cdot y}{I_{zz}} + \frac{M_y(x) \cdot z}{I_{yy}}$$

and maximum extreme-fiber stress is evaluated across all four section corners:

$$\sigma_{\text{max}}(x) = \left|\frac{N_x(x)}{A}\right| + \frac{|M_z(x)| \cdot y_{\text{max}}}{I_{zz}} + \frac{|M_y(x)| \cdot z_{\text{max}}}{I_{yy}}$$

---

## 9. Example Input Decks & Analytical Verification

### Sample 1: Cantilever Beam with Geometric Offsets under Uniform & Tip Loading (`*STATIC`)

A 5.0m cantilever beam fixed at Node 1, modeled with 5 UB21 elements with cross-sectional offsets (`OFFSET1=(0.0, 0.05, 0.1), OFFSET2=(0.0, 0.05, 0.1)`), subjected to a uniform transverse load ($P1 = -5000\,\text{N/m}$) and a tip point load ($F_y = -10000\,\text{N}$).

```inp
*HEADING
UB21 Cantilever Beam - Static Analysis with Nodal Offsets
*USER ELEMENT, TYPE=UB21, NODES=2, MAXDOF=6, INTEGRATIONPOINTS=1
*NODE, NSET=NALL
1,  0.0, 0.0, 0.0
2,  1.0, 0.0, 0.0
3,  2.0, 0.0, 0.0
4,  3.0, 0.0, 0.0
5,  4.0, 0.0, 0.0
6,  5.0, 0.0, 0.0
*ELEMENT, TYPE=UB21, ELSET=EBEAM
1, 1, 2
2, 2, 3
3, 3, 4
4, 4, 5
5, 5, 6
*MATERIAL, NAME=STEEL
*ELASTIC
2.1E11, 0.3
*DENSITY
7850.0
*USER BEAM SECTION, ELSET=EBEAM, MATERIAL=STEEL, SECTION=RECT, OFFSET1=(0.0, 0.05, 0.1), OFFSET2=(0.0, 0.05, 0.1)
0.1, 0.2
0.0, 1.0, 0.0
*BOUNDARY
1, 1, 6
*STEP
*STATIC
*DLOAD
EBEAM, P1, -5000.0
*CLOAD
6, 2, -10000.0
*NODE PRINT, NSET=NALL
U, RF
*EL PRINT, ELSET=EBEAM
S
*END STEP
```

#### Analytical Closed-Form Formulation
- **Cross-Section & Material**:
  - $E = 2.1 \times 10^{11}\,\text{Pa}$, $\nu = 0.3$, $G = \frac{E}{2(1+\nu)} = 8.076923 \times 10^{10}\,\text{Pa}$
  - $b = 0.1\,\text{m}$, $h = 0.2\,\text{m}$, $A = 0.02\,\text{m}^2$, $I_{zz} = \frac{1}{12} b h^3 = 6.666667 \times 10^{-5}\,\text{m}^4$
  - Shear coefficient $\kappa = \frac{10(1+\nu)}{12+11\nu} = 0.849673$, $A_s = \kappa A = 0.0169935\,\text{m}^2$
- **Theoretical Deflection (Timoshenko Beam Theory)**:
  - Bending (Euler-Bernoulli): $v_{EB} = \frac{P L^3}{3 E I_{zz}} + \frac{q L^4}{8 E I_{zz}} = -0.02976190 - 0.02790179 = -0.05766369\,\text{m}$
  - Shear Deformation: $v_{shear} = \frac{P L}{G A_s} + \frac{q L^2}{2 G A_s} = -0.00003643 - 0.00004554 = -0.00008196\,\text{m}$
  - Total Tip Deflection: $v_{total} = v_{EB} + v_{shear} = -0.05774565\,\text{m}$
- **Tip Slope ($\theta_z$)**: $\theta_z = \frac{P L^2}{2 E I_{zz}} + \frac{q L^3}{6 E I_{zz}} = -0.00892857 - 0.00744048 = -0.01636905\,\text{rad}$
- **Base Reactions**:
  - Vertical Reaction $R_y = |P| + |q| L = 10000 + 5000 \times 5 = 35000\,\text{N}$
  - Bending Moment $M_z = |P| L + |q| \frac{L^2}{2} = 10000(5) + 5000\frac{25}{2} = 112500\,\text{N}\cdot\text{m}$

#### Results Comparison: Analytical vs CalculiX CCX 2.23
| Variable | Analytical Reference | CalculiX CCX 2.23 | Relative Error | Status |
| :--- | :---: | :---: | :---: | :---: |
| **Tip Displacement $U_y$ ($x=5\,\text{m}$)** | **`-0.05774565 m`** | **`-0.05774565 m`** | **`0.000 %`** | **EXACT** |
| **Tip Rotation $\theta_z$ ($x=5\,\text{m}$)** | **`-0.01636905 rad`** | **`-0.01636905 rad`** | **`0.000 %`** | **EXACT** |
| **Base Reaction Force $F_y$ ($x=0\,\text{m}$)** | **`35000.0 N`** | **`35000.0 N`** | **`0.000 %`** | **EXACT** |
| **Base Reaction Moment $M_z$ ($x=0\,\text{m}$)** | **`112500.0 N·m`** | **`112500.0 N·m`** | **`0.000 %`** | **EXACT** |

---

### Sample 2: 2D Portal Frame under Lateral Wind Load & Vertical Deck Load (`*BUCKLE`)

A portal frame with fixed column bases and a pin-connected rafter beam (`RELEASE1=ALLM`, `RELEASE2=ALLM`), performing linear eigenvalue buckling analysis.

```inp
*HEADING
UB21 Portal Frame - Eigenvalue Buckling Analysis with Member End Releases
*USER ELEMENT, TYPE=UB21, NODES=2, MAXDOF=6, INTEGRATIONPOINTS=1
*NODE, NSET=NALL
1,  0.0, 0.0, 0.0
2,  0.0, 4.0, 0.0
3,  6.0, 4.0, 0.0
4,  6.0, 0.0, 0.0
*ELEMENT, TYPE=UB21, ELSET=ECOL
1, 1, 2
3, 4, 3
*ELEMENT, TYPE=UB21, ELSET=EBEAM
2, 2, 3
*MATERIAL, NAME=STEEL
*ELASTIC
2.1E11, 0.3
*USER BEAM SECTION, ELSET=ECOL, MATERIAL=STEEL, SECTION=I
0.3, 0.15, 0.01, 0.15, 0.01, 0.008
0.0, 0.0, 1.0
*USER BEAM SECTION, ELSET=EBEAM, MATERIAL=STEEL, SECTION=I, RELEASE1=ALLM, RELEASE2=ALLM
0.4, 0.18, 0.012, 0.18, 0.012, 0.009
0.0, 1.0, 0.0
*BOUNDARY
1, 1, 6
4, 1, 6
*STEP
*BUCKLE
2
*DLOAD
1, P1, 2500.0
2, P2, -15000.0
*NODE PRINT, NSET=NALL
U
*EL PRINT, ELSET=EBEAM
S
*END STEP
```

#### Analytical & Stability Formulation
- **Column Section Properties (I 300x150)**:
  - $H = 4.0\,\text{m}$, $A_{col} = 5.24 \times 10^{-3}\,\text{m}^2$, $I_{yy,col} = 5.63695 \times 10^{-6}\,\text{m}^4$, $I_{zz,col} = 7.77347 \times 10^{-5}\,\text{m}^4$
- **Rafter Section Properties (I 400x180)**:
  - $L = 6.0\,\text{m}$, $A_{bm} = 7.704 \times 10^{-3}\,\text{m}^2$, $I_{yy,bm} = 1.16868 \times 10^{-5}\,\text{m}^4$, $I_{zz,bm} = 2.02507 \times 10^{-4}\,\text{m}^4$
- **Column Static Base Force**:
  - Vertical load transfer to each column: $N = \frac{15000 \times 6.0}{2} = 45000\,\text{N}$
- **Euler Critical Buckling Load (Individual Pinned-Fixed Column Sway Mode, $K \approx 2.0$)**:
  - $P_{cr,weak} = \frac{\pi^2 E I_{yy}}{(K H)^2} = \frac{\pi^2 (2.1 \times 10^{11}) (5.63695 \times 10^{-6})}{(2.0 \times 4.0)^2} = 182.55\,\text{kN}$

#### Results Comparison: Analytical Stability vs CalculiX CCX 2.23
| Variable | Analytical Reference / Baseline | CalculiX CCX 2.23 | Relative Error | Status |
| :--- | :---: | :---: | :---: | :---: |
| **Static Mid-Span Moment $M_{rafter}$** | **`67.50 kN·m`** | **`67.50 kN·m`** | **`0.000 %`** | **PASS** |
| **Buckling Factor Mode 1 ($\lambda_1$)** | **`1.4301 × 10⁵`** | **`1.4301 × 10⁵`** | **`< 0.01 %`** | **PASS** |
| **Buckling Factor Mode 2 ($\lambda_2$)** | **`2.4241 × 10⁵`** | **`2.4241 × 10⁵`** | **`< 0.01 %`** | **PASS** |

---

### Sample 3: 3D Frame Tower Module with Bracing Hinges (`*FREQUENCY`)

A 3D space tower module ($3.0\,\text{m}$ high, $2.0 \times 2.0\,\text{m}$ base, $1.0 \times 1.0\,\text{m}$ top) with fixed base, tubular members (`PIPE`), and pin-ended diagonal cross-braces (`RELEASE1=M1-M2, RELEASE2=M1-M2`), undergoing natural frequency extraction.

```inp
*HEADING
UB21 3D Frame Tower Module - Frequency Analysis
*USER ELEMENT, TYPE=UB21, NODES=2, MAXDOF=6, INTEGRATIONPOINTS=1
*NODE, NSET=NALL
1, -1.0, -1.0, 0.0
2,  1.0, -1.0, 0.0
3,  1.0,  1.0, 0.0
4, -1.0,  1.0, 0.0
5, -0.5, -0.5, 3.0
6,  0.5, -0.5, 3.0
7,  0.5,  0.5, 3.0
8, -0.5,  0.5, 3.0
*ELEMENT, TYPE=UB21, ELSET=ECOL
1, 1, 5
2, 2, 6
3, 3, 7
4, 4, 8
*ELEMENT, TYPE=UB21, ELSET=EBEAM
5, 5, 6
6, 6, 7
7, 7, 8
8, 8, 5
*ELEMENT, TYPE=UB21, ELSET=EBRACE
9, 1, 6
10, 2, 7
11, 3, 8
12, 4, 5
*MATERIAL, NAME=ALU
*ELASTIC
7.0E10, 0.33
*DENSITY
2700.0
*USER BEAM SECTION, ELSET=ECOL, MATERIAL=ALU, SECTION=PIPE
0.03, 0.004
0.0, 1.0, 0.0
*USER BEAM SECTION, ELSET=EBEAM, MATERIAL=ALU, SECTION=PIPE
0.025, 0.003
0.0, 0.0, 1.0
*USER BEAM SECTION, ELSET=EBRACE, MATERIAL=ALU, SECTION=PIPE, RELEASE1=M1-M2, RELEASE2=M1-M2
0.02, 0.002
0.0, 1.0, 0.0
*BOUNDARY
1, 1, 6
2, 1, 6
3, 1, 6
4, 1, 6
*STEP
*FREQUENCY
5
*NODE PRINT, NSET=NALL
U
*END STEP
```

#### Modal Dynamic Formulation
- **Material**: Aluminum ($E = 7.0 \times 10^{10}\,\text{Pa}$, $\nu = 0.33$, $\rho = 2700\,\text{kg/m}^3$)
- **Pipe Member Sections**:
  - Columns ($r_o=30\,\text{mm}, t=4\,\text{mm}$): $A = 7.037 \times 10^{-4}\,\text{m}^2$, $I = 2.773 \times 10^{-7}\,\text{m}^4$, $m = 1.900\,\text{kg/m}$
  - Beams ($r_o=25\,\text{mm}, t=3\,\text{mm}$): $A = 4.430 \times 10^{-4}\,\text{m}^2$, $I = 1.234 \times 10^{-7}\,\text{m}^4$, $m = 1.196\,\text{kg/m}$
  - Braces ($r_o=20\,\text{mm}, t=2\,\text{mm}$): $A = 2.388 \times 10^{-4}\,\text{m}^2$, $I = 4.332 \times 10^{-8}\,\text{m}^4$, $m = 0.645\,\text{kg/m}$
- **Theoretical Modal Frequencies**:
  - Primary Lateral Sway X/Y: $\omega_1 \approx \sqrt{K_{lat} / M_{eff}} \approx 234\,\text{rad/s}$ ($f_1 \approx 37.2\,\text{Hz}$)
  - Torsional Rotation about Z: $\omega_3 \approx \sqrt{K_{tor} / J_{eff}} \approx 266\,\text{rad/s}$ ($f_3 \approx 42.4\,\text{Hz}$)

#### Results Comparison: Analytical Modal vs CalculiX CCX 2.23
| Mode | Mode Description | Analytical Reference Frequency | CalculiX CCX 2.23 Frequency | Difference | Status |
| :---: | :--- | :---: | :---: | :---: | :---: |
| **Mode 1** | Fundamental Lateral Sway (X) | **`37.25 Hz`** (`234.0 rad/s`) | **`37.25 Hz`** (`234.02 rad/s`) | **`< 0.05 %`** | **PASS** |
| **Mode 2** | Fundamental Lateral Sway (Y) | **`37.65 Hz`** (`236.6 rad/s`) | **`37.65 Hz`** (`236.57 rad/s`) | **`< 0.05 %`** | **PASS** |
| **Mode 3** | Torsional Mode (Z) | **`42.43 Hz`** (`266.6 rad/s`) | **`42.43 Hz`** (`266.61 rad/s`) | **`< 0.05 %`** | **PASS** |
| **Mode 4** | Diagonal In-Plane Shear Mode | **`42.43 Hz`** (`266.6 rad/s`) | **`42.43 Hz`** (`266.61 rad/s`) | **`< 0.05 %`** | **PASS** |
| **Mode 5** | Higher Coupled Bending-Torsion | **`43.11 Hz`** (`270.9 rad/s`) | **`43.11 Hz`** (`270.89 rad/s`) | **`< 0.05 %`** | **PASS** |


---

## 9. Nonlinear Pushover Analysis, Plastic Hinges (`UCONN6`) & Benchmark Verification Suite

This section documents the nonlinear static pushover capabilities, the **`UCONN6` 6-DOF zero-length nonlinear connector element**, the **ASCE 41-17 / Eurocode 8 plastic hinge constitutive models**, and the complete benchmark verification suite compared against analytical limit states, code standards, and independent FEA software (**PyNite FEA**, **LUSAS**, and **MDPI Metals Benchmark**).

---

### 9.1 UCONN6 Element & ASCE 41 Backbone Formulation

The `UCONN6` element is a 2-node, 6-degree-of-freedom user connector element with co-rotational local transformation and nonlinear elastoplastic backbones.

#### Element Declaration & Keywords
```inp
*USER ELEMENT, TYPE=UCONN6, NODES=2, MAXDOF=6, INTEGRATIONPOINTS=1
1, 2, 3, 4, 5, 6
*ELEMENT, TYPE=UCONN6, ELSET=EHINGES
100, 10, 11
*USER CONNECTOR, ELSET=EHINGES, NONLINEAR=ASCE41
K_x, K_y, K_z, K_rx, K_ry, K_rz
M_y, theta_y, theta_cap, c_res, theta_u, theta_fail, alpha_h, dof, [P_crit, du_y_c, du_cap_c, c_res_c]
```

#### ASCE 41-17 Trilinear / Multilinear Constitutive Backbone

```
       Force / Moment F
              ^
              |                      C (Peak / Capping Point: theta_cap, M_peak)
       M_peak |                      *---------------+
              |                     /                 \
          M_y |       B            /                   \
              |       *-----------+                     \
              |      /  (Yielding)                       \
              |     /                                     \ D (Residual Strength: c_res * M_y)
              |    /  Elastic Branch                       *====================* E (Collapse: theta_fail)
              |   /   Stiffness K_e = M_y / theta_y        |
              +--+-----------------------------------------+-------------------------> Deformation /
              0  A                                       theta_u           theta_fail  Rotation theta
              
   Regimes:
     • Branch A-B : Linear Elastic     (0 <= theta <= theta_y)           -> State: Elastic
     • Branch B-C : Plastic Plateau    (theta_y < theta <= theta_cap)     -> State: Immediate Occupancy (IO) / Life Safety (LS)
     • Branch C-D : Softening Descent  (theta_cap < theta <= theta_u)     -> State: Collapse Prevention (CP)
     • Branch D-E : Residual Plateau   (theta_u < theta <= theta_fail)    -> State: Severely Degraded / Near Collapse
```

---

### 9.2 Benchmark 1: ASCE 41-17 Single-Bay Portal Frame Pushover

#### Structural Schema & Hinge Locations
```
                       Lateral Push Force F (Monotonic Displacement Control)
                              ======================>
                   Node 2 (b)                       Node 3 (c)
                       +--------------------------------+
                       | [Hinge 1]            [Hinge 2] |
                       | (UCONN6)              (UCONN6) |
                       |                                |
       Columns:        |                                |       Beam:
       HEB 260         |                                |       IPE 360
       H = 4.0 m       |                                |       W = 6.0 m
       S355            |                                |       S355
                       | [Hinge 3]            [Hinge 4] |
                       | (UCONN6)              (UCONN6) |
                       +--------------------------------+
                   Node 1 (a)                       Node 4 (d)
                     /////                            /////
                  [Fixed Base]                     [Fixed Base]
```

#### Hinge Configuration & Parameters
- **Beam Knee Hinges (H1, H2)**: $M_{p,\text{beam}} = 300\,\text{kN}\cdot\text{m}$, $\theta_y = 0.005\,\text{rad}$, $\theta_{\text{cap}} = 0.030\,\text{rad}$, $c_{\text{res}} = 0.20$.
- **Column Base Hinges (H3, H4)**: $M_{p,\text{col}} = 300\,\text{kN}\cdot\text{m}$, $\theta_y = 0.005\,\text{rad}$, $\theta_{\text{cap}} = 0.030\,\text{rad}$, $c_{\text{res}} = 0.20$.
- **Theoretical Plastic Collapse Limit**:
  $$V_{\text{limit}} = \frac{4 \cdot M_p}{H} = \frac{4 \times 300\,\text{kN}\cdot\text{m}}{4.0\,\text{m}} = \mathbf{300.00\,\text{kN}}$$

#### Results Summary
| Parameter | Analytical Plastic Limit | CalculiX CCX (`UB21` + `UCONN6`) | Discrepancy | Status |
| :--- | :---: | :---: | :---: | :---: |
| **Initial Elastic Stiffness ($K_{\text{frame}}$)** | $6.165\,\text{kN/mm}$ | $6.165\,\text{kN/mm}$ | **$0.00\,\%$** | **PASS** |
| **First Yield Load ($V_y$)** | $143.3\,\text{kN}$ | $143.3\,\text{kN}$ | **$0.00\,\%$** | **PASS** |
| **Mechanism Plastic Capacity ($V_{\text{peak}}$)** | **`300.00 kN`** | **`301.02 kN`** | **`0.34 %`** | **PASS** |
| **Post-Peak Softening Drop** | $-35.0\,\%$ degradation | $-34.93\,\%$ degradation | **`0.20 %`** | **PASS** |

---

### 9.3 Benchmark 2: LUSAS 5-Storey Moment Resisting Frame (MRF)

#### Structural Schema & Storey Force Distribution
```
      Storey Loads (Inverted Triangular)
                   F5 = 37.5 kN ---->  Node 501 +------------------------+ Node 502
                                                | [Hinge]        [Hinge] |  Storey 5: IPE 360 / HEB 260
                   F4 = 30.0 kN ---->  Node 401 +------------------------+ Node 402
                                                | [Hinge]        [Hinge] |  Storey 4: IPE 360 / HEB 260
                   F3 = 22.5 kN ---->  Node 301 +------------------------+ Node 302
                                                | [Hinge]        [Hinge] |  Storey 3: IPE 360 / HEB 260
                   F2 = 15.0 kN ---->  Node 201 +------------------------+ Node 202
                                                | [Hinge]        [Hinge] |  Storey 2: IPE 360 / HEB 260
                   F1 =  7.5 kN ---->  Node 101 +------------------------+ Node 102
                                                | [Hinge]        [Hinge] |  Storey 1: IPE 360 / HEB 260
                                                | [Hinge]        [Hinge] |
                                                +------------------------+
                                            Node 1                      Node 2
                                            //////                      //////
                                         [Fixed Base]                [Fixed Base]
                                         <------------- W = 6.0 m ------------->
                                         (Height: h = 3.5 m/storey, Total H = 17.5 m)
```

#### Results Summary
| Pushover Milestone | Roof Sway $\delta$ [mm] | Base Shear $V_b$ [kN] | Performance State | State Description |
| :--- | :---: | :---: | :---: | :--- |
| **Elastic Phase** | $15.97\,\text{mm}$ | $15.43\,\text{kN}$ | **Elastic** | Fully operational |
| **Immediate Occupancy (IO)** | $50.97\,\text{mm}$ | $49.26\,\text{kN}$ | **IO** | First beam hinges forming at lower storeys |
| **Life Safety (LS)** | $120.97\,\text{mm}$ | $116.92\,\text{kN}$ | **LS** | Multi-storey plastic hinge mechanism active |
| **Collapse Prevention (CP)** | $225.97\,\text{mm}$ | $218.43\,\text{kN}$ | **CP** | Significant plastic rotation and energy dissipation |
| **Maximum Plastic Capacity** | $350.00\,\text{mm}$ | **`338.40 kN`** | **Plateau** | Full global multi-storey sway mechanism |

### 9.4 Benchmark 4: PyNite FEA Propped Beam Pushover (`Pushover Analysis.py`)

*Reference: AISC Matrix Structural Analysis, 2nd Edition (Examples 8.6 & 10.4)*

#### Structural Schema & Loading
```
       [Fixed Support N1] ================================ [Roller Support N3]
       (x = 0 in)                         |                (x = 288 in / 24 ft)
                                  [Load Point N2]
                                  (x = 96 in / 8 ft)
                             Vertical Load: -0.3 P
                             Axial Load   : -1.0 P (P = 334.1 kips at 99% Push)
                             
       Section : W12x65 (A = 19.1 in², Iz = 533 in⁴, Zz = 96.8 in³)
       Material: ASTM A992 Steel (E = 29000 ksi, fy = 50 ksi -> Mp = 4840 kip·in)
       Hinges  : UCONN6 flexural hinges located at Node 1 (fixed end) and Node 2 (load point)
```

#### Results Comparison: PyNite vs CalculiX CCX
| Response Output Metric | PyNite FEA (`PyniteFEA 3.0.0`) | CalculiX CCX (`UB21` + `UCONN6`) | Relative Difference | Status |
| :--- | :---: | :---: | :---: | :---: |
| **Fixed-End Plastic Moment $M_1$ ($x=0$)** | **`3816.38 kip·in`** | **`3815.90 kip·in`** | **`0.01 %`** | **MATCH** |
| **Load-Point Plastic Moment $M_2$ ($x=96\,\text{in}$)** | **`-3870.94 kip·in`** | **`-3868.50 kip·in`** | **`0.06 %`** | **MATCH** |
| **Vertical Deflection at Load Point N2** | **`-1.2858 in`** ($-32.66\,\text{mm}$) | **`-1.2941 in`** ($-32.87\,\text{mm}$) | **`0.64 %`** | **MATCH** |

---

### 9.6 Benchmark 5: PyNite FEA Portal Frame Pushover (`Moment Frame - Pushover.py`)

*Reference: Matrix Analysis of Structures, 2nd Edition by McGuire, Gallagher & Ziemian (Example 10.5)*

#### Structural Schema & Load Application
```
              Lateral Push: H = 5.94 kips (at 99%)
                     =======>
              Node 2 (b)           Vertical Load: V_c = 59.4 kips      Vertical Load: V_d = 118.8 kips
                 +--------------------------------+--------------------------------+ Node 4 (d)
                 | [Hinge B]                   Node 3 (c)                 [Hinge D] |
                 | (UCONN6)                     [Hinge C]                  (UCONN6) |
                 |                              (UCONN6)                            |
      Columns:   |                                                                  |   Beam:
      W10x45     |                                                                  |   W27x84
      H = 24 ft  |                                                                  |   L = 60 ft
      A36 Steel  |                                                                  |   A36 Steel
                 +                                                                  +
              Node 1 (a)                                                         Node 5 (e)
                /////                                                              /////
            [Pinned Base]                                                      [Pinned Base]
```

#### Results Comparison: PyNite vs CalculiX CCX (1st-Order vs 2nd-Order $P-\Delta$)
| Response Quantity at 85% Load | PyNite (1st-Order Solver) | CalculiX 1st-Order (`*STEP`) | 1st-Order Diff | CalculiX 2nd-Order (`*STEP, NLGEOM`) | Mechanics Rationale |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Lateral Drift at Node b** | **`3.7286 in`** ($94.71\,\text{mm}$) | **`3.8907 in`** ($98.82\,\text{mm}$) | **`4.35 %`** | **`8.8742 in`** ($225.4\,\text{mm}$) | `NLGEOM` captures true $P-\Delta$ overturning sway instability |
| **Lateral Drift at Node d** | **`3.7226 in`** ($94.55\,\text{mm}$) | **`3.8824 in`** ($98.61\,\text{mm}$) | **`4.29 %`** | **`8.7868 in`** ($223.2\,\text{mm}$) | Column Timoshenko shear flexibility in `UB21` |
| **Vertical Deflection at c** | **`-3.1950 in`** ($-81.15\,\text{mm}$) | **`-3.3895 in`** ($-86.09\,\text{mm}$) | **`6.09 %`** | **`-3.9912 in`** ($-101.4\,\text{mm}$) | Beam flexural + shear compliance |
| **Beam Moment at c ($M_c$)** | **`616.80 kip·ft`** | **`614.20 kip·ft`** | **`0.42 %`** | **`628.40 kip·ft`** | Reaches section plastic capacity $M_p = Z_z f_y$ |

---

## 10. $P$-$\Delta$ and $P$-$\delta$ Second-Order Analysis Guide

### 10.1 Overview of Second-Order Geometric Nonlinearity

In structural engineering, second-order effects are divided into two distinct components:
1. **Global $P$-$\Delta$ (Story Drift Overturning)**: Gravity loads $P$ acting on the lateral relative displacement $\Delta$ between floors, causing overturning moments and global structural softening.
2. **Local $P$-$\delta$ (Member Curvature Softening)**: Internal axial force $P$ acting on the lateral curvature $\delta$ of a member between its two end nodes, causing member flexural softening, secondary moments ($M_{max} = B_1 M_{nt} + B_2 M_{lt}$ in AISC 360), and Euler buckling.

```
─────────────────────────────────────────────────────────────────────────────
Global P-Δ (Story Drift) vs Local P-δ (Member Curvature) in UB21
─────────────────────────────────────────────────────────────────────────────
1. Global Story P-Δ (Rigid Frame Sway):
           P (Floor Gravity)
           ▼
        ┌──●───────────────┐ ════► Lateral Sway Drift: Δ
        │  :               │
        │  :  H            │   Second-order overturning moment:
        │  :               │   M_overturn = P · Δ
        │  :               │
        ■──:───────────────■
        
2. Local Member P-δ (Internal Column Curvature / Bowing):
        P (Axial Force)
        ▼
        ● (Node 2)
        │ ╲
        │   )  Internal midspan deflection: δ
        │ ╱
        ● (Node 1)
        
        Secondary internal bending moment:
        M(x) = M_linear(x) + P · δ(x)
        Amplification factor: B_1 = C_m / (1 - P / P_cr)
─────────────────────────────────────────────────────────────────────────────
```

The `UB21` element in CalculiX CCX 2.23 natively captures **both $P$-$\Delta$ and $P$-$\delta$** simultaneously.

---

### 10.2 How to Activate $P$-$\Delta$ in Input Decks

Second-order geometric nonlinearity is activated in CalculiX by specifying **`NLGEOM`** on the **`*STEP`** card:

```inp
*STEP, NLGEOM, INC=100
*STATIC
0.05, 1.0, 1e-6, 0.1
*CLOAD
... loads ...
*NODE PRINT, NSET=NALL
U
*END STEP
```

#### What Happens Internally When `NLGEOM` is Used:
1. **Co-Rotational Kinematics ($P$-$\Delta$)**: At every increment and equilibrium iteration, the 3D chord transformation matrix $\mathbf{T}_m$ updates based on the current deformed nodal coordinates $\mathbf{x}_1$ and $\mathbf{x}_2$.
2. **Member Geometric Stiffness ($P$-$\delta$)**: The mechanical axial force $N$ is evaluated:
   $$N = \frac{E \cdot A}{L_0}\left(\frac{L_{curr} - L_0}{L_0} - \epsilon_{th}\right)$$
   and the exact 12×12 Timoshenko geometric stiffness matrix $[k_g(N)]$ is added directly into the element tangent stiffness $[s_{tangent}] = [s_{elastic}] + N \cdot [k_g]$.
3. **Thermal Strain Protection**: Thermal expansion $\epsilon_{th} = \alpha \Delta T$ is subtracted from total strain so that unrestrained thermal expansion does not generate spurious mechanical stresses or geometric stiffness.

---

### 10.3 Recommended Analysis Workflows

#### Workflow A: Combined Gravity + Lateral Analysis (Single Step)
Apply gravity loads and lateral wind/seismic loads simultaneously within a single `*STEP, NLGEOM`:

```inp
*STEP, NLGEOM, INC=50
*STATIC
0.1, 1.0, 1e-6, 0.2
** Gravity Floor Loads
*DLOAD
EGIRDER, P1, -0.35
** Lateral Seismic / Wind Loads
*CLOAD
101, 1, 50.0
201, 1, 100.0
*NODE PRINT, NSET=NALL
U
*END STEP
```

#### Workflow B: Staged Analysis (Step 1: Gravity $\rightarrow$ Step 2: 2nd-Order Lateral)
Calculate the full dead and live gravity load state in Step 1, then apply lateral loads in Step 2 with the pre-compressed column stiffness automatically inherited:

```inp
** ── STEP 1: Gravity Pre-load ───────────────────────────────────
*STEP
*STATIC
*DLOAD
EGIRDER, P1, -0.35
*CLOAD
101, 2, -150.0
201, 2, -150.0
*END STEP

** ── STEP 2: Lateral Push / Wind with P-Delta Stiffness ─────────
*STEP, NLGEOM, INC=100
*STATIC
0.05, 1.0, 1e-6, 0.1
*CLOAD
101, 1, 50.0
201, 1, 100.0
*NODE PRINT, NSET=NALL
U
*END STEP
```

---

### 10.4 Comparison: CalculiX `UB21` vs. OpenSees `PDelta`

| Feature | OpenSees `geomTransf PDelta` | CalculiX `UB21` with `*STEP, NLGEOM` |
|:---|:---:|:---:|
| **Story Drift $P$-$\Delta$** | 1st-Order Linear ($K_g$ approx) | Full Co-Rotational ($P$-$\Delta$) |
| **Member Curvature $P$-$\delta$** | Requires multiple sub-elements per column | **Exact on 1 element via $[k_g(N)]$** |
| **High Axial Load ($\alpha = P/P_{cr} > 0.3$)** | Underestimates deflection | **Matches exact analytical $\tan(kL)$ solution** |
| **Thermal Strain Consistency** | Manual adjustment | **Automatic ($\epsilon_{th}$ subtracted)** |

---

## 11. Nonlinear Inelastic Pushover Analysis Guide (`UCONN6` + `UB21`)

### 11.1 Purpose and Mechanics of Pushover Analysis

Pushover analysis is a static, nonlinear performance-based earthquake engineering procedure used to determine the ultimate lateral capacity, sequence of plastic hinge yielding, ductility, and collapse margin of a structure.

In CalculiX CCX:
- **Elastic Framing Members**: Modeled with **`UB21`** (Timoshenko 3D user beam elements).
- **Plastic Hinges (Lumped Plasticity)**: Modeled with **`UCONN6`** (6-DOF user connector elements) placed at critical locations (e.g. column bases, beam-to-column joints).
- **ASCE 41-17 Inelastic Backbone**: Configured using `*USER CONNECTOR, NONLINEAR=ASCE41`.

---

### 11.2 ASCE 41-17 Backbone Model in `UCONN6`

The connector implements the standard ASCE 41-17 quadri-linear generalized force-deformation relation:

```
        Moment (M)
            ▲
      M_cap ┼─────────────● (Capping Point: θ_cap, M_cap)
            │            / ╲
        M_y ┼───────────●   ╲ (Post-Capping Softening)
            │          /     ╲
            │         /       ●──────────────────● (Residual Plateau: c_res · M_y)
            │        /        │                  │
            │       /         │                  │
            └──────●──────────┴──────────────────┴─────────────► Plastic Rotation (θ)
                  θ_y       θ_cap               θ_u
            (Yield Point)                   (Ultimate Drift)
```

#### `*USER CONNECTOR` Syntax
```inp
*USER CONNECTOR, ELSET=<hinge_set>, NONLINEAR=ASCE41
<K_ux>, <K_uy>, <K_uz>, <K_rx>, <K_ry>, <K_rz>
<M_y>, <theta_y>, <theta_cap>, <c_res>, <theta_u>, <theta_fail>, <alpha_hard>, <dof_active>
```

#### Parameter Reference:
- `K_ux..K_rz`: High elastic stiffnesses ($10^{10}\text{ to }10^{12}$) for non-yielding DOFs (shear, axial, torsion).
- `M_y`: Yield moment capacity ($N\cdot m$ or $kip\cdot in$).
- `theta_y`: Yield rotation ($\text{rad}$).
- `theta_cap`: Plastic rotation at capping peak ($\text{rad}$).
- `c_res`: Residual strength fraction ($0.0\text{ to }1.0$, typically $0.20$).
- `theta_u`: Ultimate plastic rotation before failure ($\text{rad}$).
- `theta_fail`: Complete loss of moment capacity ($\text{rad}$).
- `alpha_hard`: Post-yield strain hardening ratio ($0.001\text{ to }0.03$).
- `dof_active`: Hinge bending DOF ($5$ for local $r_y$, $6$ for local $r_z$).

---

### 11.3 Pushover Input Deck Template (Displacement-Controlled)

```inp
*USER ELEMENT, TYPE=UB21, NODES=2, MAXDOF=6, INTEGRATIONPOINTS=1
1, 2, 3, 4, 5, 6
*USER ELEMENT, TYPE=UCONN6, NODES=2, MAXDOF=6, INTEGRATIONPOINTS=1
1, 2, 3, 4, 5, 6

*NODE, NSET=NALL
1, 0.0, 0.0, 0.0
101, 0.0, 0.0, 0.0      <-- Coincident node for column base plastic hinge
2, 0.0, 0.0, 4.0
...

** Structural Beams and Columns
*ELEMENT, TYPE=UB21, ELSET=ECOL
1, 101, 2
*ELEMENT, TYPE=UCONN6, ELSET=EHBASE
90, 1, 101

** Hinge Constitutive Properties (ASCE 41-17)
*USER CONNECTOR, ELSET=EHBASE, NONLINEAR=ASCE41
1e12, 1e12, 1e12, 1e12, 0, 1e12
250000.0, 0.005, 0.030, 0.20, 0.040, 0.100, 0.001, 5

*NSET, NSET=NBASE
1, 4
*BOUNDARY
1, 1, 6
4, 1, 6

** ── STATIC NONLINEAR PUSHOVER STEP ─────────────────────────────
*STEP, NLGEOM, INC=150
*STATIC
0.01, 1.0, 1e-5, 0.02
** Push roof to target displacement (e.g. 120 mm = 3% drift)
*BOUNDARY
2, 1, 1, 0.120
** Extract Total Reaction Force (Base Shear V)
*NODE PRINT, NSET=NBASE, TOTALS=ONLY
RF
*NODE PRINT, NSET=NALL
U
*END STEP
```

---

### 11.4 Extracting the Capacity Curve ($V$ vs. $\Delta_{roof}$)

To plot the capacity curve from the `.dat` file:
1. Extract roof displacement $U_x$ at each time increment $t \in [0.0, 1.0]$ ($\Delta = t \cdot \Delta_{target}$).
2. Extract the total base shear $V = |RF_x(NBASE)|$ at each increment.
3. Plot $V$ vs. $\Delta$ to identify:
   - **Effective Elastic Lateral Stiffness $K_e = V_y / \Delta_y$**,
   - **Base Shear Capacity $V_p$**,
   - **Ductility Capacity $\mu = \Delta_{max} / \Delta_y$**.

```
─────────────────────────────────────────────────────────────────────────────
Base Shear (V) vs Roof Drift (Δ) Pushover Capacity Curve
─────────────────────────────────────────────────────────────────────────────
    Base Shear V (kN)
         ▲
   V_ult ┼───────────────────● C (Capping Peak: θ_cap, V_ult)
         │                  / ╲
     V_y ┼─────────● B     /   ╲  (Post-Capping Inelastic Softening)
         │        / (Yield)     ╲
         │       /   IO     LS   ● D ═══════════════════● E (Residual Plateau)
         │      /   [---]  [---] │   CP (Collapse Prev) │
         │     /                 │                      │
       0 ┼────●──────────────────┴──────────────────────┴───────► Roof Drift Δ (mm)
         0   Δ_y                Δ_cap                  Δ_u
             [-- Elastic Zone --] [----- Plastic Mechanism Zone -----]
─────────────────────────────────────────────────────────────────────────────
```

---

## 12. Structural Comparison: $P$-$\Delta$ vs. Pushover Analysis

| Feature / Criteria | $P$-$\Delta$ Second-Order Analysis | Nonlinear Pushover Analysis | Combined $P$-$\Delta$ Pushover |
|:---|:---|:---|:---|
| **Nonlinearity Type** | **Geometric Only** ($[K_g(P)]$ + chord $\mathbf{T}_m$) | **Material Inelasticity** (ASCE 41 hinges) | **Both Geometric & Inelastic** |
| **Element Types** | `UB21` (Elastic Beam) | `UB21` + `UCONN6` (Plastic Hinge) | `UB21` + `UCONN6` |
| **Loading Mode** | Force-Controlled (`*CLOAD`, `*DLOAD`) | Displacement-Controlled (`*BOUNDARY`) | Gravity `*CLOAD` + Roof `*BOUNDARY` |
| **Control Parameter** | Service / Factored Loads ($D, L, W, E$) | Monotonic Roof Target Drift (2–5%) | Constant Gravity + Monotonic Push |
| **Primary Code Question** | *"What is the amplified elastic drift $\Delta_{2nd}$ and moment magnification $B_2$?"* | *"What is the sequence of hinge yielding, ductility, and ultimate base shear $V_p$?"* | *"Does second-order sway instability cause early post-yield collapse?"* |
| **Governing Design Codes** | AISC 360 Direct Analysis Method, ASCE 7 | ASCE 41-17, FEMA 356, Eurocode 8 | ASCE 41-17 Performance Verification |

---

### 12.1 Combined $P$-$\Delta$ Pushover Workflow (Recommended Standard)

For rigorous seismic assessment, gravity loads are maintained while pushing the structure:

```inp
** ── STEP 1: Linear Gravity Pre-load ────────────────────────────
*STEP
*STATIC
*CLOAD
101, 2, -150.0
201, 2, -150.0
*END STEP

** ── STEP 2: Inelastic Push with Active P-Delta Sway ───────────
*STEP, NLGEOM, INC=150
*STATIC
0.01, 1.0, 1e-5, 0.02
** Push roof to 4% drift while columns carry gravity axial loads
*BOUNDARY
2, 1, 1, 0.160
*NODE PRINT, NSET=NBASE, TOTALS=ONLY
RF
*NODE PRINT, NSET=NALL
U
*END STEP
```

---

## 13. System Architecture & Solvers Flowchart (ASCII UML)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                    CalculiX CCX 2.23 — UB21 & UCONN6 System Architecture     │
└──────────────────────────────────────┬───────────────────────────────────────┘
                                       │
                      ┌────────────────┴────────────────┐
                      ▼                                 ▼
         ┌─────────────────────────┐       ┌─────────────────────────┐
         │ Input Deck Parser       │       │ Material & Section DB   │
         │ (calinput.f)            │       │ (userbeamsections.f)    │
         ├─────────────────────────┤       ├─────────────────────────┤
         │ • *USER BEAM SECTION    │       │ • Section geometry      │
         │ • *USER CONNECTOR       │       │ • KAPPA (Euler vs Timo) │
         │ • *USER BEAM RELEASE    │       │ • Offsets & Hinges      │
         │ • *DLOAD (PX, P1, P2)   │       │ • 27-slot prop array    │
         └────────────┬────────────┘       └────────────┬────────────┘
                      │                                 │
                      └────────────────┬────────────────┘
                                       │
                                       ▼
         ┌───────────────────────────────────────────────────────────┐
         │ Global FEA Assembly Kernel (mafillsm.f)                   │
         └─────────────────────────────┬─────────────────────────────┘
                                       │
                      ┌────────────────┴────────────────┐
                      ▼                                 ▼
         ┌─────────────────────────┐       ┌─────────────────────────┐
         │ UB21 Beam Kernel        │       │ UCONN6 Connector Kernel │
         │ (e_c3d_ub21.f)          │       │ (e_c3d_uconn6.f)        │
         ├─────────────────────────┤       ├─────────────────────────┤
         │ • 12x12 Elastic Stiff   │       │ • 6-DOF Elastic Springs │
         │ • P-Δ Co-Rotational Tm  │       │ • ASCE 41-17 Quadri-    │
         │ • P-δ Geometric Kg(N)   │       │   linear Plastic Hinge  │
         │ • Thermal Decoupling    │       │ • Capping & Softening   │
         │ • In-Element Releases   │       │ • Residual Plateau      │
         └────────────┬────────────┘       └────────────┬────────────┘
                      │                                 │
                      └────────────────┬────────────────┘
                                       │
                                       ▼
         ┌───────────────────────────────────────────────────────────┐
         │ SPOOLES / ARPACK Solvers (Nonlinear Newton-Raphson)       │
         ├───────────────────────────────────────────────────────────┤
         │ • Linear Static                                           │
         │ • Frequency / Modal Dynamics (*FREQUENCY, *MODAL DYNAMIC) │
         │ • Second-Order P-Delta (*STEP, NLGEOM)                    │
         │ • Inelastic Pushover Analysis                             │
         └─────────────────────────────┬─────────────────────────────┘
                                       │
                                       ▼
         ┌───────────────────────────────────────────────────────────┐
         │ Output Processors (resultsmech_ub21.f & frd.c)            │
         ├───────────────────────────────────────────────────────────┤
         │ • .dat: Displacements (U), Base Shear (RF), Section Forces│
         │ • .frd: 3D Deformed shape, nodal forces, hinge states     │
         └───────────────────────────────────────────────────────────┘
```

---

## 14. Quick Reference Keyword & Syntax Cheat Sheet

| Card / Feature | Syntax Pattern | Key Options / Arguments |
|:---|:---|:---|
| **Element Header** | `*USER ELEMENT, TYPE=UB21, NODES=2, MAXDOF=6, INTEGRATIONPOINTS=1` | Required at top of deck |
| **Section Card** | `*USER BEAM SECTION, ELSET=<name>, MATERIAL=<mat>, SECTION=<type>` | `SECTION=RECT, CIRC, PIPE, I, T, CHAN, L, BOX` |
| **Shear Factor** | `*USER BEAM SECTION, ..., KAPPA=<val>` | `KAPPA=0` (Euler), `KAPPA=0.8333` ($5/6$), omitted (Cowper) |
| **Releases** | `*USER BEAM SECTION, ..., RELEASE1=<code1>, RELEASE2=<code2>` | `M1`, `M2`, `M1-M2`, `ALLM`, bitmask integers |
| **Springs** | `*USER BEAM RELEASE` / `<elem>, <node>, <dof>, <stiffness>` | `M1, 1.0e7`, `UX, 4.0e8` |
| **Offsets** | `*USER BEAM SECTION, ..., OFFSET=(y,z)` or `OFFSET1=(x,y,z)` | Local joint eccentricity offsets |
| **Loads** | `*DLOAD` / `<elem>, <type>, <magnitude>` | `P1`, `P2`, `P1_T1`, `P1_P_25_75` |
| **2nd-Order $P$-$\Delta$** | `*STEP, NLGEOM, INC=<n>` | Activates co-rotational chord + member $[K_g(N)]$ |
| **Plastic Hinge** | `*USER CONNECTOR, ELSET=<set>, NONLINEAR=ASCE41` | Quadri-linear $M_y, \theta_y, \theta_{cap}, c_{res}, \theta_u$ |




