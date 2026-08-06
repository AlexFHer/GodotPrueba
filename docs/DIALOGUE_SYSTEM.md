# NPC Dialogue System

Potma uses one reusable, linear dialogue system for every NPC. Dialogue content
is stored in typed Godot `Resource` files, proximity is handled by a composed
`DialogueInteractable`, and one `DialogueSystem` supplied by the level manager
owns contextual input, candidate selection, typewriter flow, and UI.

## Important Files

- `dialogues/resources/dialogue_line.gd`: one speaker, multiline text, and an
  optional non-positional voice clip.
- `dialogues/resources/dialogue_data.gd`: an ordered array of dialogue lines.
- `dialogues/components/dialogue_interactable.tscn`: reusable NPC proximity area.
- `dialogues/system/dialogue_system.tscn`: the single controller and UI per level.
- `assets/npcs/pocima/pocima_dialogue.tres`: canonical typed dialogue content.
- `assets/npcs/pocima/pocima_dialogue_blip.tres`: temporary Pocima voice blip.
- `assets/npcs/pocima/pocima.tscn`: canonical working NPC example.

## Add Dialogue To An NPC

1. Next to the NPC scene, create a new `DialogueData` `.tres` resource.
2. Add one inline `DialogueLine` resource per line, in playback order. Set its
   `speaker` and multiline `text` fields. Leave `speaker` empty for narration.
   Optionally assign an imported OGG/WAV or another `AudioStream` to
   `voice_stream`. The same stream can be shared by several lines.
3. Leave `voice_stream` empty when a line should be silent. Missing audio is
   valid and does not produce a warning.
4. Instantiate `res://dialogues/components/dialogue_interactable.tscn` once as a
   child of the NPC root.
5. Assign the `.tres` to the component's `dialogue_data` property.
6. Adjust the component's exported `interaction_radius` if the default 2.5-unit
   sphere does not match the character. Do not edit its internal collision child,
   and do not add input or UI code to the NPC.
7. Ensure the playable level includes `assets/levels/levelManager.tscn` and the
   player remains in the `MainPlayer` group.
8. Test prompt entry/exit, audio, the full conversation, closing, and reopening.

Do not add a dialogue autoload or a second `DialogueSystem`; the level manager
already supplies exactly one controller and UI to each playable level.

Literal dialogue is supported. For localized content, store a translation key
in `speaker` or `text` and add that key to `i18n/translations.csv`; the UI calls
`tr()` and therefore leaves unknown literal strings unchanged.

## Runtime Contract

- The `interact` action is physical `E` on keyboard and the bottom face button
  (`JOY_BUTTON_A`: PlayStation Cross or Xbox A) on controllers.
- `E` remains the right-potion key and the controller button remains jump when
  no valid dialogue candidate is nearby. Dialogue gets contextual priority only
  while its HUD prompt is visible or a conversation is active.
- With overlapping zones, the controller selects the closest valid NPC and uses
  instance ID as a deterministic tie-breaker.
- A conversation does not pause the world. The first press during typewriter
  reveal completes the current line; the next advances; the final advance closes it.
- A line's `voice_stream` plays once, non-positionally, when that line appears.
  Completing the typewriter reveal does not restart or stop it. Advancing,
  closing, or replacing the line stops the previous stream before continuing.
- The shared player uses the `Master` audio bus. Do not add an audio player to
  each NPC for normal dialogue playback.
- Conversations always restart at line zero and can be replayed indefinitely.
- Dialogue resources contain content only. Never store current line, completion,
  or other runtime state in a shared `DialogueData` resource.
- Gameplay delays created with `SceneTree.create_timer()` should pass
  `process_always = false` so pause-menu pauses freeze them. Dialogue itself does
  not pause these timers.

## Validation Checklist

- Missing or empty dialogue data does not show a prompt and reports a warning.
- Entering and leaving the area shows and hides one prompt.
- Keyboard, PlayStation, and Xbox labels follow the last-used device.
- Starting/closing never also jumps, attacks, or consumes a potion.
- Start cannot open the pause menu over an active conversation.
- Player, enemies, physics, potion durations, and gameplay timers keep running
  while dialogue is open.
- Pocima plays one blip per line; completing the visible text does not replay it.
- Advancing or closing quickly cuts the old clip without overlapping the next.
- A line with no `voice_stream` remains silent and otherwise behaves normally.
- Long text wraps correctly at 1280x720 and 1920x1080.

Do not revive the retired JSON dialogue loader or instantiate dialogue UI from
individual NPC scripts.
