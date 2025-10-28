# Unity Navigation Experiment

This folder contains the Unity project files for **Experiment 2** of the *PanoNavigation Project*, in which participants navigated a virtual city and performed spatial memory tasks.

---

## Overview
Participants explored a **virtual city environment** composed of multiple street blocks differing in layout alignment. During the **learning phase**, participants navigated freely following directional instructions; during the **test phase**, they completed **Judgment of Relative Direction (JRD)** tasks assessing their ability to construct global and local spatial reference frames.

---

## Folder Structure
- **`Navigation.unity`** — Main experiment scene containing the city environment and experiment logic.  
- **`ExpController.cs`** — Central script controlling overall experiment flow (learning → testing → data saving).  
- **`PlayerController.cs`** — Handles participant movement and camera rotation during navigation.  
- **`JRDResponseController.cs`** — Controls JRD task trials, question display, and response collection.  
- **`DataLogger.cs`** — Manages trial-level data recording and CSV export.  

---

## Usage
1. Open the project in **Unity (version ≥ 2021.3)**.  
2. Load the scene `Navigation.unity` under `/Scenes/`.  
3. Press ▶️ *Play* in the Unity Editor to start the experiment.  

*(Note: Stimulus assets and additional prefabs may not be included in this repository due to size limits. The provided scripts and scene structure are sufficient to replicate the experiment logic.)*

---

## Citation
If using or adapting this code, please cite:  
> He, Q. (2025). *PanoNavigation Project: Spatial Reference Frame Transformation and Virtual City Navigation.*
