extends VehicleBody3D

# Movement parameters
@export var engine_force_max = 400.0
@export var brake_force = 5.0
@export var steering_limit = 0.4  # About 23 degrees
@export var steering_speed = 1.0
@export var stopping_distance = 2.0

# Steering properties (VehicleBody3D built-ins)
var steering_input = 0.0  # Must declare this for custom steering
var throttle_input = 0.0   # Optional: for more control

# Navigation
var target_position: Vector3 = Vector3.ZERO
var has_target: bool = false

func _physics_process(delta):
	if has_target:
		navigate_to_target(delta)  # Pass delta to the function

func navigate_to_target(delta: float):  # Add delta parameter
	var to_target = target_position - global_transform.origin
	var distance = to_target.length()
	
	if distance <= stopping_distance:
		stop_movement()
		return
	
	var direction = to_target.normalized()
	var forward = -global_transform.basis.z.normalized()
	
	# Calculate steering angle
	var target_steering = forward.signed_angle_to(direction, Vector3.UP)
	target_steering = clamp(target_steering, -steering_limit, steering_limit)
	
	# Smooth steering transition
	steering_input = move_toward(steering_input, target_steering, steering_speed * delta)
	
	# Apply movement
	engine_force = engine_force_max
	brake = 0.0

func stop_movement():
	engine_force = 0.0
	brake = brake_force
	steering_input = 0.0
	has_target = false

func set_target(position: Vector3):
	target_position = position
	has_target = true
	print("New target set: ", position)
