class_name Parkour3D
extends Node3D
## The room the game stops lying in.
##
## This is not a course, and it is deliberately not trying to be one. It is *inside* the
## picture at last: one round temple with a solid floor from wall to wall, one gate, and
## the staff standing in it. Everything here is built from a table or from ParkourHall, so
## the room can be read and tuned as one thing, and it opens in the true world, because
## the true world is what the hall is: the pale one is the picture that has been taken off
## it, and Q is what puts it back on.
##
## The rule the whole room runs on is one sentence long: **nothing in here arrives until
## the staff does.** The hall is empty when the player walks in, the click does nothing,
## and the fight does not exist yet. Picking the staff up is the trigger for all of it —
## the floor opens and the creatures come up out of it, the floor opens *again* and the one
## who owns the room comes up out of it, and the keys line finally admits there is a weapon
## in the player's hand. The staff is not a power-up. It is the door being opened.
##
## What owns the room is a person standing on the floor and not a limb dropping out of the
## ceiling: she comes up through the stone like everything else in here that was waiting,
## she carries her own light and her own weather, and she does two things — she opens the
## fan of blades she keeps behind her and lets four of them go, and she puts her arms up
## and the flies come off her. Both of them are shown before they land. She has a name, a
## bar across the top of the screen, and twenty strikes in her.

## What the room says on arrival, one line at a time, and how long each holds.
@export var entry_lines: PackedStringArray = [
	"YOU'RE REALLY HERE NOW.",
	"THE ONE DOOR OUT OF THIS ROOM IS YOURS, AND IT IS STANDING IN THE GATE.",
]
@export var entry_hold: float = 1.4
@export var skippable: bool = true

const FADE_IN := 0.7

## Where the owner stands and which way round. She comes up well inside the ring, on the
## far side of the middle of the floor from the gate, so that the player who has just taken
## the staff off the gate turns round and finds her already standing there.
const BOSS_AT := Vector3(0.0, 0.0, -7.0)

## The hall's own two colours. The true world is what this room is: a bleeding temple lit
## from the inside, and the stone in it is nearly colourless so that all of the colour can
## be the light — red lanterns, a fire in the gate, three cold shafts through the upper air.
## The false one is the same hall under a picture of paper: the floor stays lit, the stone
## goes white, the cloth drains, and the fog closes in, so the room gets smaller without a
## single thing in it changing shape.
const PALETTE_PERCEIVED := {
	"background": Color(0.86, 0.86, 0.87),
	"ambient": Color(1.00, 0.98, 0.96),
	"ambient_energy": 0.40,
	"sun": Color(1.00, 0.97, 0.93),
	"sun_energy": 0.55,
	"fog": 0.010,
	"fog_color": Color(0.82, 0.82, 0.83),
	"weapon": Color(0.88, 0.90, 0.95),
}
const PALETTE_TRUE := {
	"background": Color(0.016, 0.005, 0.005),
	"ambient": Color(0.52, 0.16, 0.13),
	"ambient_energy": 0.34,
	"sun": Color(1.00, 0.38, 0.30),
	"sun_energy": 0.20,
	"fog": 0.017,
	"fog_color": Color(0.085, 0.017, 0.014),
	"weapon": Color(0.72, 0.42, 0.38),
}

## The room's own HUD, and the bars its speech stands on.
const COL_WORD := Color(0.941, 0.129, 0.145, 0.98)
const COL_OUTLINE := Color(0.015, 0.015, 0.02, 0.95)
const COL_KEYS := Color(0.945, 0.925, 0.870, 0.82)
const COL_PERCEIVED := Color(1.0, 0.98, 0.94, 0.85)
const COL_TRUE := Color(0.55, 0.85, 1.0, 0.85)
const COL_BAR := Color(0.0, 0.0, 0.0, 0.78)

