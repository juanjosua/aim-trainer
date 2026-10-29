extends Node3D

# Valorant turns 0.07 degrees per mouse count at sensitivity 1.0 (same yaw as CS).
const VALORANT_YAW := 0.07
const EYE_HEIGHT := 1.6  # metres; 1 Godot unit = 1 m

# Vandal. All unverified except fire rate; tune by feel against the real game.
const FIRE_INTERVAL := 1.0 / 9.75  # 9.75 rounds/s
const FIRST_SHOT_ERROR := 0.25  # degrees, standing still
const SPRAY_ERROR := 0.15  # extra degrees of error per shot in a spray
const MAX_ERROR := 1.5
const RECOIL_UP := [0.0, 0.2, 0.5, 1.0, 1.6, 2.2, 2.8, 3.2]  # degrees above crosshair per spray shot; last value holds
const RECOVERY_MS := 350  # pause this long and the next shot is a first shot again
const MAX_MARKS := 30

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
var trigger := false
var cooldown := 0.0
var spray := 0  # shots so far in the current spray
var last_shot_ms := -RECOVERY_MS
var marks: Array[Node3D] = []
var mark_mesh := SphereMesh.new()


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

	# back wall catches misses so the spray pattern stays visible
	var wall := StaticBody3D.new()
	wall.position = Vector3(0, 3, -bot_distance - 5)
	var wall_col := CollisionShape3D.new()
	wall_col.shape = BoxShape3D.new()
	wall_col.shape.size = Vector3(40, 6, 0.2)
	wall.add_child(wall_col)
	var wall_mesh := MeshInstance3D.new()
	wall_mesh.mesh = BoxMesh.new()
	wall_mesh.mesh.size = wall_col.shape.size
	wall.add_child(wall_mesh)
	add_child(wall)

	mark_mesh.radius = 0.03
	mark_mesh.height = 0.06
	mark_mesh.material = StandardMaterial3D.new()
	mark_mesh.material.albedo_color = Color.BLACK

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
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			trigger = false
		elif captured:
			trigger = true
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED  # this click only captures, it doesn't fire
	elif event.is_action_pressed("ui_cancel"):
		trigger = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	cooldown -= delta
	if not trigger:
		cooldown = maxf(cooldown, 0.0)
	elif cooldown <= 0.0:
		shoot()
		cooldown += FIRE_INTERVAL  # += keeps the average rate exact despite frame timing


# shortcut: Vandal only, no moving inaccuracy (the player can't move yet), recoil resets
# fully after RECOVERY_MS instead of decaying; add both with player movement.
func shoot() -> void:
	var now := Time.get_ticks_msec()
	if now - last_shot_ms > RECOVERY_MS:
		spray = 0
	last_shot_ms = now
	shots += 1

	# Valorant recoil moves the bullets, not the camera: offset the ray from the crosshair.
	var error := minf(FIRST_SHOT_ERROR + SPRAY_ERROR * spray, MAX_ERROR) * sqrt(randf())  # uniform over the disc
	var angle := randf() * TAU
	var up: float = RECOIL_UP[mini(spray, RECOIL_UP.size() - 1)] + error * sin(angle)
	var side := error * cos(angle)
	spray += 1
	var aim := camera.global_basis * Basis.from_euler(Vector3(deg_to_rad(up), deg_to_rad(side), 0))

	var from := camera.global_position
	var to := from - aim.z * 200.0
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
	if hit:
		_mark(hit)
	if hit and hit.collider.has_meta("part"):
		hits += 1
		var part: String = hit.collider.get_meta("part")
		if part == "head":
			headshots += 1
		if bot.hit(part):
			kills += 1
	_update_hud()


## Leaves a bullet mark; parented to what was hit so marks on the bot move with it.
func _mark(hit: Dictionary) -> void:
	var mark := MeshInstance3D.new()
	mark.mesh = mark_mesh
	hit.collider.add_child(mark)
	mark.global_position = hit.position
	marks.append(mark)
	if marks.size() > MAX_MARKS:
		marks.pop_front().queue_free()


func _update_hud() -> void:
	var acc := 100.0 * hits / shots if shots else 0.0
	hud.text = "Kills %d   Shots %d   Hits %d (%.0f%%)   Headshots %d\nEsc: free mouse   Click: capture   Hold: spray" % [kills, shots, hits, acc, headshots]
