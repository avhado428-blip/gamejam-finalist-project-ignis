extends Node
## GameState — global run state (level, objective, pause). FINAL NAME.
## The objective text here is what the HUD displays, and it is always TRUE.

signal objective_changed(text: String)
signal paused_changed(paused: bool)
signal area_started(index: int, path: String)

## The built run, in order. Areas are advanced by AreaExit, never by level code.
const AREA_SEQUENCE: Array[String] = [
	"res://levels/area_01_awakening.tscn",
	"res://levels/area_02_false_path.tscn",
	"res://levels/area_03_other_side.tscn",
	"res://levels/area_04_distortion.tscn",
	"res://levels/area_05_the_lie.tscn",
	"res://levels/area_06_false_real.tscn",
	"res://levels/area_07_the_tear.tscn",
]

var current_level: String = ""
var current_objective: String = ""
var is_paused: bool = false
var run_time: float = 0.0
var deaths: int = 0
var area_index: int = 0


func _process(delta: float) -> void:
	if not is_paused:
		run_time += delta


func set_objective(text: String) -> void:
	if text == current_objective:
		return
	current_objective = text
	objective_changed.emit(text)
	EventManager.objective_changed.emit(text)


func set_paused(value: bool) -> void:
	if value == is_paused:
		return
	is_paused = value
	get_tree().paused = value
	paused_changed.emit(value)


func toggle_pause() -> void:
	set_paused(not is_paused)


# ── area flow ──────────────────────────────────────────────────────────────

func start_area(index: int) -> void:
	area_index = clampi(index, 0, AREA_SEQUENCE.size() - 1)
	# area one means a new run, so the tally the credits report starts here too
	if area_index == 0:
		deaths = 0
		run_time = 0.0
	CheckpointManager.reset()
	set_paused(false)
	get_tree().change_scene_to_file(AREA_SEQUENCE[area_index])
	area_started.emit(area_index, AREA_SEQUENCE[area_index])


func advance_area() -> void:
	if area_index + 1 < AREA_SEQUENCE.size():
		start_area(area_index + 1)
	else:
		# the last area hands off to the ending, not back to the title
		CheckpointManager.reset()
		set_paused(false)
		get_tree().change_scene_to_file("res://levels/ending.tscn")


func start_credits() -> void:
	CheckpointManager.reset()
	set_paused(false)
	get_tree().change_scene_to_file("res://ui/credits.tscn")


func restart_area() -> void:
	start_area(area_index)