## Her bar, over the top of everything: a name, a black rule, and a red line across it with
## a paler one bleeding along behind it, which is what tells the player a strike landed
## without any number being on the screen.
const BOSS_NAME := "THE ONE WHO OWNS THIS ROOM"
const BAR_W := 320.0
const BAR_H := 10.0
const BAR_AT := Vector2(160.0, 17.0)
const COL_BLOOD := Color(0.74, 0.06, 0.05, 1.0)
const COL_BLOOD_BACK := Color(0.10, 0.02, 0.02, 0.88)
const COL_BLOOD_GHOST := Color(0.88, 0.64, 0.56, 0.50)
const COL_BLOOD_EDGE := Color(0.02, 0.02, 0.03, 0.92)
const GHOST_CHASE := 0.5

var _sun: DirectionalLight3D
var _env: Environment
var _player: ParkourPlayer
var _layer: CanvasLayer
var _narration: Label
var _narration_row: CenterContainer
var _prompt: Label
var _prompt_row: CenterContainer
var _world: Label
var _keys: Label
var _last_bar: CenterContainer
var _hall: ParkourHall
var _staff: ParkourStaff
var _boss: TempleBoss
var _lamps: Array[ColorRect] = []
var _boss_row: Control
var _boss_fill: ColorRect
var _boss_ghost: ColorRect
var _boss_ghost_v: float = BAR_W
var _boss_target: float = BAR_W
## Whether the staff is off its stand: nothing the room does after that is reversible, and
## nothing before it happens twice.
var _armed: bool = false
## Whether the thing that owns the room has been put down, and with it the one door.
var _opened: bool = false
## One tear for the whole room; everything else in here asks it to strike.
var _glitch: Glitch
var _advance: bool = false


func _ready() -> void:
	GameState.current_level = "parkour"
	# This room is not in AREA_SEQUENCE, so the run index is still sitting on the
	# last area — which is exactly what makes AdvanceArea the right win condition
	# here. A run started straight from this scene has to be told the same thing, or
	# finishing would drop the player back near the start of the game.
	var tear: int = GameState.AREA_SEQUENCE.find("res://levels/area_07_the_tear.tscn")
	GameState.area_index = tear if tear >= 0 else GameState.AREA_SEQUENCE.size() - 1
	GameState.set_objective("")
	EventManager.hint_changed.emit("")

	add_to_group("parkour_fx")
	_glitch = Glitch.new()
	# nothing at rest, and barely anything on its own: this room is the one the game
	# stops lying in, so the tear only shows up in here when something is struck
	_glitch.intensity = 0.0
	_glitch.calm_gap = Vector2(6.0, 12.0)
	add_child(_glitch)

	# the hall's own score, and it is a low one: a room the player is walking into has a
	# slower heart than a room they are fighting in (see AudioManager)
	AudioManager.play_music("music_temple")
	AudioManager.set_music_distortion(0.42)

	# the full-screen overlay that brings the room up out of the black is a Control,
	# and a Control eats mouse motion before the player ever sees it: that is what a
	# mouse-look that does not look feels like
	var fade := get_node_or_null("Fade/Rect") as ColorRect
	if fade != null:
		fade.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_sun = get_node_or_null("Sun") as DirectionalLight3D
	var world_env := get_node_or_null("WorldEnvironment") as WorldEnvironment
	_env = world_env.environment if world_env != null else null
	_player = get_tree().get_first_node_in_group("player3d") as ParkourPlayer

	# this room opens in the true world, because it *is* the true world: the picture has
	# been taken off it and what was under the picture is a temple that bleeds. Q puts the
	# picture back on for a while, which is the only thing Q has ever done.
	if RealityManager.is_perceived():
		RealityManager.set_reality(RealityManager.Reality.TRUE, true)

	_build_ground()
	_build_backdrop()
	_build_threats()
	_build_ui()
	RealityManager.reality_changed.connect(_apply_world)
	RealityManager.reality_changed.connect(_react_room)
	_apply_world(RealityManager.current_reality)

	if _player != null:
		_player.set_control(false)
	_arrive()


func _unhandled_input(event: InputEvent) -> void:
	if _player == null or not _player.frozen:
		return
	if event.is_action_pressed("jump") or event.is_action_pressed("interact"):
		_advance = true


