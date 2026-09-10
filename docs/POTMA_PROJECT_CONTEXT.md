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
- Engine: Godot 4.7, with Godot 4.7.2 stable as the team editor and asset-import baseline.
- Language: GDScript.
- Always prefer current Godot 4.7 APIs and patterns.
- Use Godot 4.7.2 stable for asset reimports to avoid generated metadata churn between team environments.
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
- Drinking blocks movement and jumping only while the drink `AnimationTree`
  one-shot is active. `PotionsManager` start/finish signals own that lock, so
  control returns on the same frame that the drink animation completes rather
  than after a separate fixed-duration timer.
- Drink-completion particles are instantiated at the local origin of the
  `PotionsParticlesSystem` marker above the player and simulate in local
  coordinates, keeping the burst attached to the character instead of an
  unrelated world position.
- Drinking one potion consumes one selected potion and emits `potionUsed`.
- Drinking both potions at nearly the same time combines the selected potion types.
- Combined potions are not added to inventory.
- Combined potions are consumed immediately: both ingredient potions are removed and the combined ability is activated directly.
- Active potion state is tracked by `ActivePotionEffectService`.
- Only one potion effect should be active at a time.
- Drink animation mapping: left uses `Potma_DrinkLeft`, right uses
  `Potma_DrinkRight`, and a successful combination uses `Potma_DrinkBoth`.
- Drinking feedback uses `player/sfx/DrinkPotionMagic.wav`, derived from the
  user's `06-09-2026 17.01(2).m4a`: only the bottle-opening transient
  (0.48-0.76 seconds of the source), with pitched sparkle and a short echo.
  The 0.95-second result excludes the later falling-cap sounds and drinking.
  It reuses the existing drink-completion sound cue on the `SFX` bus.

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

## Player Camera
- `MainCharacterCamera` explicitly starts as `current = true`. This prevents
  earlier-instantiated teleport cameras from becoming the gameplay camera;
  wells take control only during travel and restore the prior camera afterward.
- The third-person camera normally sits 3 metres from `CameraPivot`.
- `SpringArm3D` is a collision probe rather than the camera's direct parent. It
  casts 0.55 metres beyond the desired camera distance so nearby obstacles are
  detected before they reach the camera.
- `playerCamera.gd` interpolates the actual camera distance independently: it
  retracts with responsiveness 18 and recovers with responsiveness 6. This
  keeps obstacle avoidance quick and makes the return to the normal distance
  visibly softer.
- The smoothed distance is always capped by the current collision distance, so
  an obstacle that appears suddenly cannot leave the camera behind the wall.
- `preferredDistance`, `collisionLookAhead`, `collisionApproachSpeed`, and
  `collisionRecoverySpeed` are exported tuning values on `CameraPivot`.

## Pause Menu And Settings
- The primary pause screen opened with `start` shares the settings screen's
  responsive full-screen dimming layer and centered translucent panel, with a
  localized title, separator, evenly spaced actions, and automatic focus on Resume.
- Pause and settings use the shared `Pause_Overlay.tres` theme. Its palette comes
  from the game art: deep aubergine surfaces, crystal-cyan borders and sliders,
  warm gold focus/title accents, and soft cream text. Keep the treatment compact,
  lightly rounded, and readable rather than visually heavy.
- The pause settings screen provides separate linear sliders for `Master`,
  `Music`, and `SFX`, plus fullscreen and Euskara/Spanish/English language controls.
- Euskara (`eu`) is the default language for new settings files. Existing saved
  language choices remain unchanged.
- `default_bus_layout.tres` defines `Music` and `SFX` buses routed through
  `Master`. Menu and level tracks use `Music`; player, dialogue, combat,
  collectible, potion, puzzle, and prop sounds use `SFX`.
- `GameSettings` is the shared settings autoload. It applies settings at startup
  and saves them to `user://saves/settings.cfg` after a short debounce so slider
  movement does not write on every step.
- The main menu's master-volume, fullscreen, and language controls use the same
  service, so their values remain synchronized with the pause menu.
- The settings screen remains interactive while the scene tree is paused,
  supports keyboard, mouse, and controller focus navigation, and can return via
  its visible button, `ui_cancel`, or the `circle` action.

