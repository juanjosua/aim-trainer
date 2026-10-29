extends SceneTree
## Run: godot --headless -s tests/test_main.gd

var failed := false


func check(ok: bool, what: String) -> void:
	if not ok:
		failed = true
		push_error("FAIL: " + what)


func _initialize() -> void:
	run()


func run() -> void:
	var M := preload("res://main.gd")
	# 1600 DPI at Valorant sens 0.4 is 20.41 cm/360
	var cm_per_360 := 360.0 / M.counts_to_degrees(1, 0.4) / 1600.0 * 2.54
	check(absf(cm_per_360 - 20.41) < 0.01, "sensitivity gives %.2f cm/360" % cm_per_360)

	# movement: finite acceleration, reaches run speed, counter-strafe stops in the same time
	var v: Vector3 = M.step_velocity(Vector3.ZERO, Vector3.RIGHT, 0.05)
	check(v.length() > 0 and v.length() < 6.75, "accelerates, not instant: %.2f m/s" % v.length())
	v = M.step_velocity(Vector3.ZERO, Vector3(1, 0, 1), 1.0)
	check(is_equal_approx(v.length(), 6.75), "diagonal capped at run speed: %.2f" % v.length())
	v = M.step_velocity(v, Vector3.ZERO, 6.75 / M.ACCEL)
	check(v.is_zero_approx(), "releasing keys stops")
	check(M.move_error(0) == 0 and M.move_error(M.ACCURATE_SPEED) == 0, "slow enough is accurate")
	check(is_equal_approx(M.move_error(6.75), M.MOVE_ERROR), "running adds full error")

	var main: Node3D = preload("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame  # _ready runs once the tree starts ticking
	main.bot.set_physics_process(false)

	# straight ahead is the head (eye height == head height)
	await _place_bot(main)
	main.shoot()
	check(main.headshots == 1 and main.kills == 1, "head shot kills")

	# aim 0.6 m low: chest
	await _place_bot(main)
	main.camera.rotation_degrees.x = -rad_to_deg(atan(0.6 / main.bot_distance))
	main.shoot()
	check(main.hits == 2 and main.headshots == 1 and main.bot.health == 110, "body shot does 40")

	# aim at the right leg, 1.2 m below eye height
	await _place_bot(main)
	main.camera.rotation_degrees = Vector3(-rad_to_deg(atan(1.2 / main.bot_distance)), -rad_to_deg(atan(0.1 / main.bot_distance)), 0)
	main.shoot()
	check(main.hits == 3 and main.bot.health == 76, "leg shot does 34")

	# aim far left at the wall: miss, and a first shot lands within FIRST_SHOT_ERROR
	await _place_bot(main)
	main.camera.rotation_degrees = Vector3(0, 30, 0)
	main.shoot()
	check(main.shots == 4 and main.hits == 3, "miss counts as a shot only")
	var wall_range: float = (main.bot_distance + 5) / cos(deg_to_rad(30))
	var first_dy: float = main.marks[-1].global_position.y - main.EYE_HEIGHT
	check(absf(first_dy) < wall_range * tan(deg_to_rad(main.FIRST_SHOT_ERROR)) + 0.01, "first shot error %.3f m" % first_dy)

	# 8th shot of a spray climbs well above the crosshair
	main.spray = 7
	main.shoot()
	var spray_dy: float = main.marks[-1].global_position.y - main.EYE_HEIGHT
	check(spray_dy > wall_range * tan(deg_to_rad(main.RECOIL_UP[-1] - main.MAX_ERROR)), "spray recoil rises %.2f m" % spray_dy)

	print("FAILED" if failed else "ALL PASSED")
	quit(1 if failed else 0)


func _place_bot(main: Node3D) -> void:
	main.bot.position.x = 0
	main.camera.rotation_degrees = Vector3.ZERO
	main.spray = 0  # tests fire instantly, which would otherwise count as one long spray
	await physics_frame
	await physics_frame
