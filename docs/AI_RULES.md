# AI RULES

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