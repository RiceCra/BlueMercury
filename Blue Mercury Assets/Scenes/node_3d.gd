extends Node3D

@export var waypoint_marker: PackedScene
@export var tank_root: Node3D  # This will reference your M60A1 Node3D
var tank_body: VehicleBody3D  # This will reference the VehicleBody3D child

func _ready():
	# Automatically find the VehicleBody3D in the tank's children
	if tank_root:
		for child in tank_root.get_children():
			if child is VehicleBody3D:
				tank_body = child
				break
		
		if not tank_body:
			push_error("No VehicleBody3D found in tank hierarchy")

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var ray_length = 1000
		var camera = get_viewport().get_camera_3d()
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * ray_length
		
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		var result = space_state.intersect_ray(query)
		
		if result and tank_body:
			# Place waypoint marker
			var marker = waypoint_marker.instantiate()
			add_child(marker)
			marker.global_position = result.position
			
			# Set tank target
			tank_body.target_position = result.position
			tank_body.has_target = true