Important files:
- `shared/scripts/settings_manager.gd`
- `default_bus_layout.tres`
- `scenes/shared/main-menus/settings-menu/settings-menu.tscn`

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
- Staff contacts with solid World/Enemy colliders or `CanGetHit` areas emit
  `player/particles/staff_impact.tscn`: six blue and six yellow spinning stars
  plus a small expanding cyan wave. Feedback runs once per collider per swing,
  including non-damageable scenery, and uses physics contact points when available.
  Player-owned colliders and detection-only trigger areas are excluded. Damage
  still requires `CanGetHit` and `get_hit()`. Effects expire after 0.7 seconds.
  `scenes/tests/staff_impact_test.gd` checks real physics contacts, repeat-hit
  prevention, subsequent swings, filtering, and cleanup with the player scene.
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
- `GameSettings`

## Collectibles And World Objects
- Well teleports use `assets/teleports/teleport.tscn`, with a directional
  `destination` reference to another instance in the same level. `EntryPoint`,
  `InsidePoint`, `ExitPoint`, `TeleportCamera`, and `CameraFocus` configure staging.
  Entry centers/sinks the player, holds the origin camera for 2 seconds, cuts to
  the destination camera, then launches a directed parabolic jump to `ExitPoint`.
  Destination hold, jump duration/height and landing hold are exported. The travel
  session restores the previous camera and suppresses immediate arrival reentry.
  `MainPlayer.begin_teleport/end_teleport` own the input/physics/collision lock and
  jump/fall pose playback; travel cancels attacks and rejects damage/checkpoint
  warps and new dialogue. Pause freezes travel, while normal world/potion time
  continues. Removing an endpoint aborts safely back to the entry transform.
  Setup and playable/automated tests are documented in `docs/TELEPORTS.md`.
- `assets/collectable/magic_fragment/magic_fragment.tscn` is a round water-like
  magic fragment: a translucent glossy blue shell with subtle ripples and 28
  luminous motes plus 12 bright five-pointed star particles orbiting within its
  volume. Stars face the camera, slowly rotate, and pulse with emission energy 7.
  The bubble has a strong cyan Fresnel rim (energy 4.5, power 1.8), which broadens
  and brightens between 4 and 18 metres from the camera for distance readability
  while keeping its center transparent. Rim color, energy, and power are tunable.
  A shadowless cyan OmniLight (energy 3.5, range 3 metres) lights nearby surfaces.
    One green amalgam-like glow sits at the exact center: five smoothly merged lobes
  grow and retract independently around a connected core, while irregular spikes
  emerge and recede. Shader parameter `morph_speed` controls the deformation rate.
  It uses a single billboard mesh
  with a soft halo and gentle pulse, separate from stars.
  Particle motion stays local
	and bounded inside the sphere. Touching it with a `MainPlayer` triggers a
  one-shot pickup: 0.3-second squash/stretch, a flash, and 48 outward droplets.
  The fragment emits `collected` once, then `popped` before freeing itself after
  the burst. Gameplay pickup now saves one `shard` reward per level; visual
  previews and direct `pop()` calls do not award progress. `pop()` also
  allows scripted activation; `preview_pop_loop` is an optional visual preview.
  The whole fragment floats vertically by ±0.1 units on a 2.4-second cycle,
  pausing during pop. `float_height` and `float_period` are exported controls.
  Floating uses one delta-driven sine wave per rendered frame, preserving speed
  through the center instead of chaining eased tweens that stop mid-cycle.
  Placed instances must inherit their script; `script = null` disables pickup.
  Pop audio uses `magic_pop_echo.wav`, processed from the user-provided
  `soundreality-pop-423717.mp3` with pitched shimmer, crystalline accents and
  fading stereo echoes. A positional SFX player starts at the burst and lives
  as a sibling until playback finishes so removing the fragment keeps its tail.
  `pop_sound` and `pop_volume_db` are inspector controls.
- The project includes mythril collectibles, coins, books, keys, chests, fire towers, arcs, elevators, doors, levers, NPC dialogue, and enemies.
- Collectibles and progression should support the 3D collectathon fantasy.
- The four level collectible categories are babys, mythril, books, and magic
  shards. Babys and the existing magic fragment now use the same persistent
  ledger as mithril/books, without invalidating earlier saves.
