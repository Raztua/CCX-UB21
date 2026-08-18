# CalculiX CCX 2.23 — UB21 Beam Element & User Sections Extension

[![CalculiX](https://img.shields.io/badge/CalculiX-CCX%202.23-blue.svg)](http://www.calculix.de/)
[![Element](https://img.shields.io/badge/Element-UB21-green.svg)]()
[![Kinematics](https://img.shields.io/badge/Formulation-Timoshenko%20%2F%20Euler--Bernoulli-orange.svg)]()
[![Validation](https://img.shields.io/badge/Validation-100%25%20Verified-brightgreen.svg)]()
[![License](https://img.shields.io/badge/License-GPL%20v2-lightgrey.svg)](CalculiX/ccx_2.23/src/gpl.htm)

A native extension and patch for **CalculiX CCX 2.23** adding the **UB21 (2-node 3D Timoshenko / Euler-Bernoulli user beam element)** and **User Beam Sections** system.

This implementation provides high-accuracy 3D beam modeling with complete rotational coupling, 8 cross-section shapes, member end releases (hinges), 3D geometric nodal offsets, rich distributed load distributions, mass formulation choices, and enhanced post-processing in **CalculiX GraphiX (CGX)**.

---

## 📑 Table of Contents
- [Key Features](#-key-features)
- [Repository Structure](#-repository-structure)
- [Installation Guide](#-installation-guide)
  - [Automated 1-Command Installation](#option-1-automated-1-command-installation-recommended)
  - [Manual Installation (Linux / macOS)](#option-2-manual-installation-linux--macos)
  - [Windows Installation (WSL / Git Bash / MSYS2)](#option-3-windows-installation)
- [Quickstart Example Deck](#-quickstart-example-deck)
- [Input Syntax & Usage](#-input-syntax--usage)
  - [1. User Element Declaration (`*USER ELEMENT`)](#1-user-element-declaration-user-element)
  - [2. User Beam Section (`*USER BEAM SECTION`)](#2-user-beam-section-user-beam-section)
  - [3. Raw Property Vector (`*USER SECTION, CONSTANTS=19`)](#3-raw-property-vector-user-section-constants19)
  - [4. Cross-Section Types & Parameters](#4-cross-section-types--parameters)
  - [5. Member End Releases (Hinges)](#5-member-end-releases-hinges)
  - [6. Distributed Loading Library (`*DLOAD`)](#6-distributed-loading-library-dload)
  - [7. Dynamic Multi-Station Beam CSV Output (`*USER BEAM OUTPUT`)](#7-dynamic-multi-station-beam-csv-output-user-beam-output)
  - [8. `UCONN6` Connectors & ASCE 41-17 Plastic Hinge Output (`*USER CONNECTOR OUTPUT`)](#8-uconn6-connectors--asce-41-17-plastic-hinge-output-user-connector-output)
- [Analysis Capabilities](#-analysis-capabilities)
- [Post-Processing & CGX Visualization](#-post-processing--cgx-visualization)
- [Validation & Verification](#-validation--verification)
- [Documentation Reference](#-documentation-reference)
- [License](#-license)

---

## 🚀 Key Features

- **Element Formulation**: 2-node 3D beam element (`UB21`) with 6 DOFs per node (`UX`, `UY`, `UZ`, `ROTX`, `ROTY`, `ROTZ`).
- **Timoshenko Shear & Limiting Euler-Bernoulli Kinematics**: Exact shear coefficients computed automatically based on cross-section geometry and Poisson's ratio $\nu$.
- **8 Cross-Section Profiles**: `RECT`, `CIRC`, `PIPE`, `I`, `T`, `CHAN` (U-channel), `L` (Angle), and `BOX` (Hollow Box).
- **Asymmetric Section Handling**: Automatic determination of principal inertia axes ($I_{yy}$, $I_{zz}$) and principal rotation angle $\theta_p$ for `L` and `CHAN` sections to eliminate spurious bending-shear coupling.
- **Member End Releases (Hinges)**: Static condensation of rotational degrees of freedom at Node 1 and Node 2 (`ALLM`, `M1-M2`, `M1`, `M2`, `T`) or full 6-DOF bitwise fixity masks (`1..63`).
- **3D Geometric Nodal Offsets**: Eccentric neutral-axis shifts at element ends via `OFFSET=`, `OFFSET1=`, `OFFSET2=`.
- **Comprehensive Distributed Loading**: Uniform, triangular, trapezoidal, and partial patch transverse loads (`PX`, `P1`, `P2`, `P1_T1`, `P1_T2`, `P2_T1`, `P2_T2`, `P1_P_aa_bb`, `P2_P_aa_bb`), plus `CENTRIF` and `GRAV`.
- **Dynamic Mass Options**: Consistent mass matrix and optional lumped mass formulation (controlled by explicit dynamics or `CCX_LUMPED_MASS=1`).
- **Advanced Post-Processing**:
  - Automatically expands each UB21 element into 10 line sub-elements in the `.frd` file for smooth continuous stress and internal force contour visualization in CGX.
  - Generates 11-station internal force/stress evaluations per step in `ub21_beam_forces.csv`.

---

## 📁 Repository Structure

```text
CCX-CB/
├── CalculiX/                     # CalculiX CCX 2.23 source tree with SPOOLES & ARPACK
│   └── ccx_2.23/src/             # CCX core routines and patched Fortran/C modules
├── cgx_2.23.all/                 # CalculiX GraphiX (CGX 2.23) source tree
├── ub21_source_files/            # Pure Fortran modules for the UB21 patch
├── ub21_ccx223.patch             # Unified diff patch for a clean CCX 2.23 tree
├── install_ub21.sh               # Automated installer & compiler script
├── run_tests.py                  # Unified master test runner CLI
├── UB21_CCX223_Manual.md         # Comprehensive User Manual, Theory & Deck Reference
├── CGX_UB21_Guide.md             # CGX Visualization & Post-Processing Guide
├── README.md                     # Project README
└── tests/                        # Organized verification, validation & benchmark suites
    ├── 01_static_linear/         # Linear static, member releases & semi-rigid springs
    ├── 02_modal_eigenfrequency/  # Free vibration modal & natural frequency benchmarks
    ├── 03_geometric_nonlinear_pdelta/# Second-order P-Delta & geometric nonlinearity
    ├── 04_pushover_and_plasticity/# Inelastic pushover (ASCE 41-17, MDPI CBF, PyNite)
    ├── 05_full_verification_and_qa/# 10-Batch analytical verification & ground truth QA
    ├── 06_demos/                 # Mixed-dimensional demo models
    ├── reports/                  # Markdown verification reports
    └── run_all_tests.py          # Master test harness
```

---

## 🛠 Installation Guide

### Option 1: Automated 1-Command Installation (Recommended)

1. Make `install_ub21.sh` executable:
   ```bash
   chmod +x install_ub21.sh
   ```
2. Execute the script targeting your CCX source tree:
   ```bash
   ./install_ub21.sh CalculiX/ccx_2.23/src
   ```
   The script automatically detects directory depth, applies `ub21_ccx223.patch`, builds with `make -j$(nproc)`, and verifies the generated `ccx_2.23` binary.

---

### Option 2: Manual Installation (Linux / macOS)

From the root of a clean CalculiX 2.23 source tree:

```bash
# 1. Apply the patch
patch -p1 < ub21_ccx223.patch

# 2. Compile CCX binary
cd CalculiX/ccx_2.23/src
make -j$(nproc)
```

---

### Option 3: Windows Installation

- **WSL (Ubuntu / Debian - Recommended)**:
  ```bash
  sudo apt update && sudo apt install build-essential patch gfortran liblapack-dev libspooles-dev
  ./install_ub21.sh /mnt/c/path/to/ccx_2.23/src
  ```
- **Git Bash (Windows Native)**:
  ```bash
  patch -p1 < ub21_ccx223.patch
  ```
- **MSYS2 / MinGW-w64**:
  ```bash
  pacman -S patch make mingw-w64-x86_64-gfortran mingw-w64-x86_64-gcc
  cd CalculiX/ccx_2.23/src && make -f Makefile
  ```

---

## ⚡ Quickstart Example Deck

Create a file `cantilever.inp`:

```inp
*HEADING
UB21 Cantilever Beam - Static Point & Uniform Load
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
U, RF
*EL PRINT, ELSET=EBEAM
S
*END STEP
```

Run with CCX:
```bash
ccx_2.23 cantilever
```

---

## 📖 Input Syntax & Usage

### 1. User Element Declaration (`*USER ELEMENT`)
Before defining any UB21 elements, declare the user element type:
```inp
*USER ELEMENT, TYPE=UB21, NODES=2, MAXDOF=6, INTEGRATIONPOINTS=1
```

---

### 2. User Beam Section (`*USER BEAM SECTION`)
High-level keyword for assigning geometry, orientation, releases, and offsets:

```inp
*USER BEAM SECTION, ELSET=<elset>, MATERIAL=<mat>, SECTION=<shape> [, ORIENTATION=<ori>] [, ROTATION=<deg>] [, RELEASE1=<code>] [, RELEASE2=<code>] [, OFFSET1=(x,y,z)] [, OFFSET2=(x,y,z)]
<dim_1>, <dim_2>, <dim_3>, <dim_4>, <dim_5>, <dim_6>
<e2_x>, <e2_y>, <e2_z>
```
- **Data Line 1**: Cross-section dimensions (`dims(1..6)`).
- **Data Line 2**: Local orientation normal vector $\mathbf{e}_2$ (local transverse $y$-direction, e.g. `0.0, 1.0, 0.0`).
- **Nodal Offsets**: Configured on the keyword line via `OFFSET=`, `OFFSET1=`, `OFFSET2=`.

---

### 3. Raw Property Vector (`*USER SECTION, CONSTANTS=19`)
Generic CalculiX property array format where all 19 constant slots are passed across data lines:

```inp
*USER SECTION, ELSET=BEAM, MATERIAL=STEEL, CONSTANTS=19
1, 0.1, 0.2, 0.0, 0.0, 0.0, 0.0, 0.0,
0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
0, 0,
0.0, 1.0, 0.0
```
- **Line 1 (Slots 1..8)**: `sect_type, dim1..dim6, rot_angle`
- **Line 2 (Slots 9..14)**: `off_x1, off_y1, off_z1, off_x2, off_y2, off_z2`
- **Line 3 (Slots 15..16)**: `rel_1, rel_2` (Bitmask integers)
- **Line 4 (Slots 17..19)**: `e2_x, e2_y, e2_z` (Orientation normal vector)

---

### 4. Cross-Section Types & Parameters

| Section Code (`SECTION=`) | Parameter List | Parameter Description |
| :--- | :--- | :--- |
| **`RECT`** | `b, h` | Width `b` (local $y$), Height `h` (local $z$) |
| **`CIRC`** | `r_o` | Outer radius $r_o$ (or `r_o, 0.0`) |
| **`PIPE`** | `r_o, t` | Outer radius $r_o$, Wall thickness $t$ |
| **`I`** | `h, b_top, t_f1, b_bot, t_f2, t_w` | Total height $h$, Top flange width/thickness, Bottom flange width/thickness, Web thickness |
| **`T`** | `h, b, t_f, t_w` | Total height $h$, Flange width $b$, Flange thickness $t_f$, Web thickness $t_w$ |
| **`CHAN`** (U-channel) | `h, b, t_f, t_w` | Channel height $h$, Flange width $b$, Flange thickness $t_f$, Web thickness $t_w$ |
| **`L`** (Angle) | `b, h, t` | Horizontal leg width $b$, Vertical leg height $h$, Thickness $t$ |
| **`BOX`** (Hollow Box) | `h, b, t_bot, t_left, t_top, t_right` | Total height $h$, Width $b$, Flange and web thicknesses (or `h, b, t, t, t, t`) |

---

### 5. Member End Releases (Hinges)

Hinges can be defined using mnemonic string shortcuts or bitwise integers:

| Mnemonic Code | Description | Released DOFs | Bit Value |
| :--- | :--- | :---: | :---: |
| **`ALLM`** | **Full Moment / Ball-Joint + Torsion** | Local $R_x, R_y, R_z$ | **`56`** |
| **`M1-M2`** | **Spherical Bending Hinge** (pins both bending axes) | Local $R_y, R_z$ | **`48`** |
| **`M1`** | **Planar Bending Hinge about axis 1** ($y$) | Local $R_y$ | **`16`** |
| **`M2`** | **Planar Bending Hinge about axis 2** ($z$) | Local $R_z$ | **`32`** |
| **`T`** | **Torsional Pin** | Local $R_x$ | **`8`** |
| *Custom Integer* | *Sum of bit weights ($u_x=1, u_y=2, u_z=4, r_x=8, r_y=16, r_z=32$)* | Custom | `1..63` |

---

### 6. Distributed Loading Library (`*DLOAD`)

| Label | Description |
| :--- | :--- |
| **`PX`** | Uniform axial force per unit length along element axis. |
| **`P1`** | Uniform transverse load per unit length along local $y$. |
| **`P2`** | Uniform transverse load per unit length along local $z$. |
| **`P1_T1` / `P1_T2`** | Triangular load along local $y$ (increasing Node 1 $\rightarrow$ 2 / decreasing Node 1 $\rightarrow$ 2). |
| **`P2_T1` / `P2_T2`** | Triangular load along local $z$ (increasing Node 1 $\rightarrow$ 2 / decreasing Node 1 $\rightarrow$ 2). |
| **`P1_P_aa_bb`** | Partial patch load along local $y$ starting at `aa`% and ending at `bb`% of length. |
| **`P2_P_aa_bb`** | Partial patch load along local $z$ starting at `aa`% and ending at `bb`% of length. |
| **`CENTRIF`** | Centrifugal load field with rotational velocity $\omega$ and axis. |
| **`GRAV`** | Gravity/body accelerational force computed from material density $\rho$ and area $A$. |

---

### 7. Dynamic Multi-Station Beam CSV Output (`*USER BEAM OUTPUT`)

Zero-RAM, high-performance streaming of internal beam results along member spans directly to CSV:

```inp
*USER BEAM OUTPUT, FILE=girders.csv, ELSET=EGIRDERS, SUBDIVISIONS=10, INCREMENT=LAST
F, U, S
```

#### Parameters:
- **`FILE=`**: Destination filename (e.g. `girders.csv`) or tuple list `FILE=(f1.csv, f2.csv)` mapped 1-to-1 with `ELSET=(...)`.
- **`ELSET=`**: Target element set(s) (e.g. `EBEAM`, `ELSET=(COLS, GIRDERS)`, `ELSET=ALL`, or `ELSET=*`).
- **`SUBDIVISIONS=N`**: Number of internal span evaluation stations per member ($N=1..100+$). Evaluates exact Hermite shape functions + closed-form particular sag $v_0(x), w_0(x)$ under distributed line loads.
- **`INCREMENT=`**: Output step filter (`LAST`, `ALL`, `FREQ=k`, or list `(1, 5, 10)`).
- **`COORDINATES=`**: Coordinate transformation system (`LOCAL` or `GLOBAL`).

#### Column Variable Selectors:
- **`F`**: Internal forces & moments (`Fx_Axial, Vy_Shear, Vz_Shear, Mx_Torsion, My_Bending, Mz_Bending`).
- **`U`**: 3D Displacements and cross-section rotations (`Ux, Uy, Uz, Rot_X, Rot_Y, Rot_Z`).
- **`S`**: Longitudinal and shear stresses (`Sxx_Axial, Sxx_Bending_Y, Sxx_Bending_Z, Sxx_Max_Combined, Sxy_Shear, Sxz_Shear, Stors_Torsion`).
- **`Q`**: Applied line load values (`Qx_Load, Qy_Load, Qz_Load`).
- **`ALL`**: All 26 standard columns.

#### Generated CSV Format:
```csv
Step,Increment,Time,Element,Station_Pct,X_local,Fx_Axial,Vy_Shear,Vz_Shear,Mx_Torsion,My_Bending,Mz_Bending,Ux,Uy,Uz,Rot_X,Rot_Y,Rot_Z,...
```

---

### 8. `UCONN6` Connectors & ASCE 41-17 Plastic Hinge Output (`*USER CONNECTOR OUTPUT`)

6-DOF zero-length connector element (`UCONN6`) for discrete joint springs, member end releases, and nonlinear ASCE 41-17 plastic hinges:

#### A. Connector Definition (`*USER CONNECTOR`)
```inp
*USER ELEMENT, TYPE=UCONN6, NODES=2, MAXDOF=6, INTEGRATIONPOINTS=1
*ELEMENT, TYPE=UCONN6, ELSET=EHINGE
10, 1, 101

** Linear 6-DOF elastic spring:
*USER CONNECTOR, ELSET=EHINGE
K_ux, K_uy, K_uz, K_rx, K_ry, K_rz

** Nonlinear ASCE 41-17 plastic hinge:
*USER CONNECTOR, ELSET=EHINGE, NONLINEAR=ASCE41
K_ux, K_uy, K_uz, K_rx, 0.0, K_rz
My, theta_y, theta_cap, c_res, theta_u, theta_fail, alpha_hard, dof_idx
```

#### B. Connector Output Card (`*USER CONNECTOR OUTPUT`)
```inp
*USER CONNECTOR OUTPUT, FILE=hinges.csv, ELSET=EHINGE
F, U, STATE
```
- **`F`**: Connector forces & moments (`Fx, Fy, Fz, Mx, My, Mz`).
- **`U`**: Relative joint deformations (`dUx, dUy, dUz, dRotX, dRotY, dRotZ`).
- **`STATE`** / **`ASCE41`**: Damage state (`Elastic`, `IO`, `LS`, `CP`, `Failure`), `Yield_Ratio`, `Plastic_Def`, and `Tangent_K`.
- **`ALL`**: All connector columns.

#### Generated CSV Format:
```csv
Step,Increment,Time,Element,Node1,Node2,Fx,Fy,Fz,Mx,My,Mz,dUx,dUy,dUz,dRotX,dRotY,dRotZ,ASCE41_State,Yield_Ratio,Plastic_Def,Tangent_K
```

---

## 🔬 Analysis Capabilities

The UB21 and UCONN6 extensions support all standard CCX step procedures:
- **`*STATIC`**: Linear static displacement, reaction, and stress analysis.
- **`*FREQUENCY`**: Natural frequency extraction and mode shape calculation with consistent or lumped mass.
- **`*BUCKLE`**: Linear critical eigenvalue buckling factor estimation using exact geometric stiffness matrices.
- **`*DYNAMIC` / `*MODAL DYNAMIC`**: Direct integration or modal time-history dynamic simulations.

---

## 📊 Post-Processing & CGX Visualization

Visualizing results in **CalculiX GraphiX (CGX)**:

```bash
cgx cantilever.frd
```

### Essential CGX Commands
```cgx
read cantilever.frd      # Load result deck
view elem                # Show element boundaries
plot elem                # Render element mesh

# Displacements & Mode Shapes
ds 1 e 2                 # Select Dataset 1, Component 2 (UY)
ds 1 e 4                 # Select Total Magnitude (ALL)
plot f                   # Plot color contours
view disp                # Toggle deformed view
scal d 50                # Scale deformation display 50x

# Stresses & Internal Forces
ds 2 e 1                 # SXX (Max Normal Stress / Axial)
ds 2 e 2                 # SYY (Bending Moment My)
ds 2 e 3                 # SZZ (Bending Moment Mz)
plot f                   # Render contours
```

For complete step-by-step CGX batch scripting and dataset queries, see [`CGX_UB21_Guide.md`](CGX_UB21_Guide.md).

---

## ✅ Validation & Verification

The patch includes 15 automated validation suites verifying the implementation against theoretical analytical solutions (Timoshenko & Euler-Bernoulli beam theory) and Nastran 95 baselines:

### 1. Running the Verification Suites
```bash
# Run fast smoke tests across all categories (15 test suites)
python3 run_tests.py

# Run full multi-section verification across all shapes (RECT, BOX, CIRC, PIPE, L, I, T)
python3 run_tests.py --suite verif

# Run unit tests and member end releases
python3 run_tests.py --suite unit

# Run nonlinear pushover and frame benchmarks
python3 run_tests.py --suite pushover

# Run all test suites
python3 run_tests.py --all
```

### 2. Validation Results Summary
- **Static Deflection & Reactions**: **`0.000%` error** against exact Timoshenko closed-form solutions.
- **Dynamic Station Displacements**: Exact match with Euler-Bernoulli particular sag ($v_{\text{mid}} = \frac{5 w L^4}{384 E I}$).
- **Eigenfrequency Modal Analysis**: **`< 0.05%` error** against analytical beam natural frequencies.
- **Eigenvalue Buckling Analysis**: Exact match on multi-span frames and column stability limits.
- **15 / 15 Test Suites Passed (100% success)** across static, modal, P-Delta, ASCE 41-17 pushover, and QA verification suites.

Detailed benchmarks, pass/fail status breakdowns, and comparison tables are available in:
- **[`tests/reports/ANALYSIS_STATUS_SUMMARY.md`](tests/reports/ANALYSIS_STATUS_SUMMARY.md)**: Pass/Fail/Review/NA metrics and physical explanations across all analysis categories.
- **[`tests/reports/MASTER_RESULTS_SUMMARY.md`](tests/reports/MASTER_RESULTS_SUMMARY.md)**: Master quantitative comparison table across all 7 physical quantities, 5 analysis types, and reference baselines.
- **[`tests/reports/global_verification_report.md`](tests/reports/global_verification_report.md)**: Multi-section 10-batch analytical verification report across all 8 shapes.
- **[`tests/reports/validation_report.md`](tests/reports/validation_report.md)**: Static, modal, transient dynamic, and Nastran 95 validation report.
- **[`tests/reports/qa_quality_report.md`](tests/reports/qa_quality_report.md)**: QA robustness, equilibrium, energy conservation, and mechanism report.

---

## 📚 Documentation Reference

- **[`UB21_CCX223_Manual.md`](UB21_CCX223_Manual.md)**: Full technical reference manual, mathematical derivations, cross-section formulations, and verified example decks.
- **[`CGX_UB21_Guide.md`](CGX_UB21_Guide.md)**: Complete guide for post-processing and rendering UB21 results in CGX.
- **[`tests/README.md`](tests/README.md)**: Comprehensive test suite documentation, category organization, and execution guide.
- **[`tests/reports/ANALYSIS_STATUS_SUMMARY.md`](tests/reports/ANALYSIS_STATUS_SUMMARY.md)**: Comprehensive status metrics (Pass / Review / Fail / NA) breakdown by analysis type.
- **[`tests/reports/MASTER_RESULTS_SUMMARY.md`](tests/reports/MASTER_RESULTS_SUMMARY.md)**: Quantitative comparison tables vs Nastran 95, OpenSees, PyNite, LUSAS, and analytical theory.

---

## 📄 License

CalculiX is distributed under the terms of the **GNU General Public License (GPL v2)**. See the `CalculiX/ccx_2.23/src/gpl.htm` file for license details.
