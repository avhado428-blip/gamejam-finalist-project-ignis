extends Node
## EventManager — central signal hub. FINAL NAMES.
## Cross-system events funnel through here so systems stay decoupled.

## These signals are the contract other systems connect to, so they are not
## "used" inside this file — silencing the unused-signal warning is correct here.
@warning_ignore("unused_signal")
signal player_spawned(player: Node)
@warning_ignore("unused_signal")
signal player_died(player: Node)
@warning_ignore("unused_signal")
signal player_respawned(player: Node)

@warning_ignore("unused_signal")
signal reality_shift_started(from_reality: int, to_reality: int)
@warning_ignore("unused_signal")
signal reality_shift_finished(reality: int)

@warning_ignore("unused_signal")
signal checkpoint_activated(position: Vector2)
@warning_ignore("unused_signal")
signal objective_changed(text: String)
@warning_ignore("unused_signal")
signal prompt_changed(text: String)
@warning_ignore("unused_signal")
signal interaction_used(target: Node)

@warning_ignore("unused_signal")
signal request_camera_shake(amount: float, duration: float)
@warning_ignore("unused_signal")
signal request_flash(color: Color, duration: float)

## ── puzzle / area vocabulary ───────────────────────────────────────────────
## Everything a puzzle needs to say to the rest of the game goes through these,
## so no component ever has to reach into a specific level.

## A quiet, truthful hint line (tutorial zones, "it does not open", ...).
@warning_ignore("unused_signal")
signal hint_changed(text: String)

## Something was triggered by id. Fired by Interactables, listened to by Mechanisms.
@warning_ignore("unused_signal")
signal mechanism_activated(id: StringName)

## A mechanism changed state. Fired by Mechanisms, listened to by gates/reactors.
@warning_ignore("unused_signal")
signal mechanism_state_changed(id: StringName, active: bool)

## Something that was triggered by id has been let go again — a plate that
## sprang back up, a lever released. Lets a lock undo the step it took.
@warning_ignore("unused_signal")
signal mechanism_deactivated(id: StringName)

## Ask for the next reality shift to be loud, or deliberately quiet.
## AmbiguousShiftZone (Area 5) uses this: the shift is still real, only the
## feedback is withheld.
@warning_ignore("unused_signal")
signal shift_style_requested(muffled: bool)
