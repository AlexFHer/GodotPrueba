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
3. Walk, run, turn, and jump while drinking from either hand or both. Confirm
   the legs and lower robe keep their locomotion animation while the upper body
   drinks, the bottles follow the hands, and attacks/dashes stay blocked until
   drinking ends.
4. Walk and rotate beside walls, pillars, corners, and low ceilings. Confirm the
   camera retracts without crossing the obstacle, changes distance smoothly,
   and returns more gently to its normal three-metre distance afterward.
5. Repeat the obstacle check while sprinting and dashing. Confirm a sudden close
   collision may retract faster for safety but never leaves the camera behind
   the wall or changes the player's movement direction unexpectedly.

## Three-Hit Normal Attack Combo
Use [combo_hit_counter_targets.tscn](combo_hit_counter_targets.tscn), already
placed beside the player spawn in [assets_test.tscn](assets_test.tscn). The blue
column exercises the `Body3D` damage path and the orange column exercises the
`Area3D` path. Reload the scene between cases to reset both visible counters.

1. With no potion active, stand within staff range of the blue `BODY` column and
   tap Square once. Confirm only attack 1 plays and the display changes exactly
   once from `0 / 3 READY` to `1 / 3 KEEP COMBO`.
2. Let the combo continuation window expire, then tap Square again. Confirm the
   animation restarts at attack 1 rather than advancing to attack 2; each swing
   still adds exactly one visible hit.
3. Reload, then press Square once per valid continuation window. Confirm attacks
   1, 2, and 3 play in order, each attack shows the staff trail, and the blue
   display finishes at exactly `3 / 3 OK`.
4. Repeat the complete chain against the orange `AREA` column. Confirm its display
   also finishes at exactly `3 / 3 OK`, proving both damage callbacks work.
5. Stay overlapped with each target throughout a complete chain. Confirm closing
   and reopening each strike window produces one hit per attack: no missed second
   or third hit and no `EXTRA HIT` result.
6. Press Square repeatedly during one attack. Confirm input buffering advances at
   most one stage, never skips an animation, and never produces two hits from one
   strike window.
7. Queue one Square press near the end of attack 1. Confirm attack 2 starts once;
   do not press again and confirm the chain then expires instead of auto-playing 3.
8. Complete attack 3, wait through recovery, and press Square once. Confirm a new
   chain starts at attack 1 rather than attempting a fourth combo stage.
9. Start a combo near Pocima in the main level and open dialogue during startup,
   the active hit window, and recovery in separate runs. Each time confirm the
   animation, staff collision, sound, trail, queued input, and combo state clear;
   no delayed hit occurs and the first post-dialogue Square starts attack 1.
10. Let an enemy damage the player during attacks 1, 2, and 3 in separate runs.
    Confirm the hit reaction cancels the current chain and its hitbox, and the next
    accepted Square starts attack 1.
11. Begin drinking a potion during a normal combo. Confirm drinking cancels the
    chain without a delayed staff hit; normal attacking remains blocked until the
    drink finishes, then restarts from attack 1.
12. Start and continue combos while jumping or falling. Confirm airborne Square
    presses remain valid, leaving the floor does not reset the current chain, and
    the same continuation timing applies before and after landing.
13. With the damage-dash potion active, press Square. Confirm Square starts the
    fire dash instead of the normal staff chain and only ability contact damage
    becomes active. Confirm the dash action does not start this potion dash. In a
    separate run, take damage during the dash and confirm attacking stays blocked
    until both the dash and hit reaction finish, then restarts cleanly after the
    potion ends.
14. With plain Fire active, complete attacks 1, 2, and 3. Confirm the three normal
    attack animations play in order, the staff hitbox still deals one hit per
    stage, and each stage shows an emissive orange-red staff trail and launches
    exactly one fireball plus one separate forward-moving fire arc. Confirm arc 1
    slopes down from the left, arc 2 uses the opposite diagonal, and arc 3 is a
    vertical top-to-bottom cut.
15. Pause during the continuation window and wait longer than its normal duration.
    Resume and confirm the remaining window was frozen rather than expiring while
    paused.
16. During every normal stage, verify one matching sound and trail window, that the
    weapon trail is short, thin, and lightly translucent; confirm it grows from
    and returns to a point with softly faded sides and no visible rectangular
    edge, stops on completion or cancellation, and that locomotion resumes cleanly.
17. Start a plain Fire chain and press Square for stages 2 and 3 before the
    two-second projectile cooldown expires. Confirm both continuation inputs are
    accepted, but a new Fire chain cannot start until the cooldown finishes.
18. Let a plain Fire chain expire after attack 1 or 2. Confirm the next accepted
    Square starts again at attack 1, the staff trail returns to its normal color
    after Fire expires, and any previously launched arc finishes naturally.
19. Aim a Fire attack at multiple aligned targets. Confirm its wide fire arc
    passes through them and damages each compatible body or area exactly once;
    confirm the tapered bright core, animated red-orange edge, and sparks are
    visible before the arc disappears after its short forward travel.
