# Pano & Navigation Experiment Code

This repository contains the **MATLAB** and **C# (Unity)** experiment code for the *PanoNavigation* project, which investigated how individuals utilize multi-level spatial cues to construct and shift between **global–local reference frames** during spatial navigation.  
The project includes three experiments: two panoramic tasks implemented with Psychtoolbox and PanoBasic toolbox in MATLAB, and one large-scale navigation task implemented with Unity.

---

## Overview

| Experiment | Folder | Platform | Description |
|-------------|---------|-----------|-------------|
| **Exp 1a — Regular Layout Panorama** | `PanoCross` | MATLAB | Participants explored cross-shaped panoramic intersections and performed Judgment of Relative Direction (JRD) tasks. |
| **Exp 1b — Irregular Layout Panorama** | `PanoIrr` | MATLAB | Similar design using irregular street layouts. |
| **Exp 2 — Virtual City Navigation** | `UnityNavigation` | Unity (C#) | Participants navigated a virtual city composed of multiple street blocks differing in layout alignment, then completed global and local JRD tasks. |

---

## Dependencies

### MATLAB Experiments (Exp 1a & 1b)
- **MATLAB R2024a**
- **Psychtoolbox 3.0.19**
- Typical runtime: ~25 min per experiment  

### Unity Experiment (Exp 2)
- **Unity 2022.3**
- **C# scripts**
- Typical runtime: ~100 min (60 min learn + 40 min test) per experiment  

---

## Data and Stimuli

Raw panoramic images and full 3D Unity assets are not included.  
Instead, `CrossPanoParameters.xlsx` & `IrregularPanoParameters.xlsx` provides parameter spreadsheets describing all stimulus configurations (street layout, location, URL, etc.). These files can be used to regenerate stimuli following `geneVideoFrame.m`.

---

*This code is shared for academic and educational purposes.*
