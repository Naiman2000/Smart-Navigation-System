# Diagram References for FYP2 Report

This document provides references for all diagrams to be included in the report chapters.

## Chapter 3: Methodology

### Figure 3.1: Database Structure
**File:** `../diagrams/Database Structure.png`  
**Caption:** Firebase Firestore database structure showing Users, Products, Shopping Lists, Beacons, and Routes collections.

### Figure 3.2: System Flow
**File:** `../diagrams/System Flow.drawio.png`  
**Caption:** Overall system flow diagram illustrating the complete user journey from login to navigation.

## Chapter 4: System Implementation

### Figure 4.1: System Architecture (Three-Tier)
**File:** `../diagrams/System-Architecture.png`  
**Caption:** Three-tier architecture of the Smart Navigation System showing Presentation Layer (UI screens), Business Logic Layer (services including Firebase Service, Beacon Service, Navigation Service), and Data Layer (models and Firebase backend).

**Where to use:** Section 4.3 - System Architecture

---

### Figure 4.2: Navigation Flow Diagram
**File:** `../diagrams/Navigation-Flow.png`  
**Caption:** Application navigation flow showing user journey between screens and key interactions from login to navigation features.

**Where to use:** Section 4.5 - User Interface Implementation

---

### Figure 4.3: Class Diagram - Data Models
**File:** `../diagrams/Class-Diagram.png`  
**Caption:** UML class diagram showing data models and their relationships: UserModel, ProductModel, ShoppingListModel, and their associated classes with properties and methods.

**Where to use:** Section 4.4 - Database Implementation

---

### Figure 4.4: Beacon Trilateration Process
**File:** `../diagrams/Beacon-Trilateration.png`  
**Caption:** Indoor positioning algorithm flowchart showing the process of beacon detection, RSSI measurement, distance calculation, and position triangulation using trilateration.

**Where to use:** Section 4.7.3 - Indoor Navigation

---

### Figure 4.5: Data Flow Diagram
**File:** `../diagrams/Data-Flow.png`  
**Caption:** Data flow diagram showing how information moves through the system layers from user actions through UI components, services, and data storage.

**Where to use:** Section 4.3 - System Architecture

---

### Figure 4.6: Component Interaction Sequence
**File:** `../diagrams/Sequence-Diagram.png`  
**Caption:** Sequence diagram illustrating the interaction between User, UI Screen, Services, and Firebase for two key operations: adding items to shopping list and beacon-based navigation.

**Where to use:** Section 4.8 - Code Snippets and Explanations

## How to Insert in Word Document

For Microsoft Word:
1. Go to the section where you want to insert the diagram
2. Click **Insert > Pictures > This Device**
3. Navigate to the diagram file
4. Insert the image
5. Right-click image > Insert Caption
6. Add caption text from this document
7. Use "Figure" as label and check "Exclude label from caption" if needed

For LaTeX:
```latex
\begin{figure}[h]
    \centering
    \includegraphics[width=0.8\textwidth]{../diagrams/System-Architecture.png}
    \caption{Three-tier architecture of the Smart Navigation System}
    \label{fig:system-architecture}
\end{figure}
```

## Diagram Dimensions

All diagrams are generated with transparent backgrounds and can be resized as needed. Recommended widths:
- Full page width: 6.5 inches
- Half page: 3.25 inches
- Three-quarter page: 5 inches

## Color Scheme

The diagrams use a consistent color scheme:
- **Blue tones** - Presentation/UI Layer
- **Yellow tones** - Business Logic/Services
- **Green tones** - Data Layer/Models
- **Specific colors** - Used for flow and emphasis

---

## Quick Reference Table

| Figure | File Name | Chapter | Section | Size |
|--------|-----------|---------|---------|------|
| 3.1 | Database Structure.png | 3 | 3.4 | Full |
| 3.2 | System Flow.drawio.png | 3 | 3.4 | Full |
| 4.1 | System-Architecture.png | 4 | 4.3 | Full |
| 4.2 | Navigation-Flow.png | 4 | 4.5 | Full |
| 4.3 | Class-Diagram.png | 4 | 4.4 | 3/4 |
| 4.4 | Beacon-Trilateration.png | 4 | 4.7.3 | 3/4 |
| 4.5 | Data-Flow.png | 4 | 4.3 | Full |
| 4.6 | Sequence-Diagram.png | 4 | 4.8 | Full |

---

*Last Updated: [Current Date]*  
*Total Diagrams: 8*




