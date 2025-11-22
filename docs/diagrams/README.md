# Smart Navigation System - Diagrams

This folder contains all the diagrams used in the FYP report documentation.

## Generated Diagrams

### System Architecture
**File:** `System-Architecture.png`  
**Description:** Shows the three-tier architecture of the Smart Navigation System, including Presentation Layer (UI screens), Business Logic Layer (services), and Data Layer (models and Firebase).

### Navigation Flow
**File:** `Navigation-Flow.png`  
**Description:** Illustrates the user navigation flow between different screens in the application, showing how users move from login to various features.

### Beacon Trilateration
**File:** `Beacon-Trilateration.png`  
**Description:** Explains the indoor positioning algorithm using Bluetooth beacon triangulation, showing the process from beacon detection to position calculation.

### Sequence Diagram
**File:** `Sequence-Diagram.png`  
**Description:** Shows the interaction sequence between User, UI, Services, and Firebase for adding items and beacon navigation.

### Class Diagram
**File:** `Class-Diagram.png`  
**Description:** Displays the relationships between data models (UserModel, ProductModel, ShoppingListModel) and their properties.

### Data Flow
**File:** `Data-Flow.png`  
**Description:** Illustrates how data flows through the system from user actions through UI, services, and data storage.

## Existing Diagrams

### Database Structure
**File:** `Database Structure.png`  
**Description:** Shows the Firebase Firestore database structure with collections and document schemas.

### System Flow
**File:** `System Flow.drawio.png`  
**Description:** Overall system flow diagram created in Draw.io showing the complete user journey.

## Source Files

The `.mmd` files are Mermaid diagram source files that can be edited and regenerated if needed.

### How to Regenerate Diagrams

If you need to modify and regenerate any diagram:

1. Edit the corresponding `.mmd` file
2. Run the following command:
   ```bash
   mmdc -i <diagram-name>.mmd -o <Diagram-Name>.png -b transparent
   ```

Or use the online editor at https://mermaid.live/

### Tools Used

- **Mermaid CLI** - For generating PNG images from Mermaid syntax
- **Draw.io** - For manually created diagrams
- **Mermaid Live Editor** - https://mermaid.live/ (alternative tool)

## Usage in Report

These diagrams are referenced in:
- **Chapter 3:** Methodology - System design diagrams
- **Chapter 4:** System Implementation - Architecture and class diagrams
- **Chapter 5:** Testing - Sequence and flow diagrams

---

*Generated for FYP2 - Smart Navigation System Report*




