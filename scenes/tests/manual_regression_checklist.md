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
4. NPC dialogue starts and loads dialogue file correctly.

## Naming Migration Validation
1. Confirm dialogue scene loads from [dialogues/dialogue.tscn](dialogues/dialogue.tscn).
2. Confirm NPC script path resolves to [assets/npcs/npc_dialogue.gd](assets/npcs/npc_dialogue.gd).
3. Confirm potion scene paths resolve in level scene and test scenes:
   - [assets/potions/fire_potion/fire_potion.tscn](assets/potions/fire_potion/fire_potion.tscn)
   - [assets/potions/jump_potion/jump_potion.tscn](assets/potions/jump_potion/jump_potion.tscn)
   - [assets/potions/speed_potion/speed_potion.tscn](assets/potions/speed_potion/speed_potion.tscn)

## Logging
1. In debug build, verify gameplay debug/info logs appear with prefixes.
2. Ensure no direct print-based debug spam appears from touched gameplay scripts.
