# GODOT PROJECT RULES

## Engine
Godot 4.6 stable

## Language
Use GDScript only.

## Important
Use ONLY Godot 4.6 syntax.
Never generate Godot 3 code.

## Coding Style
- Use snake_case for variables and functions
- Use PascalCase for class names
- Use tabs for indentation
- Keep scripts modular and reusable

## Architecture
- Prefer composition over inheritance
- Use signals for node communication
- Avoid unnecessary singleton usage

## Scene Rules
- Use CharacterBody2D for player and enemies
- Use exported variables for balancing and tuning

## Performance
- Avoid expensive operations in _process()
- Cache references when possible

## Project Structure
- scenes/
- scripts/
- assets/
- ui/