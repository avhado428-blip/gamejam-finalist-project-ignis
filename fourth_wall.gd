class_name FourthWall
extends Area2D
## The one time the game stops pretending.
##
## Every room before this one has talked to the player through the HUD: the
## prompt, the name of the world, the lamps in the corner. Walking into this knocks
## that out of the picture mid-sentence, says a few things in the game's own voice
## instead — about the person holding the keyboard rather than the character on
## screen — and then puts the camera into the screen, because that is where the
## rest of this happens.
##
## What it hands over to is the ending's own two-of-you merge, and then the parkour
## room. `Engine`'s "parkour_mode" is how the ending is told it is being borrowed
## as this beat rather than being the end of the game: the ending consumes it as it
## loads, so the real ending still plays afterwards, when the parkour is finished.

const MERGE_SCENE := "res://levels/ending.tscn"
const FADE_OUT := 0.55

## Everything said to the player, one line at a time, in order. Rewrite these
## freely: nothing else in this file cares what they say.
@export var lines: PackedStringArray = [
	"YOU HAVE BEEN PRESSING Q FOR SEVEN ROOMS.",
	"IT WILL NOT HELP HERE. THIS IS NOT A WALL YOU CAN STAND ON THE OTHER SIDE OF.",
	"COME IN. BRING YOURSELF.",
]
## Seconds a line holds once it has finished arriving. Short, because three lines
## of being talked to is already a long time to be talked to.
@export var hold: float = 1.2
## How long the camera takes to go into the picture, and how far in it goes. At the
## end of it the pixels are the size of the screen.
@export var zoom_time: float = 1.5
@export var zoom_to: float = 3.4
@export var skippable: bool = true

const COL_WORD := Color(0.941, 0.129, 0.145, 0.98)
const COL_OUTLINE := Color(0.015, 0.015, 0.02, 0.95)
## The caption plate under the line: nearly black, and nearly opaque. The words here are
## the same red the room is made of, so without this they are a red sentence on a red wall.
const COL_PLATE := Color(0.025, 0.012, 0.045, 0.82)
const COL_BLACKOUT := Color(0.043, 0.020, 0.078, 1.0)
const COL_SHOT := Color(0.62, 0.20, 0.24, 0.42)
## How fast a line arrives, in characters per second, and how much it twitches.
const CHARS_PER_SECOND := 30.0
const JITTER := 3.2
const LINE_Y := 140.0

var _fired: bool = false
var _advance: bool = false
var _layer: CanvasLayer
var _dlg: Label
var _blackout: ColorRect
var _glitch: Glitch


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	# authored without a shape and fitted here, the same way every other runtime
	# hitbox in this room is
	var box := RectangleShape2D.new()
	box.size = Vector2(26.0, 104.0)
	var shape := CollisionShape2D.new()
	shape.shape = box
	add_child(shape)


func _unhandled_input(event: InputEvent) -> void:
	if not _fired or not skippable:
		return
	if event.is_action_pressed("jump") or event.is_action_pressed("interact"):
		_advance = true


func _on_body_entered(body: Node2D) -> void:
	if _fired or not (body is Player):
		return
	_fired = true
	_beat(body as Player)


func _beat(player: Player) -> void:
	# nothing in this room gets to act on the player any more, starting with the
	# room itself: frozen where they stand, and past being touched, so no creature
	# can interrupt this
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	player.invulnerable = true
	player.sprite.play("idle")
	EventManager.hint_changed.emit("")
	# the room's own finish stays where it is, but it gives up its right to end the
	# level: the player is being taken by the one standing in front of it
	var exit := get_parent().get_node_or_null("Exit") as Area2D
	if exit != null:
		exit.set_deferred("monitoring", false)

	AudioManager.play_sfx("sting", -6.0, 0.6)
	AudioManager.set_music_distortion(1.0)

	_glitch = Glitch.new()
	_glitch.intensity = 0.55
	add_child(_glitch)
	_glitch.burst(1.0)

	_layer = CanvasLayer.new()
	_layer.layer = 30
	add_child(_layer)

	_blackout = ColorRect.new()
	_blackout.color = COL_BLACKOUT
	_blackout.modulate.a = 0.0
	_blackout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_blackout)
	_blackout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_make_dlg()
	_kill_hud()

	await _say_all()
	await _push_in(player)
	await _leave()


## The HUD is the only voice this game has ever had and this is where it stops
## being one. Nothing is deleted and nothing is hidden: the plates are shaken, then
## left standing slightly off their marks doing nothing at all, which is worse than
## them being gone. The two that talk — the world switch, and the name of the world
## — lose their words first.
func _kill_hud() -> void:
	var hud := get_parent().get_node_or_null("HUD") as CanvasLayer
	if hud == null or hud.get_child_count() == 0:
		return
	var root := hud.get_child(0) as Control
	if root == null:
		return
	for node in root.get_children():
		var c := node as Control
		if c == null:
			continue
		if c is Label:
			var l := c as Label
			if l.text.begins_with("PRESS Q") or l.text == "PERCEIVED" or l.text == "TRUE":
				l.text = ""
		var home := c.position
		var t := create_tween()
		# it shakes first, because it is still trying to be a HUD
		for i in 5:
			t.tween_property(c, "position", home + Vector2(randf_range(-7.0, 7.0), randf_range(-5.0, 5.0)), 0.045)
		# and then it gives up exactly where it is standing
		t.tween_property(c, "modulate", COL_SHOT, 0.4)


