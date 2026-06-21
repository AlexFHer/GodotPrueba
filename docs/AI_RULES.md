# AI RULES

## Project Context
- This project belongs to Potma.
- Treat Potma as a Godot 4.6 project.
- Always prefer the newest stable Godot 4.6 APIs and patterns available for this project.
- Use GDScript as the scripting language for gameplay, tools, and editor scripts unless the user explicitly requests otherwise.
- When choosing between older examples and newer Godot 4.6 approaches, follow the Godot 4.6 approach.

## Game Concept
- Potma is a 3D collectathon inspired by classic adventure platformers like Spyro.
- The game is set in a magical world where the main character is a wizard who cannot naturally cast magic.
- To use magic, the wizard must drink potions that temporarily grant magical abilities.
- This potion-based magic limitation should guide gameplay ideas, collectibles, progression, level design, and player abilities.
- The tone should support a colorful, whimsical, exploration-focused adventure with clear collectible goals and playful magical mechanics.

## General Rules
- Always use Godot 4.6 syntax
- Never use Godot 3 APIs
- Use GDScript only

---

## Code Generation Rules
- Prefer modular code
- Prefer reusable scenes
- Keep scripts small and maintainable
- Avoid overengineering
- Avoid unnecessary abstractions

---

## Editing Rules
- Do not rewrite entire files unnecessarily
- Modify only the requested parts
- Preserve existing architecture
- Preserve variable names unless necessary

---

## Performance Rules
- Avoid expensive operations in _process()
- Cache node references when possible
- Avoid unnecessary object creation

---

## Communication Rules
- Explain why changes are needed
- Mention possible side effects
- Suggest improvements when relevant

---

## Godot Architecture Rules
- Prefer signals over tight coupling
- Prefer composition over inheritance
- Avoid singleton abuse
- Use Resources for reusable data

---

## Scene Rules
- Keep scenes focused on one responsibility
- Avoid giant scene hierarchies
- Use exported variables for tuning

---

## UI Rules
- Separate UI logic from gameplay logic
- Avoid hardcoded references
- Use containers when possible

---

## Important
If unsure, prioritize readability and maintainability.