- Select (`toggle-hud`) shows all four counters, including zero: shards at top
  left, books at top center, mythril at top right (40px number), and the existing
  baby render at bottom center. Anchored containers adapt to viewport size.
  The key indicator remains separate at bottom right when a key is held.
  HUD icons, numbers, spacing, and container bounds were reduced by about 15%, then a further 10%
  at the user's request, preserving screen anchors and edge margins.
- The top HUD slides down from above the viewport while babys slide up from
  below it, both in 0.45 seconds. They stay for 3 seconds, then fade toward
  their respective screen edges. Repeated Select replaces the active tween and
  renews the duration. UI owns the animation; level manager supplies progress.
- The shard HUD render is `assets/collectable/magic_fragment/ui/magic_shard_icon.png`;
  it is a transparent ImageGen asset. Its exact generation prompt is recorded
  beside it in `GENERATION.md`. The in-world fragment VFX remains unchanged.
- Collectible progress persists per level when leaving or closing the game.
  `LevelCollectablesData` saves a versioned reward ledger immediately to
  `user://saves/collectables_v1.json`; totals are derived from recorded rewards.
  Failed writes reject the pickup, and invalid saves are not overwritten.
- `levelName` is the stable level ID. Existing levels have explicit IDs. Each
  placed mithril, coin, book, chest, and reward-bearing enemy exposes
  `collectableId`, unique within its level. Keep both IDs unchanged when moving
  or renaming content; assign a NEW collectible ID when duplicating an object.
  Existing placed rewards have IDs. Empty IDs fall back to a level-relative
  node path for prototypes only; such saves depend on the scene hierarchy.
- The emitter requires the source node, resolves its level manager, records the
  reward once, then emits a level-qualified signal. Level manager scope is its
  owning scene (or itself when run standalone); keep one manager per level.
- Collected loose items disappear on reentry. Chests restore their opened state
  without consuming another key; magic chests also remove their force field.
  Enemies still respawn, but their mithril reward is granted only once per level.
- `LevelCollectables` remains authored configuration; each manager duplicates it
  into a HUD snapshot and restores both mithril and book state from the ledger.
  Keys, potions, enemy death, and puzzle completion are not persisted here.
- Persistence regression coverage is in
  `scenes/tests/collectable_persistence_test.tscn` (separate write/read runs with
  isolated APPDATA containing `.collectable-test-user`, never real player saves).
- Fire-based interactions exist through fireballs and fire puzzle objects.

## Enemies And Damage
- Globrc Big waits a random 1.0-1.6 seconds after each attack finishes before
  attacking again if the player remains in attack range. Inspector properties
  `attack_cooldown_min` and `attack_cooldown_max` tune this pause; it follows
  gameplay processing, freezes with pause, and is not reset by range reentry.
- Globrc Big's ground slam emits an expanding blue-white electrical discharge,
  with jagged flickering arcs and branches instead of a solid torus. Its shader
  follows the damage radius, fades at the outer limit, and uses per-instance
  materials so overlapping waves remain independent. Two emissive 3D lightning
  filaments arch above the ground wave, with shader-driven jagged deformation.
  Expansion speed is 6.5 units/second (previously 5); range, jump avoidance,
  and once-per-wave damage behavior are preserved.
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
- 2026-09-04: Made the potion movement lock follow the actual drink-animation
  one-shot instead of a fixed 2.1-second timer, and anchored completion
  particles to the player's local particle marker.
- 2026-09-04: Decoupled the third-person camera from the `SpringArm3D` endpoint
  and added predictive, asymmetric distance smoothing for obstacle avoidance.
- 2026-09-04: Expanded pause settings with persistent Master/Music/SFX volumes,
  fullscreen, language selection, controller navigation, and shared main-menu
  state through the new `GameSettings` autoload.
- 2026-09-10: Aligned project instructions with the intentional Godot 4.7
  migration and standardized development and asset imports on Godot 4.7.2 stable.
- 2026-09-10: Added Euskara localization for gameplay UI, menus, settings, and
  Pocima dialogue; Euskara is the default for new settings while saved choices
  remain respected.
- 2026-09-10: Restyled the primary pause screen to match the settings panel while
  preserving its existing Resume, Settings, and Main Menu behavior.
- 2026-09-10: Refined the shared pause/settings presentation around Potma's
  aubergine, crystal-cyan, sky-lilac, and gold palette, including polished button
  states and diamond-shaped slider handles.
