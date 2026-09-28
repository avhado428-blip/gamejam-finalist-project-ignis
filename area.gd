class_name AreaRoot
extends Node2D
## Shared boot logic for every area: name it, set the objective, put the player in
## the TRUE world, swap the sky to match, frame the camera, and fade up from black.
##
## It also gives the place its own voice: a name card that arrives once, and a
## presence that keeps talking to itself while the player is inside it.

@export var area_id: String = ""
@export var objective: String = ""
@export var fade_in: float = 1.8
## The name of this place. Shown once, at the start, and then never again.
@export var area_numeral: String = ""
@export var area_title: String = ""
@export var area_subtitle: String = ""  ## kept as data; the card no longer prints it
@export var presence_enabled: bool = true
## limit_left / limit_top / size.x / size.y for the player's camera.
@export var camera_bounds: Rect2 = Rect2(0, 24, 1280, 360)
@export var music: String = "music_calm"
## 0 = clean, 1 = badly broken. Grows toward the final area.
@export var music_distortion: float = 0.0
## Visible drops: one [centre_x, width] pair per pit in this area, so every hole in
## the floor shows a shaft instead of an absence of tiles.
@export var voids: Array = []
@export var void_top: float = 224.0


func _ready() -> void:
	GameState.current_level = area_id
	# Keep the run's flow index in step with whichever area we actually are, so
	# an area run on its own still hands off to the right next one.
	var index: int = GameState.AREA_SEQUENCE.find(scene_file_path)
	if index >= 0:
		GameState.area_index = index
	GameState.set_objective(objective)

	# Every area begins in the true world.
	RealityManager.set_reality(RealityManager.Reality.TRUE, true)
	RealityManager.reality_changed.connect(_on_reality_changed)
	_apply_sky(RealityManager.current_reality)

	AudioManager.play_music(music)
	AudioManager.set_music_distortion(music_distortion)
	_apply_camera_bounds()
	# make every drop in the floor visible, so a hole reads as a hole
	for v in voids:
		var pair: Vector2 = v
		var shaft := VoidShaft.new()
		shaft.width = pair.y
		shaft.position = Vector2(pair.x, void_top)
		add_child(shaft)
	if fade_in > 0.0:
		# fade *from* near-black: the flash rect starts opaque and eases out
		EventManager.request_flash.emit(Color(0.02, 0.022, 0.03, 1.0), fade_in)
	_announce()


## The place introduces itself, once — its name near the top of the screen, and
## then the room itself, which never speaks but does move.
func _announce() -> void:
	if area_title != "":
		var card := LevelTitle.new()
		card.numeral = area_numeral
		card.title = area_title
		add_child(card)
	if not presence_enabled:
		return

	# How deep into the run we are. The first area is almost still; the last one
	# is barely holding itself together, and everything below scales with this.
	var depth: float = 0.0
	if GameState.AREA_SEQUENCE.size() > 1:
		depth = clampf(float(GameState.area_index) / float(GameState.AREA_SEQUENCE.size() - 1), 0.0, 1.0)

	var presence := Presence.new()
	presence.dread = depth
	add_child(presence)

	var glitch := Glitch.new()
	glitch.intensity = depth * 0.75
	add_child(glitch)

	var ambience := get_node_or_null("Ambience") as Ambience
	if ambience != null:
		ambience.apply_dread(depth)


func _on_reality_changed(new_reality: int) -> void:
	_apply_sky(new_reality)


## The sky plate has to follow the reality too, or the pale world's white backdrop
## shows through the dark one.
func _apply_sky(new_reality: int) -> void:
	var perceived := get_node_or_null("Background/SkyPerceived") as CanvasItem
	var true_sky := get_node_or_null("Background/SkyTrue") as CanvasItem
	if perceived != null:
		perceived.visible = new_reality == RealityManager.Reality.PERCEIVED
	if true_sky != null:
		true_sky.visible = new_reality == RealityManager.Reality.TRUE


func _apply_camera_bounds() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var cam := player.get_node_or_null("Camera") as Camera2D
	if cam == null:
		return
	cam.limit_left = int(camera_bounds.position.x)
	cam.limit_top = int(camera_bounds.position.y)
	cam.limit_right = int(camera_bounds.end.x)
	cam.limit_bottom = int(camera_bounds.end.y)
