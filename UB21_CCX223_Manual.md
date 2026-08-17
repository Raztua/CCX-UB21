# User Manual & Installation Guide: UB21 Beam Element & User Sections in CalculiX 2.23

This document provides a detailed installation guide, technical manual, material & section definition guide, loading reference, and analysis capability overview for the **UB21 (2-node 3D Timoshenko / Euler-Bernoulli user beam element)** patch applied to **CalculiX CCX 2.23**.

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

*(For the 3-node quadratic user beam element UB32, declare `TYPE=UB32, NODES=3, MAXDOF=6, INTEGRATIONPOINTS=1`).*

### Element Connectivity (`*ELEMENT`)
Elements are instantiated with standard connectivity syntax:

```inp
*ELEMENT, TYPE=UB21, ELSET=<elset_name>
<elem_id>, <node1>, <node2>
```

### Element Capabilities
- **Nodes**: 2 nodes per element (Node 1, Node 2).
- **Degrees of Freedom (DOFs)**: 6 DOFs per node (`UX`, `UY`, `UZ`, `ROTX`, `ROTY`, `ROTZ`).
- **Kinematics**: Timoshenko shear deformation formulation with Euler-Bernoulli limiting behavior.
- **Section Orientations**: Defined via local direction vector $\mathbf{e}_2$ on the section card or `ORIENTATION` key definitions.
- **Section Rotations**: In-plane section rotation around the longitudinal beam axis via `ROTATION=<angle_deg>`.
- **Nodal Offsets**: 3D geometric offsets at Node 1 and Node 2 defined via `OFFSET=`, `OFFSET1=`, `OFFSET2=`.
- **Member End Releases (Hinges)**: Static condensation of rotational degrees of freedom (`M1`, `M2`, `T`, `M1-M2`, `ALLM`, or bitwise integer fixity).
- **Mass Matrices**: Consistent mass matrix formulation and optional lumped mass formulation (controlled by explicit dynamics or environment variable `CCX_LUMPED_MASS=1`).

---

## 3. Input Deck Syntax: `*USER BEAM SECTION`

To assign section properties, material, orientation, offsets, and hinges to UB21 elements, use the `*USER BEAM SECTION` keyword.

### Syntax Layout

```inp
*USER BEAM SECTION, ELSET=<elset_name>, MATERIAL=<mat_name>, SECTION=<RECT|CIRC|PIPE|I|T|CHAN|L|BOX> [, ORIENTATION=<ori_name>] [, ROTATION=<angle_deg>] [, RELEASE1=<code1>] [, RELEASE2=<code2>] [, OFFSET=(y,z)|OFFSET=(x,y,z)] [, OFFSET1=(x,y,z)] [, OFFSET2=(x,y,z)]
<dim_1>, <dim_2>, <dim_3>, <dim_4>, <dim_5>, <dim_6>
<e2_x>, <e2_y>, <e2_z>
```

### Parameter Explanations

1. **Keyword Line Parameters**:
   - `ELSET=<name>`: Name of the element set assigned to this section. (Required)
   - `MATERIAL=<name>`: Name of the material definition. (Required)
   - `SECTION=<type>`: Cross-section shape: `RECT`, `CIRC`, `PIPE`, `I`, `T`, `CHAN`, `L`, or `BOX`. (Required)
   - `ORIENTATION=<name>`: Optional user coordinate system orientation name.
   - `ROTATION=<angle>`: In-plane rotation angle (in degrees) around the beam longitudinal axis.
   - `RELEASE1=<code>`: Member end release code at Node 1 (`M1`, `M2`, `T`, `M1-M2`, `ALLM`, or custom bitmask integer `1..63`).
   - `RELEASE2=<code>`: Member end release code at Node 2 (`M1`, `M2`, `T`, `M1-M2`, `ALLM`, or custom bitmask integer `1..63`).
   - `OFFSET=(y, z)` or `OFFSET=(x, y, z)`: Local geometric offsets applied to all nodes of the element.
   - `OFFSET1=(x, y, z)`: Local geometric offset at Node 1.
   - `OFFSET2=(x, y, z)`: Local geometric offset at Node 2.

2. **Data Line 1 (Dimensions)**:
   - Up to 6 dimension values `<dim_1>, ..., <dim_6>` corresponding to the selected `SECTION` type (see Section 4).

3. **Data Line 2 (Orientation Normal / Direction Vector $\mathbf{e}_2$)**:
   - 3 real numbers `<e2_x>, <e2_y>, <e2_z>` defining the local transverse axis 2 (local $y$-direction) in global Cartesian coordinates (e.g. `0.0, 1.0, 0.0` or `0.0, 0.0, 1.0`).
   - *Must have non-zero length* ($\|\mathbf{e}_2\| > 0$).

> [!NOTE]
> Do **not** place nodal offsets on the second data line. Offsets are configured directly on the keyword header line using `OFFSET=`, `OFFSET1=`, `OFFSET2=`.

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

> [!TIP]
> For circular and pipe sections (`CIRC` and `PIPE`), the first parameter is the **outer radius $r_o$**, not the diameter.

> [!NOTE]
> **Asymmetric Sections (`CHAN`, `L`)**: UB21 automatically computes principal axes of inertia and principal rotation angles to prevent spurious shear-bending coupling.

---

## 5. Member End Releases (Hinges) & Custom Bitwise Fixity

