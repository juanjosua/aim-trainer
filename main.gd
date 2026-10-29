extends Node3D

# Valorant turns 0.07 degrees per mouse count at sensitivity 1.0 (same yaw as CS).
const VALORANT_YAW := 0.07
const EYE_HEIGHT := 1.6  # metres; 1 Godot unit = 1 m

@export var sensitivity := 0.4  # your in-game Valorant sensitivity
@export var bot_distance := 15.0

var camera: Camera3D
var bot: Node3D
var hud: Label
var yaw := 0.0
var pitch := 0.0
var shots := 0
var hits := 0
var headshots := 0
var kills := 0


static func counts_to_degrees(counts: float, sens: float) -> float:
	return counts * VALORANT_YAW * sens


func _ready() -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, 30, 0)
	add_child(light)

	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	floor_mesh.mesh.size = Vector2(40, 40)
	add_child(floor_mesh)

	camera = Camera3D.new()
	camera.position.y = EYE_HEIGHT
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.fov = 103  # Valorant's fixed horizontal FOV
	add_child(camera)

	bot = preload("res://bot.gd").new()
	bot.position.z = -bot_distance
	add_child(bot)

	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.grow_horizontal = Control.GROW_DIRECTION_BOTH
	crosshair.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(crosshair)

	hud = Label.new()
	hud.position = Vector2(12, 12)
	add_child(hud)
	_update_hud()

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and captured:
		# screen_relative is unscaled by window size, so 1 unit = 1 mouse count
		yaw -= counts_to_degrees(event.screen_relative.x, sensitivity)
		pitch = clampf(pitch - counts_to_degrees(event.screen_relative.y, sensitivity), -89, 89)
		camera.rotation_degrees = Vector3(pitch, yaw, 0)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if captured:
			shoot()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# shortcut: perfect first-shot accuracy, no spread/recoil/fire rate yet; add per-weapon numbers next.
func shoot() -> void:
	shots += 1
	var from := camera.global_position
	var to := from - camera.global_basis.z * 200.0
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
	if hit and hit.collider.has_meta("part"):
		hits += 1
		var is_head: bool = hit.collider.get_meta("part") == "head"
		if is_head:
			headshots += 1
		if bot.hit(is_head):
			kills += 1
	_update_hud()


func _update_hud() -> void:
	var acc := 100.0 * hits / shots if shots else 0.0
	hud.text = "Kills %d   Shots %d   Hits %d (%.0f%%)   Headshots %d\nEsc: free mouse   Click: capture/shoot" % [kills, shots, hits, acc, headshots]
