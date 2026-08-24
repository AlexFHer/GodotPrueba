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
- Each selected slot is represented by a generic bottle attached to the
  corresponding `Potion.L` or `Potion.R` character bone.
- Belt bottles are hidden for `None` and identify potion types by liquid color:
  Fire is red, Jump is blue, and Speed is green.
- A consumed belt bottle keeps its current appearance until its drinking
  animation finishes, then synchronizes with the latest slot selection.
- Drinking one potion consumes one selected potion and emits `potionUsed`.
- Drinking both potions at nearly the same time combines the selected potion types.
- Combined potions are not added to inventory.
- Combined potions are consumed immediately: both ingredient potions are removed and the combined ability is activated directly.
- Active potion state is tracked by `ActivePotionEffectService`.
- Only one potion effect should be active at a time.
- Drink animation mapping: left uses `Potma_DrinkLeft`, right uses
  `Potma_DrinkRight`, and a successful combination uses `Potma_DrinkBoth`.

Important files:
- `player/scripts/potions-manager.gd`
- `player/scripts/Belt_potions_system.gd`
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
- Contextual interaction/dialogue action: `interact` (`E` on keyboard and the
  bottom controller face button: PlayStation Cross / Xbox A).
- Drink left potion: `drinkPotionLeft`.
- Drink right potion: `drinkPotionRight`.
- Toggle left potion: `toggleLeftPotion`.
- Toggle right potion: `toggleRightPotion`.

## NPC Dialogue System
- Dialogue is linear in v1: no choices, branches, gameplay commands, or
  persistence of already-read conversations.
- Content uses typed `DialogueData` and `DialogueLine` Resources, not JSON.
- Dialogue resources should store translation keys for localized NPC text; Pocima
  uses `npc_pocima_*` keys in `i18n/translations.csv`.
- Each `DialogueLine` may reference an optional, language-neutral
  `voice_stream`. One non-positional player in `DialogueSystem` plays it once
  when the line appears and stops it on advance, replacement, or close.
- Revealing the complete typewriter text does not restart or stop line audio.
  Lines without a stream are valid and silent.
- NPCs gain dialogue by composing one `DialogueInteractable` Area3D and assigning
  a dialogue resource; NPC scripts must not instantiate or control dialogue UI.
- One `DialogueSystem` is provided by `assets/levels/levelManager.tscn` and owns
  candidate selection, contextual input, typewriter progression, and HUD UI.
- If interaction zones overlap, the nearest valid NPC is selected.
- Dialogue does not pause the world; enemies, physics, potion durations, and
  other gameplay timers continue while the conversation UI is open.
- Dialogue can be replayed from the first line after close.
- `interact` intentionally overlaps the keyboard right-potion key and controller
  jump button. It has priority only while a valid prompt/dialogue is active.
- During active or closing dialogue, player jump and potion drinking ignore the
  shared interaction press so advancing text does not leak into gameplay.
- Gameplay `SceneTreeTimer` instances should use `process_always = false` so
  pause screens freeze their remaining time. Dialogue no longer uses tree pause.
- Pocima is the canonical implementation example.
- Exact setup instructions are in the [NPC dialogue guide](DIALOGUE_SYSTEM.md).

Important files:
- `dialogues/system/dialogue_system.tscn`
- `dialogues/components/dialogue_interactable.tscn`
- [Dialogue setup guide](DIALOGUE_SYSTEM.md)

## Ability Combat Rules
- Normal staff hit damages `CanGetHit` targets.
- Fire potion uses the fireball projectile.
- Combined abilities that include fire should not automatically behave like plain `Fire`.
- Damage dash and damaging second jump use the player's `AbilityDamageArea`.
- Ability contact damage should only be active during the intended ability window.

## Potion Visual Feedback
- Active potions should be visually readable on the protagonist.
- Current visual direction: apply a potion color to the protagonist mesh and drain it from top to bottom over the potion lifetime, like an hourglass.
- The potion color is limited by `player/materials/PotmaMat_Mask.png`: white UV regions receive the effect, black regions keep the original body color, and grayscale values blend between them.
- Current implementation targets the visible `Potma` mesh because the imported model exposes the body as one surface rather than a separate cape mesh.
- The original body material remains active while no potion is running. Active potions temporarily use an opaque, lit PBR surface override and restore the original override when they finish.
- The potion shader does not snap or move vertices. Its top-to-bottom drain uses a rest-pose height baked into `UV2.x` on an instance-exclusive copy of the visible body mesh, normalized between local Y `-0.025` and `1.04`. This keeps the cutoff stable when animation skinning changes the pose. The UV mask independently limits which clothing regions receive color, and potion activation explicitly renders the entire white mask once at full color strength before the timed vertical drain begins.
- If the cape becomes a separate mesh later, move the same visual effect to the cape.

Potion effect colors:
- `Fire`: red.
- `Jump`: blue.
- `Speed`: green.
- `JumpAndFire`: purple.
- `JumpAndSpeed`: cyan.
- `SpeedAndFire`: orange.

The shared potion color palette is provided by `PotionsConfig` and is used by
both active body feedback and the belt bottle liquids.

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
- Ground locomotion uses `Locomotion/WalkBlend`, a 1D blend space driven at
  runtime with `0 = Potma_Idle`, `1 = Potma_Walk`, and
  `2 = Potma_RunPotion`. Analog stick magnitude scales movement speed and the
  blend position: normal movement covers 0-1, while active speed sprinting
  covers 0-2. Keyboard movement uses full input strength, and damage dashes
  target the run point directly.

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
- 2026-07-19: Documented the reusable Resource-based NPC dialogue system,
  contextual interaction input, and pause-aware gameplay timer convention.
- 2026-07-19: Changed NPC dialogue to keep world time running while conversations
  are open; shared jump/potion inputs are still consumed contextually.
- 2026-07-19: Converted Pocima dialogue content to translation keys backed by
  `i18n/translations.csv`.
- 2026-07-25: Added optional non-positional audio per dialogue line; Pocima uses
  a temporary shared PCM blip for both lines.
- 2026-08-10: Mapped left, right, and combined potion drinking to their matching
  player animations.
- 2026-08-10: Connected the player's Idle/Walk/Run 1D locomotion blend space to
  movement and speed-potion sprint state.
- 2026-08-10: Made joystick movement analog; stick magnitude now scales both
  horizontal speed and the locomotion blend position.
- 2026-08-11: Added independent left/right belt bottle visuals driven by potion
  selection, including per-slot liquid materials and drink-animation retention.
- 2026-08-24: Limited the active potion body-color drain to the UV regions selected
  by `PotmaMat_Mask.png`; made it an active-only opaque PBR override that restores
  the original material. Baked a normalized rest-pose height into the instance
  mesh's free UV2 channel so animation skinning cannot move the vertical cutoff;
  the complete mask begins colored before draining, including one guaranteed
  full-strength rendered frame at activation.
