# Game Project – Onboarding README

Welcome! This document is a quick guide to help new contributors understand the project structure and how to run and explore the game.

---

## Running the Project

* **Run the project from the Main Menu**: Press **F5**

  * This launches the game starting from the main entry point.

* **Run a specific scene**: Open a scene from the file explorer in Godot and press **F6**

  * Useful for testing individual menus, levels, or systems without loading the full flow.

---

## File Organization Overview

All core development happens inside the `Source` directory. High‑level structure:

```
Source/
├─ Audio/
├─ Entities/
├─ Game Container/
├─ Levels/
├─ Menu/
├─ Resources/
└─ Scripts/
```


---

## Key Folders

### Game Container

**Path:**

```
Source → Game Container
```

This scene, game_container.tscn, acts as the **root container for the game**.

* Menus and levels are instanced under the Game Container
* It allows smooth transitions between menus and gameplay
* Keeps global systems centralized

Think of this as the "house" that everything else lives inside.

---

### Menus

**Path:**

```
Source → Menus
```

How menus work:

* Menus are instantiated under the **Game Container**
* When the player starts the game:

  * A level is loaded
  * The active menu is **freed** from the Game Container

This keeps menu logic separate from gameplay and avoids unnecessary scene overlap.

---

### Levels

**Path:**

```
Source → Levels
```

The primary level to look at (used for Pitch Night):

```
Source → Levels → test_level_parallax.tscn
```

This level demonstrates:

* General **boss fight layout**
* Scene composition standards
* Core gameplay components, including:

  * Player
  * Boss
  * Lock‑on system

Use this scene as the reference for how future levels should be structured.

---

## Core Gameplay Entities

### Player

**Path:**

```
Source → Entities → Player → better_player.tscn
```

Contains:

* Player movement and combat logic
* Input handling
* Player‑specific systems

---

### Tank Boss

**Path:**

```
Source → Entities → Bosses → TankBoss
```

The specific Tank Boss scene is tank_boss.tscn

Contains:

* Boss behavior and attacks
* State logic
* Visual and gameplay components specific to the Tank Boss

#### Shared Components

Several boss systems rely on reusable components located at:

```
Source → Entities → Components
```

These components are shared across entities to avoid duplicated logic and keep behaviors modular.

---

## Suggested First Steps for New Contributors

1. Run the project with **F5** to understand the full flow
2. Open and run `test_level_parallax.tscn` with **F6**
3. Explore:

   * `Game Container` scene
   * `better_player`
   * `TankBoss`
4. Review shared logic in `Entities → Components`

---

If you’re ever unsure where something belongs, use `test_level_parallax.tscn` as the canonical example for scene layout and composition.

---

## Godot 4.6 Basics: Scenes and Nodes (2D)

If you’re new to Godot, it’s important to understand how **Scenes** and **Nodes** work, since almost everything in this project is built on top of them.

### Nodes

* A **Node** is the smallest building block in Godot.
* Each node represents a single piece of functionality, such as:

  * A sprite (`Sprite2D`)
  * Collision (`CollisionShape2D`)
  * Logic (`Node`, `Node2D`, `CharacterBody2D`)
  * Cameras, audio players, timers, etc.
* Nodes are arranged in a **tree structure**, where child nodes inherit transforms and lifecycle behavior from their parents.

In this project, you’ll commonly see:

* `Node2D` – base node for 2D positioning
* `CharacterBody2D` – used for the player and enemies that move and collide
* `Area2D` – used for hitboxes, detection zones, and triggers

---

### Scenes

* A **Scene** is a collection of nodes saved together as a reusable unit (`.tscn`).
* Scenes can be:

  * Instanced inside other scenes
  * Nested multiple levels deep
  * Used like prefabs in other engines

Examples in this project:

* `game_container.tscn` – a high‑level scene that owns menus and levels
* `better_player.tscn` – a reusable player scene made of many child nodes
* `tank_boss.tscn` – a boss scene composed of visuals, hitboxes, and logic

A scene usually has:

* One **root node** (the top of the tree)
* Multiple child nodes that handle visuals, collisions, and behavior

---

### Scene Instancing

Instead of putting everything in one giant scene, Godot encourages **instancing**:

* Menus are instanced into the Game Container
* Levels are instanced when gameplay starts
* Players and bosses are instanced into levels

This keeps things modular, reusable, and easy to reason about.

---

### How This Project Uses Scenes and Nodes

* **Game Container** owns the high‑level flow (menus → levels)
* **Menus** are temporary scenes that get freed when gameplay starts
* **Levels** act as containers for gameplay entities
* **Entities** (player, bosses) are self‑contained scenes made of many nodes
* **Components** are reusable logic nodes that can be attached to multiple entities


---