func _make_dlg() -> void:
	var width: float = get_viewport().get_visible_rect().size.x
	_dlg = Label.new()
	_dlg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The same hand the rooms are written in, just not *worn out*: this is the one page
	# in the game where the words are the entire point of the scene, and the ending's
	# hand — rubbed through, thorned, sitting off its baseline — is a hand for a line
	# you are supposed to be unsettled by, not one you are supposed to read. Two percent
	# of it is missing. It is still the game's own alphabet.
	var hand: Node = preload("res://ui/creepy_font.gd").new()
	_dlg.add_theme_font_override("font", hand.call("build", 2, 1) as FontFile)
	hand.free()
	_dlg.add_theme_font_size_override("font_size", 18)
	_dlg.add_theme_color_override("font_color", COL_WORD)
	_dlg.add_theme_color_override("font_outline_color", COL_OUTLINE)
	_dlg.add_theme_constant_override("outline_size", 5)
	# the longest line here is seventy-six characters, which does not fit on one line of
	# a 640-wide screen at this size — it used to run off both ends and get clipped, which
	# is a sentence the player is only ever told the middle of
	_dlg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dlg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dlg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dlg.size = Vector2(width - 48.0, 48.0)
	_dlg.position = Vector2(24.0, LINE_Y)
	_dlg.modulate.a = 0.0
	_layer.add_child(_dlg)

	# The caption. It is a child of the label, one layer *under* it, so it inherits every
	# fade and every twitch the rest of this beat applies to the words — and so the plate
	# and the line it is under can never come apart. Somebody is going to read this while
	# the room is being taken apart around it, and the only thing that has to survive that
	# is the sentence.
	var plate := ColorRect.new()
	plate.color = COL_PLATE
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.z_as_relative = true
	plate.z_index = -1
	plate.position = Vector2(-10.0, 0.0)
	plate.size = Vector2(_dlg.size.x + 20.0, _dlg.size.y)
	_dlg.add_child(plate)


func _say_all() -> void:
	await _sleep(0.5)
	for row in lines:
		var text: String = row.strip_edges()
		if text == "":
			continue
		await _say(text)


## One line, arriving a character at a time in the game's own broken hand. The line
## twitches as it is drawn, because nothing in this game sits still while it is
## speaking, and the player can cut it short.
func _say(text: String) -> void:
	_dlg.text = text
	_dlg.visible_characters = 0
	_dlg.modulate.a = 1.0
	var shown: float = 0.0
	var total: float = float(text.length())
	while shown < total and not _advance:
		shown += CHARS_PER_SECOND * 0.05
		_dlg.visible_characters = int(shown)
		_dlg.position = Vector2(24.0, LINE_Y) + Vector2(randf_range(-JITTER, JITTER), randf_range(-JITTER, JITTER) * 0.5)
		await _sleep(0.05)
	_dlg.visible_characters = -1
	_dlg.position = Vector2(24.0, LINE_Y)
	var held: float = 0.0
	while held < hold and not _advance:
		held += 0.05
		await _sleep(0.05)
	_advance = false
	var out := create_tween()
	out.tween_property(_dlg, "modulate:a", 0.0, 0.35)
	await out.finished


## The picture stops being a picture: the camera goes into it until the pixels are
## the size of the screen, and the light that was carrying the room goes with it.
func _push_in(player: Player) -> void:
	var cam := player.get_node_or_null("Camera") as Camera2D
	if cam == null:
		return
	cam.position_smoothing_enabled = false
	var start: Vector2 = cam.zoom
	AudioManager.play_sfx("whisper", -14.0, 0.5)
	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_property(cam, "zoom", start * zoom_to, zoom_time)
	t.parallel().tween_property(_dlg, "modulate:a", 0.0, zoom_time * 0.5)
	while t.is_running():
		if _advance:
			_advance = false
			t.kill()
			cam.zoom = start * zoom_to
			_dlg.modulate.a = 0.0
			break
		await get_tree().process_frame


## Out through the front of the picture. The ending takes it from here: the two of
## them are pulled together, and the flash at the end of that is the door.
func _leave() -> void:
	_glitch.burst(1.0)
	AudioManager.play_sfx("heartbeat", -2.0, 0.4)
	await _sleep(0.22)
	_dlg.modulate.a = 0.0
	var out := create_tween()
	out.tween_property(_blackout, "modulate:a", 1.0, FADE_OUT)
	await out.finished
	Engine.set_meta("parkour_mode", true)
	get_tree().change_scene_to_file(MERGE_SCENE)


## Waits in small steps so the beat can answer to a key press instead of sitting
## there until it is over. A beat about the player should not be one they are made
## to watch.
func _sleep(seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		var step: float = minf(0.05, left)
		await get_tree().create_timer(step).timeout
		left -= step
