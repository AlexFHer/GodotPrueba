# Manual Regression Checklist

## Scope
Validate gameplay after naming migrations, potion-state unification, logger adoption, and enemy refactors.

## Smoke
1. Open project and ensure no missing resource popups.
2. Run main scene and verify the level loads without parser/runtime errors.
3. Open [scenes/tests/SceneTest.tscn](scenes/tests/SceneTest.tscn) and [scenes/tests/assets_test.tscn](scenes/tests/assets_test.tscn) to confirm potion scenes instantiate.

## Player Core
1. Move, jump, and attack with no potion active.
2. Receive damage and verify life decreases and death flow restarts scene.
3. Verify movement lock during potion drink lasts briefly and returns control.

## Potions
1. Cycle left and right potion slots.
2. Drink left slot only and confirm effect activates and expires.
3. Drink right slot only and confirm effect activates and expires.
4. Press both drink buttons within merge window and verify merge result is added.
5. Confirm no drink action is allowed while another potion effect is active.
6. Confirm fire potion changes attack behavior to projectile throw.

## Enemies
1. GlobrcSmall patrols between points and idles at waypoints.
2. GlobrcSmall follows player on detection and returns to patrol after timeout.
3. Mimic stays idle until player enters detection range, then follows and attacks.
4. Both enemies stop reacting after death state.

## Interaction Systems
1. Elevator moves through points and continues cycles without stopping.
2. Chest warns/blocks open when player has no key.
3. Secret tower activation still animates and audio plays.
4. Approaching and leaving Pocima shows and hides one dialogue prompt.
5. `E`, PlayStation Cross, and Xbox A open, reveal, advance, and close dialogue.
6. Starting or closing dialogue does not also jump or consume a potion.
7. Dialogue does not pause enemies, physics, potion duration, or gameplay timers.
8. Start does not open the pause menu over an active conversation.
9. Closing restores gameplay, shows the nearby prompt, and permits reopening.
10. Overlapping NPC interaction zones select only the nearest valid NPC.
11. The prompt badge follows the last-used device and updates safely when a
    controller is connected or disconnected (`E`, PlayStation `X`, Xbox `A`, or
    `A/X` for an unknown controller).
12. Deleting an NPC while its interaction zone is registered produces no error
    and removes it from candidate selection.
13. Empty, missing, or incomplete dialogue data logs a warning, skips invalid
    entries, and never opens an empty UI.
14. Dialogue layout wraps long text and shows Pocima's localized Spanish and
    English text, not raw translation keys, at 1280x720 and 1920x1080.
15. Each Pocima line plays one blip when it appears; completing the typewriter
    text does not restart or stop that clip.
16. Advancing or closing while a clip plays stops it, and the next line never
    overlaps the previous clip.
17. Closing and reopening starts the first line's audio again from the beginning.
18. A dialogue line with no `voice_stream` is silent and still displays normally.

## Naming Migration Validation
1. Confirm the shared dialogue system loads from
   [dialogues/system/dialogue_system.tscn](../../dialogues/system/dialogue_system.tscn).
2. Confirm the reusable NPC component resolves from
   [dialogues/components/dialogue_interactable.tscn](../../dialogues/components/dialogue_interactable.tscn).
3. Confirm Pocima references a typed `DialogueData` resource and no legacy JSON.
4. Confirm potion scene paths resolve in level scene and test scenes:
   - [assets/potions/fire_potion/fire_potion.tscn](assets/potions/fire_potion/fire_potion.tscn)
   - [assets/potions/jump_potion/jump_potion.tscn](assets/potions/jump_potion/jump_potion.tscn)
   - [assets/potions/speed_potion/speed_potion.tscn](assets/potions/speed_potion/speed_potion.tscn)

## Logging
1. In debug build, verify gameplay debug/info logs appear with prefixes.
2. Ensure no direct print-based debug spam appears from touched gameplay scripts.