20. Compare the fireball and fire arc in motion. Confirm both travel at the same
    faster speed, the enlarged arc remains clearly readable, and its thicker
    body, stronger glow, denser sparks, and larger collision remain aligned.
21. Attack while each of the three Fire animations moves the staff to a different
    side. Confirm the fireball and arc always appear together at chest height,
    centered directly ahead of the player, and travel along the facing direction
    without inheriting the staff bone's lateral offset.

## Potions
1. Start with an empty inventory and confirm both belt bottles are hidden.
2. Pick up the first potion and confirm both automatically selected belt slots
   appear with the correct liquid color.
3. Cycle left and right potion slots independently; confirm each bottle updates
   without changing the other bottle's color or liquid wobble.
4. Drink the last potion from the left slot and confirm its bottle remains
   visible through `Potma_DrinkLeft`, then updates or hides when it finishes.
5. Repeat the previous check for the right slot and `Potma_DrinkRight`.
6. Press both drink buttons within the merge window and confirm both ingredient
   bottles remain visible through `Potma_DrinkBoth`, are consumed directly, and
   update afterward without displaying the combined potion on the belt.
7. Reload the player scene while `PlayerPotions` retains selections and confirm
   both belt visuals synchronize immediately.
8. Confirm the potion effect activates and expires after drinking either slot.
9. Confirm no drink action is allowed while another potion effect is active.
10. Confirm plain Fire changes each stage of the normal combo into a fire-colored
    staff swing with one additional fireball and one independent fire arc;
    combined Fire potions retain their own existing abilities.
11. Finish drinking while standing still and while the player is at several
    different world positions. Confirm the completion burst always appears over
    the player, never at the map origin or another unrelated location; begin
    moving immediately and confirm the short burst remains attached to the
    character.

## Pause Menu And Settings
1. Open pause and enter Settings with keyboard, mouse, and controller. Confirm
   focus begins on Master volume and every slider, toggle, language button, and
   Back button is reachable without a mouse.
2. Change Master volume and confirm both level music and gameplay effects change.
   Set it to 0% and confirm all game audio is silent, then restore it.
3. Change Music volume and confirm menu/level music changes while player and
   collectible sounds keep their current level.
4. Change Effects volume and confirm movement, attack, potion, dialogue,
   collectible, chest, projectile, and puzzle sounds change while music does not.
5. Toggle fullscreen on and off and confirm the checkbox follows the current
   saved state without unpausing the game.
6. On a fresh settings file, confirm Euskara is selected by default. Cycle through
   Euskara, Spanish, and English from both the main menu and pause settings;
   confirm labels update immediately and the chosen language is kept after
   changing scene.
7. Return with the visible button, `Esc`, and controller Circle/B in separate
   runs. Confirm focus returns to Resume and gameplay remains paused.
8. Reopen settings, return to the main menu, and restart the game. Confirm all
   three volume values, fullscreen, and language persist and the main-menu master
   volume/fullscreen controls show the same state.
9. Pause while potion, combo, and ability timers are active. Spend time changing
   settings, resume, and confirm the gameplay timers did not advance.

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
6. During active and closing dialogue, movement, jump, dash, attack, fire,
   drinking, and left/right potion selection do nothing; camera rotation works.
7. Opening while moving stops horizontal movement and blends locomotion to idle.
8. Opening during dash, damaging second jump, staff attack, or fire attack
   cancels the offensive action, disables its hitbox, and spawns no projectile.
9. Opening during the 0.25-second merge window discards pending drink intents.
10. A potion already consumed finishes its animation, audio, particles, and belt
    synchronization without unlocking controls during the dialogue.
11. An airborne player keeps falling and can receive damage or die; enemies,
    physics, potion duration, and gameplay timers continue normally.
12. Start does not open the pause menu over an active conversation.
13. Holding `E` or A/Cross through the final line triggers no gameplay action;
    releasing it restores controls, shows the nearby prompt, and permits reopening.
14. Overlapping NPC interaction zones select only the nearest valid NPC.
15. The prompt badge follows the last-used device and updates safely when a
    controller is connected or disconnected (`E`, PlayStation `X`, Xbox `A`, or
    `A/X` for an unknown controller).
16. Deleting an NPC while its interaction zone is registered produces no error
    and removes it from candidate selection.
17. Empty, missing, or incomplete dialogue data logs a warning, skips invalid
    entries, and never opens an empty UI.
18. Dialogue layout wraps long text and shows Pocima's localized Euskara,
    Spanish, and English text, not raw translation keys, at 1280x720 and
    1920x1080.
19. Each Pocima line plays one blip when it appears; completing the typewriter
    text does not restart or stop that clip.
20. Advancing or closing while a clip plays stops it, and the next line never
    overlaps the previous clip.
21. Closing and reopening starts the first line's audio again from the beginning.
22. A dialogue line with no `voice_stream` is silent and still displays normally.

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
