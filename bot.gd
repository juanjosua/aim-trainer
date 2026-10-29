extends Node3D
## A bot that ADAD-strafes and sometimes stops, like a player peeking.

const RUN_SPEED := 6.75  # Valorant run speed with a rifle, m/s
const MAX_HEALTH := 150  # 100 HP + full shields
const HEAD_DAMAGE := 160  # Vandal head: one tap
const BODY_DAMAGE := 40  # Vandal body: four shots

@export var lane := 4.0  # strafes within +-lane metres of centre

var health := MAX_HEALTH
var dir := 1.0
var turn_timer := 0.0


func _ready() -> void:
	var body := BoxShape3D.new()
	body.size = Vector3(0.6, 1.4, 0.4)
	_add_part("body", body, 0.7, Color.CRIMSON)
	var head := SphereShape3D.new()
	head.radius = 0.15
	_add_part("head", head, 1.6, Color.ORANGE)


func _add_part(part: String, shape: Shape3D, y: float, color: Color) -> void:
	var collider := StaticBody3D.new()
	collider.position.y = y
	collider.set_meta("part", part)
	var col := CollisionShape3D.new()
	col.shape = shape
	collider.add_child(col)
	var mesh := MeshInstance3D.new()
	mesh.mesh = shape.get_debug_mesh()
	mesh.material_override = StandardMaterial3D.new()
	mesh.material_override.albedo_color = color
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
func hit(is_head: bool) -> bool:
	health -= HEAD_DAMAGE if is_head else BODY_DAMAGE
	if health > 0:
		return false
	health = MAX_HEALTH
	position.x = randf_range(-lane, lane)
	return true