Hinges can be defined independently at Node 1 (`RELEASE1=`) and Node 2 (`RELEASE2=`).

### Standard Mnemonic Release Shortcuts

| Release Code | Mnemonic Description | Released Degrees of Freedom | Base-10 Integer Value |
| :--- | :--- | :--- | :--- |
| **`T`** | Torsional release | Local $R_x$ released | **`8`** |
| **`M1`** | Bending hinge about local axis 1 ($y$) | Local $R_y$ released | **`16`** |
| **`M2`** | Bending hinge about local axis 2 ($z$) | Local $R_z$ released | **`32`** |
| **`M1-M2`** | Spherical bending hinge | Local $R_y, R_z$ released | **`48`** ($16 + 32$) |
| **`ALLM`** | Full ball joint / moment release | Local $R_x, R_y, R_z$ released | **`56`** ($8 + 16 + 32$) |

---

### Custom Member Fixity Setup (Bitwise / Base-10 Integer Encoding)

You can pass a custom integer directly to `RELEASE1=` or `RELEASE2=` (e.g. `RELEASE1=20`). The UB21 solver decodes the release value using a bitwise mask across the 6 local DOFs at each node:

$$\text{DOF Index (1..6)} = [u_x, u_y, u_z, r_x, r_y, r_z]$$

| Local DOF | Motion / DOF Name | Bit Position | Bit Weight (Base-10 Value) |
| :--- | :--- | :---: | :---: |
| **DOF 1** | Local Axial Displacement ($u_x$) | $2^0$ | **`1`** |
| **DOF 2** | Local Transverse Shear ($u_y$) | $2^1$ | **`2`** |
| **DOF 3** | Local Transverse Shear ($u_z$) | $2^2$ | **`4`** |
| **DOF 4** | Local Torsion ($r_x$) | $2^3$ | **`8`** |
| **DOF 5** | Local Bending Rotation ($r_y$) | $2^4$ | **`16`** |
| **DOF 6** | Local Bending Rotation ($r_z$) | $2^5$ | **`32`** |

#### Calculation Rule & Formula
To release any combination of local degrees of freedom at a node, sum the bit weights of the desired released DOFs:

$$\text{Release Value} = \sum \text{Bit Weight of Released DOFs}$$

#### Examples:
1. **Axial Release + Bending Hinge about $y$ (Sliding Expansion Joint)**:
   - Release $u_x$ (weight `1`) and $r_y$ (weight `16`).
   - $\text{RELEASE1} = 1 + 16 = 17$
   - Syntax: `*USER BEAM SECTION, ..., RELEASE1=17`

2. **Axial Shear Release ($u_x$ and $u_y$) + Torsion ($r_x$)**:
   - Release $u_x$ (weight `1`), $u_y$ (weight `2`), and $r_x$ (weight `8`).
   - $\text{RELEASE1} = 1 + 2 + 8 = 11$
   - Syntax: `*USER BEAM SECTION, ..., RELEASE1=11`

3. **Complete Free End / Disconnected Internal Hinge (All 6 DOFs released)**:
   - Release $u_x, u_y, u_z, r_x, r_y, r_z$.
   - $\text{RELEASE1} = 1 + 2 + 4 + 8 + 16 + 32 = 63$
   - Syntax: `*USER BEAM SECTION, ..., RELEASE1=63`

---

## 6. Supported Loading Types

UB21 supports both concentrated nodal loads (`*CLOAD`) and distributed element loads (`*DLOAD`).

### Concentrated Loads (`*CLOAD`)
Applied at nodes directly in global Cartesian components:
- `1..3`: Global Force components ($F_x, F_y, F_z$).
- `4..6`: Global Moment components ($M_x, M_y, M_z$).

### Distributed Loads (`*DLOAD`)

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

## 8. Output Variables & Post-Processing

Element outputs are written to the CCX `.dat`, `.frd` visualization files, and `ub21_beam_forces.csv`:

### 1. `.frd` File Outputs (for CGX Visualization)
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

### 2. Multi-Station CSV Output (`ub21_beam_forces.csv`)
For every step, `resultsmech_ub21.f` automatically writes 11 station evaluations ($x = 0\%, 10\%, 20\%, \dots, 100\%$) along the beam span to `ub21_beam_forces.csv`. This file records:
- `Axial_Fx`, `Shear_Vy`, `Shear_Vz`
- `Torsion_Tx`, `Bending_My`, `Bending_Mz`
- `Max_Stress` ($\sigma_{max}$)

---

## 9. Example Input Decks

### Sample 1: Cantilever Beam under Uniform & Tip Loading (`*STATIC`)

A 5.0m cantilever beam fixed at Node 1, modeled with 5 UB21 elements, subjected to self-weight, a uniform transverse load (`P1`), and a tip point load.

```inp
*HEADING
UB21 Cantilever Beam - Static Analysis with Uniform Transverse Load
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
*USER BEAM SECTION, ELSET=EBEAM, MATERIAL=STEEL, SECTION=RECT
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
U
*EL PRINT, ELSET=EBEAM
S
*END STEP
```

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

---

### Sample 3: 3D Frame Tower Module with Bracing Hinges (`*FREQUENCY`)

A 3D frame tower module where all columns and beams are modeled with UB21 elements, with diagonal cross-braces using pin-ended spherical releases (`RELEASE1=M1-M2, RELEASE2=M1-M2`), undergoing natural frequency extraction.

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