## The two bars that move on their own: her health catching up to itself, and nothing else.
func _process(delta: float) -> void:
	if GameState.is_paused:
		return
	if _boss_ghost != null:
		_boss_ghost_v = move_toward(_boss_ghost_v, _boss_target, delta * BAR_W * GHOST_CHASE)
		_boss_ghost.size = Vector2(_boss_ghost_v, BAR_H)


# ── the room ───────────────────────────────────────────────────────────────

## The floor of the hall, out to the wall, and the wall itself. One disc and a ring of
## slabs: there is nowhere in here to fall and nothing to fall through, which is the whole
## difference between this room and the one it replaced. The arena is solid ground.
func _build_ground() -> void:
	var r: float = ParkourHall.R_WALL
	var body := StaticBody3D.new()
	body.name = "Ground"
	body.add_child(_shape(_disc(r), Vector3(0.0, -1.0, 0.0)))
	# the wall, which is not decoration: it is what makes this a room with one door in it
	var sides := 20
	for i in sides:
		var a: float = TAU * float(i) / float(sides)
		var dir := Vector3(cos(a), 0.0, -sin(a))
		# the box is laid so that its local X is the inward direction and its local Z runs
		# along the wall, which is what a Y-rotation by the angle between them does
		var slab := BoxShape3D.new()
		slab.size = Vector3(1.2, 24.0, TAU * r / float(sides) * 1.16)
		var s := _shape(slab, dir * (r + 0.35) + Vector3(0.0, 12.0, 0.0))
		s.rotation.y = a
		body.add_child(s)
	add_child(body)


func _shape(shape: Shape3D, pos: Vector3) -> CollisionShape3D:
	var s := CollisionShape3D.new()
	s.shape = shape
	s.position = pos
	return s


func _disc(radius: float) -> CylinderShape3D:
	var c := CylinderShape3D.new()
	c.radius = radius
	c.height = 2.0
	return c


## The hall the player is standing in, built as one thing by the thing that owns it.
func _build_backdrop() -> void:
	_hall = ParkourHall.new()
	add_child(_hall)


## The two things the room puts in the hall itself. The staff is the door: everything the
## player is about to meet is on the other side of picking it up. And the one who owns the
## room sleeps until then — see TempleBoss.wake.
func _build_threats() -> void:
	_staff = ParkourStaff.new()
	add_child(_staff)
	# standing in the one doorway, a step in front of it, where a person can reach it
	_staff.setup({"x": 0.0, "top": 0.0, "z": ParkourHall.GATE_Z + 2.4})
	_boss = TempleBoss.new()
	add_child(_boss)
	_boss.setup({"x": BOSS_AT.x, "z": BOSS_AT.z, "top": BOSS_AT.y})


## The other half of the world switch: what is hunting the player and how the hall around
## them is painted. The lighting half stays in _apply_world.
func _react_room(reality: int) -> void:
	if _boss != null:
		_boss.react(reality)


## One tear for the whole room rather than a screen shader per prop: everything in here
## that wants to hit the picture asks the room to do it.
func pulse_glitch(amount: float) -> void:
	if _glitch != null:
		_glitch.burst(amount)


# ── the three the flat game kept in its corner ─────────────────────────────

## Built where the flat game's HUD kept them, because the HUD did not survive the room
## before this one. Losing one dims it rather than hiding it: the plates are left standing.
func _build_health() -> void:
	var panel := Control.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = Vector2(596.0, 9.0)
	panel.size = Vector2(40.0, 8.0)
	_layer.add_child(panel)
	for i in ParkourPlayer.MAX_HITS:
		var lamp := ColorRect.new()
		lamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lamp.color = COL_KEYS
		lamp.size = Vector2(7.0, 7.0)
		lamp.position = Vector2(float(i) * 12.0, 0.0)
		panel.add_child(lamp)
		_lamps.append(lamp)
	if _player != null:
		_player.hits_changed.connect(_paint_health)
	_paint_health(0)


func _paint_health(hits_taken: int) -> void:
	for i in _lamps.size():
		var lost: bool = i < hits_taken
		_lamps[i].color = Color(0.24, 0.06, 0.08, 0.5) if lost else COL_KEYS


