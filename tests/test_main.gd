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

	# aim far left: miss
	main.camera.rotation_degrees = Vector3(0, 30, 0)
	main.shoot()
	check(main.shots == 3 and main.hits == 2, "miss counts as a shot only")

	print("FAILED" if failed else "ALL PASSED")
	quit(1 if failed else 0)


func _place_bot(main: Node3D) -> void:
	main.bot.position.x = 0
	main.camera.rotation_degrees = Vector3.ZERO
	await physics_frame
	await physics_frame
