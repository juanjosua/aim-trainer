extends Node3D
## A stickman bot that ADAD-strafes and sometimes stops, like a player peeking.

const RUN_SPEED := 5.4  # Valorant run speed with a rifle (Vandal), m/s; 6.75 is knife-out
const ACCEL := 40.0  # m/s^2, full speed or a full stop in ~0.14 s; unverified, shared with the player
const STRIDE := 1.0  # metres covered per two side steps
const LEG_SPREAD := 25.0  # degrees each leg swings out at full run speed
const MAX_HEALTH := 150  # 100 HP + full shields
const DAMAGE := {"head": 160, "body": 40, "legs": 34}  # Vandal: head one-tap, 4 body shots

@export var lane := 4.0  # strafes within +-lane metres of centre

var health := MAX_HEALTH
var dir := 1.0
var turn_timer := 0.0
var velocity := 0.0  # along x
var phase := 0.0
var hips: Array[Node3D] = []  # leg pivots, left then right


# Each limb's hitbox is exactly its visible capsule; arms count as body, as in Valorant.
func _ready() -> void:
	_add_part("head", Vector3(0, 1.6, 0), 0.15)
	_add_part("body", Vector3(0, 1.135, 0), 0.15, 0.57)
	_add_part("body", Vector3(-0.24, 1.11, 0), 0.05, 0.55)
	_add_part("body", Vector3(0.24, 1.11, 0), 0.05, 0.55)
	for x in [-0.1, 0.1]:
		var hip := Node3D.new()  # legs swing from the hip, not their middle
		hip.position = Vector3(x, 0.85, 0)
		add_child(hip)
		_add_part("legs", Vector3(0, -0.425, 0), 0.08, 0.85, hip)
		hips.append(hip)


## height 0 makes a sphere, otherwise a vertical capsule of that total height.
func _add_part(part: String, pos: Vector3, radius: float, height := 0.0, parent: Node3D = self) -> void:
	var collider := StaticBody3D.new()
	collider.position = pos
	collider.set_meta("part", part)
	var col := CollisionShape3D.new()
	var mesh := MeshInstance3D.new()
	if height == 0.0:
		col.shape = SphereShape3D.new()
		col.shape.radius = radius
		mesh.mesh = SphereMesh.new()
		mesh.mesh.radius = radius
		mesh.mesh.height = radius * 2
	else:
		col.shape = CapsuleShape3D.new()
		col.shape.radius = radius
		col.shape.height = height
		mesh.mesh = CapsuleMesh.new()
		mesh.mesh.radius = radius
		mesh.mesh.height = height
	mesh.material_override = StandardMaterial3D.new()
	mesh.material_override.albedo_color = Color.ORANGE if part == "head" else Color.CRIMSON
	collider.add_child(col)
	collider.add_child(mesh)
	parent.add_child(collider)


func _physics_process(delta: float) -> void:
	turn_timer -= delta
	if absf(position.x) > lane:
		dir = -signf(position.x)
	elif turn_timer <= 0:
		dir = [-1.0, 0.0, 1.0].pick_random()  # 0 = stopped, the moment a real player shoots
		turn_timer = randf_range(0.2, 0.9)
	velocity = move_toward(velocity, dir * RUN_SPEED, ACCEL * delta)
	position.x += velocity * delta

	# side-step gait: legs take turns swinging out, so one foot is always planted; wider the faster it moves
	phase += absf(velocity) * delta / STRIDE * TAU
	var swing := deg_to_rad(LEG_SPREAD) * sin(phase) * absf(velocity) / RUN_SPEED
	hips[0].rotation.z = -maxf(swing, 0.0)
	hips[1].rotation.z = maxf(-swing, 0.0)


## Returns true if this hit killed the bot.
func hit(part: String) -> bool:
	health -= DAMAGE[part]
	if health > 0:
		return false
	health = MAX_HEALTH
	position.x = randf_range(-lane, lane)
	return true