## The world switch, and it is the same switch it has always been: what the room is lit
## by, and how thick the air in it is. Nothing here is an overlay.
func _apply_world(reality: int) -> void:
	var perceived: bool = reality == RealityManager.Reality.PERCEIVED
	var pal: Dictionary = PALETTE_PERCEIVED if perceived else PALETTE_TRUE
	if _sun != null:
		_sun.light_color = Color(pal["sun"])
		_sun.light_energy = float(pal["sun_energy"])
	if _env != null:
		_env.background_color = Color(pal["background"])
		_env.ambient_light_color = Color(pal["ambient"])
		_env.ambient_light_energy = float(pal["ambient_energy"])
		_env.fog_light_color = Color(pal["fog_color"])
		_env.fog_density = float(pal["fog"])
		# the floor of this room is wet stone, and a wet floor that reflects is most of
		# what makes it read as wet at all
		_env.ssr_enabled = true
	if _player != null:
		_player.tint_body(Color(pal["weapon"]))
	_paint_world_label()


# ── the room's own HUD ─────────────────────────────────────────────────────

func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 10
	add_child(_layer)

	_world = _mk_label(Vector2(16.0, 12.0), Vector2(200.0, 18.0), 13, COL_PERCEIVED, HORIZONTAL_ALIGNMENT_LEFT)
	_keys = _mk_label(Vector2(16.0, 332.0), Vector2(608.0, 18.0), 11, COL_KEYS, HORIZONTAL_ALIGNMENT_CENTER)
	# the keys line does not lie at any point in the room: it leaves the click out until
	# there is something in the player's hand to click with
	_paint_keys()
	# the room talks in captions. Every line it says stands on its own black bar, sized to
	# the line rather than to the screen, so it can be read over a hall that is doing its
	# best to look like something else
	_narration = _caption(Vector2(24.0, 142.0), Vector2(592.0, 32.0), 14, COL_WORD, true)
	_narration_row = _last_bar
	_prompt = _caption(Vector2(24.0, 294.0), Vector2(592.0, 26.0), 12, COL_KEYS, false)
	_prompt_row = _last_bar
	_prompt_row.visible = false
	_build_health()
	_build_boss_bar()
	_paint_world_label()


func _mk_label(pos: Vector2, size: Vector2, size_px: int, col: Color, align: HorizontalAlignment) -> Label:
	var l := Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", COL_OUTLINE)
	l.add_theme_constant_override("outline_size", 3)
	l.horizontal_alignment = align
	l.position = pos
	l.size = size
	_layer.add_child(l)
	return l


