# Unity Navigation Experiment

## Overview
This folder contains the scene and script files for **Experiment 2 (Virtual City Navigation)** in the *PanoNavigation* Project.  
In this experiment, participants navigated through a **virtual city composed of three street blocks** with road orientations of **0°, 22.5°, and 45°** relative to true north.  

---

## Virtual Environment
The Unity scene (`/Scenes/Navigation.unity`) includes a virtual city with three distinct **street blocks**, each differing in overall alignment to north.  
From this environment, **9 intersections** (3 per block) were randomly selected as **targets** that participants needed to learn and later recall.

During navigation, participants encoded two types of spatial information:  
- **Inter-location relations** — spatial positions among the 9 target intersections.  
- **Intra-location orientations** — view-based layouts within each intersection.  
These corresponded to **two JRD tasks** administered later in the experiment.

---

## Experiment Design
Each participant completed **six learning rounds** followed by **JRD testing**:

1. **Learning Phase** — In each round, participants navigated the city following on-screen cues to visit all 9 target intersections (order randomized). Upon arrival, they freely rotated their view to memorize the intersection layout.  
2. **Test Phase** — Participants performed **54 JRD trials**, each trial consists of:  
   - **Inter-JRD:** judgments between different intersections.  
   - **Intra-JRD:** judgments within the intersection.

---

## Code Structure
| File | Description |
|------|--------------|
| `Navigation.unity` | Main Unity scene containing the city environment and experiment setup. |
| `ExpController.cs` | Controls experiment flow (learning, testing, data saving). |
| `PlayerController.cs` | Handles player movement and camera rotation during navigation. |
| `JRDResponseController.cs` | Manages the JRD test phase, question display, and response collection. |
| `DataLogger.cs` | Records data and exports CSV files. |

---

## Dependencies
- **Unity**  
- **C#**  

---

*Note: Some prefabs and environment assets are not included.*
