extends Node3D
## A stickman bot that ADAD-strafes and sometimes stops, like a player peeking.

const RUN_SPEED := 6.75  # Valorant run speed with a rifle, m/s
const MAX_HEALTH := 150  # 100 HP + full shields
const DAMAGE := {"head": 160, "body": 40, "legs": 34}  # Vandal: head one-tap, 4 body shots

@export var lane := 4.0  # strafes within +-lane metres of centre

var health := MAX_HEALTH
var dir := 1.0
var turn_timer := 0.0


# Each limb's hitbox is exactly its visible capsule; arms count as body, as in Valorant.
func _ready() -> void:
	_add_part("head", Vector3(0, 1.6, 0), 0.15)
	_add_part("body", Vector3(0, 1.135, 0), 0.15, 0.57)
	_add_part("body", Vector3(-0.24, 1.11, 0), 0.05, 0.55)
	_add_part("body", Vector3(0.24, 1.11, 0), 0.05, 0.55)
	_add_part("legs", Vector3(-0.1, 0.425, 0), 0.08, 0.85)
	_add_part("legs", Vector3(0.1, 0.425, 0), 0.08, 0.85)


## height 0 makes a sphere, otherwise a vertical capsule of that total height.
func _add_part(part: String, pos: Vector3, radius: float, height := 0.0) -> void:
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
	add_child(collider)


# shortcut: instant direction changes, no acceleration; add Valorant's accel/decel when tuning feel.
func _physics_process(delta: float) -> void:
	turn_timer -= delta
	if absf(position.x) > lane:
		dir = -signf(position.x)
	elif turn_timer <= 0:
		dir = [-1.0, 0.0, 1.0].pick_random()  # 0 = stopped, the moment a real player shoots
		turn_timer = randf_range(0.2, 0.9)
	position.x += dir * RUN_SPEED * delta


## Returns true if this hit killed the bot.
func hit(part: String) -> bool:
	health -= DAMAGE[part]
	if health > 0:
		return false
	health = MAX_HEALTH
	position.x = randf_range(-lane, lane)
	return true