## One line of the room's speech: a label inside a bar, so the words are legible over the
## hall. The bar is a container rather than a rectangle because it has to be exactly as
## wide as the sentence and no wider, and a container that hugs its child is the only way
## to get that without measuring text by hand. Returns the label; the row it stands on is
## left in _last_bar, because the line and its bar fade in and out together.
##
## Every piece of it is told not to eat the mouse. A full-width Control with the default
## filter stops mouse motion before the player ever sees it, and that is what a mouse-look
## that does not look feels like.
func _caption(pos: Vector2, size: Vector2, px: int, col: Color, eerie: bool) -> Label:
	var row := CenterContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.position = pos
	row.size = size
	_layer.add_child(row)

	var bar := PanelContainer.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = COL_BAR
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override("panel", style)
	row.add_child(bar)

	var l := Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", COL_OUTLINE)
	l.add_theme_constant_override("outline_size", 4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if eerie:
		# the same damaged hand the rooms are written in: this is the game talking, not
		# a UI
		var hand: Node = preload("res://ui/creepy_font.gd").new()
		l.add_theme_font_override("font", hand.call("build_eerie") as FontFile)
		hand.free()
	bar.add_child(l)
	_last_bar = row
	return l


## Her bar. It is the top of the screen and it is the room itself speaking — a name, a
## black rule under it, a red line across it, and a paler line left behind it that catches
## up a moment later. Nothing in it is a number and nothing in it is a portrait, because
## the only thing the player needs to read at a glance is how much of her is left.
func _build_boss_bar() -> void:
	_boss_row = Control.new()
	_boss_row.name = "BossBar"
	_boss_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_row.position = BAR_AT
	_boss_row.size = Vector2(BAR_W, 34.0)
	_boss_row.modulate.a = 0.0
	_boss_row.visible = false
	_layer.add_child(_boss_row)

	var name_label := Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", COL_WORD)
	name_label.add_theme_color_override("font_outline_color", COL_OUTLINE)
	name_label.add_theme_constant_override("outline_size", 5)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text = BOSS_NAME
	name_label.position = Vector2(0.0, 0.0)
	name_label.size = Vector2(BAR_W, 16.0)
	var hand: Node = preload("res://ui/creepy_font.gd").new()
	name_label.add_theme_font_override("font", hand.call("build_eerie") as FontFile)
	hand.free()
	_boss_row.add_child(name_label)

	var edge := ColorRect.new()
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge.color = COL_BLOOD_EDGE
	edge.position = Vector2(-1.0, 15.0)
	edge.size = Vector2(BAR_W + 2.0, BAR_H + 2.0)
	_boss_row.add_child(edge)

	var back := ColorRect.new()
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.color = COL_BLOOD_BACK
	back.position = Vector2(0.0, 16.0)
	back.size = Vector2(BAR_W, BAR_H)
	_boss_row.add_child(back)

	_boss_ghost = ColorRect.new()
	_boss_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_ghost.color = COL_BLOOD_GHOST
	_boss_ghost.position = Vector2(0.0, 16.0)
	_boss_ghost.size = Vector2(BAR_W, BAR_H)
	_boss_row.add_child(_boss_ghost)

	_boss_fill = ColorRect.new()
	_boss_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_fill.color = COL_BLOOD
	_boss_fill.position = Vector2(0.0, 16.0)
	_boss_fill.size = Vector2(BAR_W, BAR_H)
	_boss_row.add_child(_boss_fill)

	if _boss != null:
		_boss.health_changed.connect(_paint_boss_bar)
		_paint_boss_bar(_boss.health, TempleBoss.HEALTH_MAX)


func _paint_boss_bar(health_left: int, maximum: int) -> void:
	if _boss_fill == null:
		return
	var frac: float = clampf(float(health_left) / maxf(1.0, float(maximum)), 0.0, 1.0)
	_boss_target = BAR_W * frac
	_boss_fill.size = Vector2(_boss_target, BAR_H)


func _show_boss_bar(on: bool) -> void:
	if _boss_row == null:
		return
	var t := create_tween()
	if on:
		_boss_row.visible = true
		t.tween_property(_boss_row, "modulate:a", 1.0, 0.8)
	else:
		t.tween_property(_boss_row, "modulate:a", 0.0, 0.9)
		t.tween_callback(_hide_boss_bar)


func _hide_boss_bar() -> void:
	if _boss_row != null:
		_boss_row.visible = false


func _paint_world_label() -> void:
	if _world == null:
		return
	_world.text = RealityManager.reality_name()
	_world.add_theme_color_override("font_color",
		COL_PERCEIVED if RealityManager.is_perceived() else COL_TRUE)


# ── arriving ───────────────────────────────────────────────────────────────

## The last few seconds the game keeps the player's hands off them: the room comes up out
## of the black, says one thing, and then it is theirs.
func _arrive() -> void:
	var rect := get_node_or_null("Fade/Rect") as ColorRect
	if rect != null:
		var fade := create_tween()
		fade.tween_property(rect, "modulate:a", 0.0, FADE_IN)
		await fade.finished
	await _run_intro(_player)


func _run_intro(player: ParkourPlayer) -> void:
	await _sleep(0.6)
	for row in entry_lines:
		var text: String = row.strip_edges()
		if text == "":
			continue
		_narration.text = text
		var t := create_tween()
		t.tween_property(_narration_row, "modulate:a", 1.0, 0.4)
		await t.finished
		var held: float = 0.0
		while held < entry_hold and not (_advance and skippable):
			held += 0.05
			await _sleep(0.05)
		var cut: bool = _advance and skippable
		_advance = false
		var out := create_tween()
		out.tween_property(_narration_row, "modulate:a", 0.0, 0.35)
		await out.finished
		if cut:
			break
	_advance = false
	_narration.text = ""
	if player != null:
		player.set_control(true)


## Waits in small steps, so a line can be cut short instead of sitting there until it is
## over.
func _sleep(seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		var step: float = minf(0.05, left)
		await get_tree().create_timer(step).timeout
		left -= step


# ── what taking the staff changes ──────────────────────────────────────────

## The player has it. Everything the room was holding back arrives at once: the floor
## opens and the creatures come up out of it, the floor opens again and the one who owns
## the room comes up out of it, her bar comes down on the top of the screen, the keys line
## finally admits there is something to click with — and the room tears once, hard, because
## this is the moment it stops being a walk.
func equip_staff() -> void:
	if _armed:
		return
	# nothing walks the floor with the player any more. What the room was holding back is
	# her, and what she brings with her: the staff is still the door, it just opens on one
	# thing now instead of nine.
	_armed = true
	if _boss != null:
		_boss.wake()
	if _player != null:
		_player.equip_staff()
	_paint_keys()
	_show_boss_bar(true)
	pulse_glitch(0.9)
	AudioManager.play_music("music_boss")
	AudioManager.set_music_distortion(0.26)
	AudioManager.play_sfx("sting", -3.0, 1.15)
	AudioManager.play_sfx("static_burst", -9.0, 0.8)
	_say("IT WAS ONLY EVER WAITING FOR YOU TO BE HOLDING SOMETHING.", 3.0)


## The thing that owns the room has been put down, and the room says so. Everything else
## the room put in here with the player goes down with it, and the one door in the room —
## which has been shut, and shut with a red seam under it, since the player walked in —
## opens.
func boss_down() -> void:
	if _opened:
		return
	_opened = true
	# everything she brought with her goes with her: every fly she summoned off herself is
	# put down the moment she is, wherever it is in the room
	for node in get_tree().get_nodes_in_group("enemy3d"):
		if node is BossFly:
			(node as BossFly).hit()
	_open_exit()
	_show_boss_bar(false)
	pulse_glitch(0.8)
	AudioManager.play_music("music_after")
	AudioManager.set_music_distortion(0.12)
	AudioManager.play_sfx("chime", -6.0, 0.8)
	_say("IT KNOWS YOU NOW. THE DOOR IS OPEN.", 3.4)


func _open_exit() -> void:
	# the door first: the room lights its own way out before anything is allowed through it
	if _hall != null:
		_hall.open_portal()
	var line := get_node_or_null("FinishLine") as Area3D
	if line == null:
		return
	var box := line.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if box != null:
		box.set_deferred("disabled", false)
	line.set_deferred("monitoring", true)


## One line, over the room, for a moment. The intro uses its own slower version of this;
## this one is for something said while the player is already moving.
func _say(text: String, hold: float) -> void:
	if _narration == null or _narration_row == null:
		return
	_narration.text = text
	var t := create_tween()
	t.tween_property(_narration_row, "modulate:a", 1.0, 0.3)
	t.tween_interval(hold)
	t.tween_property(_narration_row, "modulate:a", 0.0, 0.45)


## The room's one-line prompt: what is in front of the player, and what pressing E would
## do about it. Nothing else in the room uses it.
func show_prompt(text: String) -> void:
	if _prompt == null:
		return
	_prompt.text = text
	if _prompt_row != null:
		_prompt_row.visible = text != ""


## The keys line. It does not mention the click until the click does something, which is
## the only honest way to teach a control the room has not given out yet.
func _paint_keys() -> void:
	if _keys == null:
		return
	if _armed:
		_keys.text = "MOUSE LOOKS · CLICK ZAPS · WASD MOVES · SPACE JUMPS · Q SWITCHES · R RESTARTS"
	else:
		_keys.text = "MOUSE LOOKS · WASD MOVES · SPACE JUMPS · Q SWITCHES · E TAKES · R RESTARTS"