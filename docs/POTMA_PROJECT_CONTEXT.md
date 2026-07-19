# Potma Project Context

This is the living project memory for Potma. Read this file before making design,
code, gameplay, or content decisions in this repository. Keep it updated whenever
a new decision, mechanic, constraint, naming convention, or open question appears.

## How To Use This File
- Treat this document as the shared memory for future chats and collaborators.
- When a new mechanic or decision is implemented, add it here in the relevant section.
- When something is uncertain, add it under `Open Questions` instead of inventing final rules.
- Keep entries concise and practical. Prefer facts that help future implementation.
- Do not remove old decisions unless they are truly obsolete; move them to `Changed Decisions` if useful.

## Project Identity
- Project name: Potma.
- Ownership: proprietary project owned by Potma. See `LICENSE.txt`.
- Engine: Godot 4.6.
- Language: GDScript.
- Always prefer current Godot 4.6 APIs and patterns.
- Do not use Godot 3 APIs.

## Game Concept
- Potma is a 3D collectathon inspired by classic adventure platformers like Spyro.
- The game is set in a colorful magical world.
- The protagonist is a wizard who cannot naturally cast magic.
- To use magic, the wizard must drink potions that temporarily grant abilities.
- The potion limitation should guide gameplay, collectibles, progression, level design, and player abilities.
- Desired tone: whimsical, exploration-focused, playful, magical, and readable.

## Core Gameplay Pillars
- Exploration in 3D spaces.
- Collectathon progression with clear collectible goals.
- Potion-driven abilities as the main magic system.
- Temporary powers that create route, combat, and traversal choices.
- Simple, readable systems over overengineered abstractions.

## Current Potion System
- The player has left and right potion slots.
- Left and right selected potion types are managed by `PlayerPotions`.
- Drinking one potion consumes one selected potion and emits `potionUsed`.
- Drinking both potions at nearly the same time combines the selected potion types.
- Combined potions are not added to inventory.
- Combined potions are consumed immediately: both ingredient potions are removed and the combined ability is activated directly.
- Active potion state is tracked by `ActivePotionEffectService`.
- Only one potion effect should be active at a time.

Important files:
- `player/scripts/potions-manager.gd`
- `assets/potions/shared/services/player-potions-inventory-service.gd`
- `assets/potions/shared/services/potion-merger-service.gd`
- `assets/potions/shared/services/active-potion-effect-service.gd`
- `assets/potions/shared/models/potion-types.gd`
- `assets/potions/shared/config/potion-config.gd`

## Potion Types And Abilities
- `Fire`: lets the player launch a fireball with the attack action.
- `Jump`: gives the player a higher jump.
- `Speed`: makes the player run faster.
- `SpeedAndFire`: grants a damage dash.
- `JumpAndFire`: grants a double jump; the second jump damages enemies on contact.
- `JumpAndSpeed`: currently uses the simplest useful implementation: high jump plus faster movement.

Current durations:
- `Jump`: 30 seconds.
- `Speed`: 20 seconds.
- `Fire`: 30 seconds.
- `JumpAndSpeed`: 30 seconds.
- `JumpAndFire`: 30 seconds.
- `SpeedAndFire`: 30 seconds.

## Player Controls
- Movement actions: `move-forward`, `move-backwards`, `move-left`, `move-right`.
- Jump action: `jump`.
- Attack action: `attack`.
- Dash action: `dash`.
- Drink left potion: `drinkPotionLeft`.
- Drink right potion: `drinkPotionRight`.
- Toggle left potion: `toggleLeftPotion`.
- Toggle right potion: `toggleRightPotion`.

## Ability Combat Rules
- Normal staff hit damages `CanGetHit` targets.
- Fire potion uses the fireball projectile.
- Combined abilities that include fire should not automatically behave like plain `Fire`.
- Damage dash and damaging second jump use the player's `AbilityDamageArea`.
- Ability contact damage should only be active during the intended ability window.

## Potion Visual Feedback
- Active potions should be visually readable on the protagonist.
- Current visual direction: apply a potion color to the protagonist mesh and drain it from top to bottom over the potion lifetime, like an hourglass.
- Current implementation targets `MainBody` because the imported model does not expose a separate cape mesh by name.
- If the cape becomes a separate mesh later, move the same visual effect to the cape.

Potion effect colors:
- `Fire`: red.
- `Jump`: blue.
- `Speed`: green.
- `JumpAndFire`: purple.
- `JumpAndSpeed`: cyan.
- `SpeedAndFire`: orange.

Important files:
- `player/scripts/player-model-manager.gd`
- `player/materials/shaders/potion_duration_body.gdshader`

## Existing Architecture Notes
- Autoloads are declared in `project.godot`.
- Prefer signals over tight coupling.
- Prefer composition over inheritance.
- Avoid singleton abuse, but keep existing autoload services when they are already part of the architecture.
- Use Resources for reusable data when appropriate.
- Keep scripts small and maintainable.
- Do not rewrite full files unnecessarily.
- Preserve existing architecture and variable names unless there is a clear reason to change them.

## Current Main Autoloads
- `SavesManager`
- `LevelCollectablesData`
- `GlobalManager`
- `PlayerPotions`
- `PotionMerger`
- `SelectedMergePotion`
- `ActivePotionEffectService`
- `CollectablesEmitterService`
- `PlayerInventory`
- `GameLog`

## Collectibles And World Objects
- The project includes mythril collectibles, coins, books, keys, chests, fire towers, arcs, elevators, doors, levers, NPC dialogue, and enemies.
- Collectibles and progression should support the 3D collectathon fantasy.
- Fire-based interactions exist through fireballs and fire puzzle objects.

## Enemies And Damage
- Damageable entities use the `CanGetHit` group.
- Some enemies expose `get_hit()` directly.
- Some enemy hit areas are `Area3D` nodes that forward hits to the enemy.
- The player belongs to the `MainPlayer` group.

## Visual Style
- The repo includes PSX-style camera/object shaders.
- Keep visual additions compatible with the retro/PSX-inspired style unless a specific feature calls for a different look.
- Prefer clear gameplay readability over decorative effects.

## Documentation And Rules
- `docs/AI_RULES.md` contains short AI/code rules.
- This file contains deeper project memory and should be updated more often.
- `AGENTS.md` in the repo root points future Codex sessions to these docs.

## Open Questions
- Final design for `JumpAndSpeed` is undecided. Current placeholder: high jump plus speed.
- Whether potion visuals should affect the full body, only the cape, or another model part depends on future character model structure.
- Exact balancing values for dash speed, dash cooldown, double jump force, and potion durations are provisional.

## Changed Decisions
- Potion merging originally created a new potion in the inventory.
- New decision: pressing both potion triggers should drink both ingredients immediately and grant the combined ability directly.
- Combined abilities should be distinct abilities, not just reused plain potion behavior.

## Update Log
- 2026-07-19: Created living context file for Potma.
- 2026-07-19: Documented direct potion combination, combination abilities, dash, double jump damage, and potion visual drain effect.
