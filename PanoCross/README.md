# PanoCross Experiment

## Overview
This folder contains the code and parameter files for **Experiment 1a (Regular Layout Panorama)** in the PanoNavigation project.  
In this condition, participants explored **cross-shaped street intersections** and later performed **Judgment of Relative Direction (JRD)** tasks to assess heading representations.

---

## Stimuli
The original panoramic images were not uploaded.  
Instead, the accompanying `PanoCross_Parameters.xlsx` provides detailed metadata for all **60 panoramic street scenes**, including:  
- `NorthRotation` — the rotation (in degrees) of the true north within each panorama.  
- `RoadRotation1_N` and `RoadRotation2_N` — the angular directions of the two main roads relative to north.  
- `URL` — the link to the corresponding Google Street View panorama.  
These parameters allow others to **reconstruct or re-download** the original stimuli if needed.

Panoramic images were preprocessed into 360 square frames using the script `geneVideoFrame.m`.  
**Frame 1** always aligned with the road closest to north.  
Frame extraction used the [**PanoBasic Toolbox**](https://github.com/yindaz/PanoBasic).

---

## Experiment Design
Each participant completed **20 trials**, each consisting of two phases:

1. **Learning Phase (60 s)** — Participants freely explored a panorama using **keyboard arrow keys** to rotate their view.  
2. **Test Phase (JRD)** — Participants completed a **Judgment of Relative Direction** task with no time limit.

At the start of each trial, participants were **instructed to face north**.  
The **alignment angle** (difference between true north and the nearest road) was randomly selected from the range **[-44°, +45°]**.  
Each participant’s 20 panoramas were randomly sampled from the 60 scene database, balancing other visual features.

---

## Code Structure
| File | Description |
|------|--------------|
| `geneVideoFrame.m` | Converts panoramic images into 360 square view frames. |
| `A0main_PanoExp.m` | Main script. |
| `PanoCross_Parameters.xlsx` | Metadata for all panoramas (orientation, layout angles, and URLs). |

---

## Dependencies
- **MATLAB**   
- **Psychtoolbox**  
- **[PanoBasic Toolbox](https://github.com/yindaz/PanoBasic)** (for frame extraction)

---
