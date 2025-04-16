extends VehicleBody3D

@export var target_position: Vector3 = Vector3.ZERO
@export var rotation_threshold: float = 2.0  # Degrees
@export var arrival_distance: float = 0.5
@export var rotation_speed: float = 200000.0
@export var move_speed: float = 30000.0

enum State { ROTATING, MOVING, IDLE }
var current_state: State = State.IDLE
var left_tracks: Array
var right_tracks: Array
var has_target: bool = false

func _ready():
	# Collect wheel references - organize wheels in "LeftTrack" and "RightTrack" nodes
	left_tracks = [$LeftWheel1, $LeftWheel2, $LeftWheel3, $LeftWheel4, $LeftWheel5, $LeftWheel6]
	right_tracks = [$RightWheel1, $RightWheel2, $RightWheel3, $RightWheel4, $RightWheel5, $RightWheel6]

func _physics_process(delta):
	if current_state == State.IDLE:
		return
	
	match current_state:
		State.ROTATING:
			handle_rotation(delta)
		State.MOVING:
			handle_movement(delta)

func set_target_position(new_target: Vector3):
	brake = 0
	target_position = new_target
	current_state = State.ROTATING

func handle_rotation(delta):
	var to_target = target_position - global_transform.origin
	to_target.y = 0  # Ignore vertical difference
	
	if to_target.length() < arrival_distance:
		current_state = State.IDLE
		return
	
	var forward = global_transform.basis.x  # Forward direction in 3D
	forward.y = 0
	forward = forward.normalized()
	
	var target_dir = to_target.normalized()
	var angle_diff = forward.angle_to(target_dir)
	var cross = forward.cross(target_dir)
	
	print("---")
	print("Angle difference: ", rad_to_deg(angle_diff))
	print("Raw Angle: ", angle_diff)
	print("Rotation Threshhold: ", deg_to_rad(rotation_threshold))
	#if angle_diff > deg_to_rad(rotation_threshold):
	if rad_to_deg(angle_diff) + deg_to_rad(rotation_threshold) <= 180:
		# Determine rotation direction
		var rotation_direction = sign(cross.y)
		
		# Apply differential steering
		var rotation_force = rotation_speed * delta
		apply_track_forces(rotation_force * rotation_direction, -rotation_force * rotation_direction)
	else:
		# Aligned with target, start moving
		print("moving trigger")
		current_state = State.MOVING
		apply_track_forces(0, 0)  # Stop rotation

func handle_movement(delta):
	var to_target = target_position - global_transform.origin
	to_target.y = 0
	
	if to_target.length() < arrival_distance:
		brake = 5
		apply_track_forces(0, 0)
		current_state = State.IDLE
		return
	
	# Maintain forward movement
	var current_forward = global_transform.basis.x
	var forward_speed = move_speed * delta
	apply_track_forces(forward_speed, forward_speed)
	
	# Optional: Add minor course corrections
	var target_dir = to_target.normalized()
	var angle_diff = current_forward.angle_to(target_dir)
	var cross = current_forward.cross(target_dir)
	
	if angle_diff > deg_to_rad(rotation_threshold):
		# Small adjustment while moving
		var adjustment = move_speed * 0.2 * sign(cross.y) * delta
		apply_track_forces(forward_speed - adjustment, forward_speed + adjustment)

func apply_track_forces(left_force: float, right_force: float):
	# Apply forces to all wheels in each track
	for wheel in left_tracks:
		wheel.engine_force = left_force
	for wheel in right_tracks:
		wheel.engine_force = right_force

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Example: Set target position on click
		var ray_length = 1000
		var camera = get_viewport().get_camera_3d()
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * ray_length
		var query = PhysicsRayQueryParameters3D.create(from, to)
		var result = get_world_3d().direct_space_state.intersect_ray(query)
		
		if result:
			set_target_position(result.position)
