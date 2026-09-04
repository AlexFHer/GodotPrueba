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
- During active or closing dialogue, all character actions are locked: movement,
  jump, dash, combat, potion drinking, and potion selection. Camera rotation
  remains available and `interact` continues to control the dialogue.
- Dialogue control lock is independent from `MainPlayer.canMove`. Physics,
  gravity, collisions, damage, enemies, and gameplay timers remain active.
- `MainPlayer.is_gameplay_input_locked()` is the shared player-side facade;
  future character input handlers and delayed offensive callbacks must honor it.
- Starting dialogue cancels active attacks, dash, and ability damage. A potion
  already consumed finishes its feedback, while pending drink/merge intents are
  discarded so they cannot resolve during the conversation.
- Gameplay `SceneTreeTimer` instances should use `process_always = false` so
  pause screens freeze their remaining time. Dialogue no longer uses tree pause.
- Pocima is the canonical implementation example.
- Exact setup instructions are in the [NPC dialogue guide](DIALOGUE_SYSTEM.md).

Important files:
- `dialogues/system/dialogue_system.tscn`
- `dialogues/components/dialogue_interactable.tscn`
- [Dialogue setup guide](DIALOGUE_SYSTEM.md)

## Normal Attack Combo
- The normal staff attack is a three-hit combo using `Potma_Attack`,
  `Potma_Attack2`, and `Potma_Attack3` in that order.
- Each hit requires one separate `attack` press; one press never plays the full
  combo automatically.
- While a hit is active, at most one press may be buffered for the next hit.
- After either of the first two hits finishes, the player has a 0.40-second grace
  window to request the next hit before the combo resets to hit one.
- The third hit never buffers another normal attack and always ends the combo.
- All three hits deal the same normal-attack damage.
- Each normal hit restarts and shows the staff trail for that hit; the combo
  code owns trail start/end so legacy animation callbacks cannot cut later
  stages short. The weapon trail is intentionally subtle: 48% opacity, a narrow
  ribbon profile, and a short 0.26-second trail lifetime. Its four-point width
  curve begins and ends almost at zero and uses extra ribbon subdivisions so it
  grows and tapers smoothly. The ribbon also uses
  `player/particles/staff_trail_soft.gdshader`, which fades alpha independently
  across both sides and both ends so the underlying rectangular mesh is never
  visible as a hard square. Fire changes its color and emission through shader
  parameters but keeps the same compact translucent shape.
- Normal attacks remain available while moving and while airborne; locomotion or
  leaving the ground does not reset the chain.
- Dialogue, potion drinking, dash, taking damage, and death are strong
  interruptions: they cancel the active combo, close its damage window, clear
  buffered input, and reset the next normal attack to hit one. Attacking remains
  blocked until the interrupting action or reaction finishes.
- Plain `Fire` reuses the normal three-hit animations instead of
  `Potma_FireAttack`. Every requested stage keeps its normal staff hit, changes
  the staff ribbon into an emissive orange-red trail, and launches both one
  fireball and one wide fire arc. The arc is the reusable
  `player/scenes/fire_arc_projectile.tscn` Area3D: it travels forward for 0.8
  seconds, passes through targets, and damages each compatible body or area at
  most once. Its curved, tapered fire cut has a bright core, animated noisy
  edges, a broad flame body, and dense trailing sparks. Both the fireball and
  fire arc travel at 16 units per second; their unchanged lifetimes also give
  them more range than the earlier 10-units-per-second version. The arc's roll
  matches each swing: hit 1 slopes 35
  degrees down from the left, hit 2 uses the opposite 35-degree diagonal, and
  hit 3 is vertical. Both projectiles share a centered spawn transform 1.05
  units above and 1.25 units directly ahead of the player; their origin is not
  attached to the animated staff bone. The existing 2-second Fire cooldown
  gates the start of a new chain but never blocks stages two or three of a chain
  already in progress.
- Fire-containing combined abilities continue to use the normal three-hit combo
  without the plain `Fire` projectile or fire-arc behavior.

## Ability Combat Rules
- Normal staff hit damages `CanGetHit` targets.
- Fire potion adds one fireball, one independent forward-moving fire arc, and a
  fire-colored staff trail to every stage of the normal three-hit combo.
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
- 2026-08-26: Locked player movement, combat, dash, potion use, and potion
  selection during active/closing dialogue while keeping camera and world
  simulation active.
- 2026-08-28: Defined the three-hit normal attack combo, including its animation
  order, one-input buffer, 0.40-second continuation grace, interruption rules,
  movement freedom, equal damage, and separation from the plain Fire attack.
- 2026-09-04: Replaced plain Fire's standalone throw animation with the normal
  three-hit combo; every stage now adds an emissive staff trail, one fireball,
  and one independent forward-moving fire arc, while the existing cooldown
  gates only the start of a new Fire chain. The fireball and arc travel at 16
  units per second, the arc uses an enlarged, thicker high-emission visual, and
  both spawn from one centered point directly ahead of the player rather than
  from the animated staff bone. The weapon-attached trail is a short, narrow,
  smoothly tapered 48%-opacity accent so it does not compete with the launched
  arc.
