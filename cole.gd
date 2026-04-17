extends CharacterBody2D

@export var mouse_sensitivity: float = 0.25
@export var max_reach: float = 120.0 
@export var drag_strength: float = 10.0
@export var max_drag_speed: float = 1500.0
@export var sprite_rotation_offset: float = 90.0 

@onready var shoulder = $Arm/Shoulder
@onready var hand_target = $HandTarget

var is_grabbing: bool = false
var grab_anchor_global: Vector2
var virtual_mouse_local: Vector2 = Vector2(0, 50) 

func _ready():
	hand_target.top_level = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		virtual_mouse_local += event.relative * mouse_sensitivity
		if virtual_mouse_local.length() > max_reach:
			virtual_mouse_local = virtual_mouse_local.normalized() * max_reach

# --- NEW: Helper function to clean up release logic ---
func _release_grip():
	is_grabbing = false
	# Tension Reset: Lock the ghost mouse to the exact physical distance
	virtual_mouse_local = grab_anchor_global - shoulder.global_position
	if virtual_mouse_local.length() > max_reach:
		virtual_mouse_local = virtual_mouse_local.normalized() * max_reach
	$Arm/Shoulder/Hand/CarpetNoise.play()


func _physics_process(delta):
	if Input.is_action_just_pressed("click"):
		is_grabbing = true
		grab_anchor_global = hand_target.global_position
		$Arm/Shoulder/Hand/CarpetNoise.play()

	# If we let go of the mouse, drop the grip
	if Input.is_action_just_released("click") and is_grabbing:
		_release_grip()

	if is_grabbing:
		# --- NEW: Grip Break ---
		# If the arm stretches past its maximum reach, the grip snaps automatically.
		# (I added a tiny 1.05 buffer so physics jitter doesn't unfairly break your grip)
		if shoulder.global_position.distance_to(grab_anchor_global) > (max_reach * 1.05):
			_release_grip()
		else:
			# Normal grabbing logic
			hand_target.global_position = grab_anchor_global
			var desired_shoulder_pos = grab_anchor_global - virtual_mouse_local
			var shoulder_offset = shoulder.global_position - global_position
			var desired_body_pos = desired_shoulder_pos - shoulder_offset
			
			velocity = (desired_body_pos - global_position) * drag_strength
			velocity = velocity.limit_length(max_drag_speed)
		
	# We use "if not is_grabbing" instead of "else" so that if the grip breaks 
	# in the block above, this code runs immediately on the same frame.
	if not is_grabbing:
		hand_target.global_position = shoulder.global_position + virtual_mouse_local
		velocity = velocity.move_toward(Vector2.ZERO, 10000 * delta)
		
	if velocity.length() > 50.0:
		var target_rotation = velocity.angle() + deg_to_rad(sprite_rotation_offset)
		rotation = lerp_angle(rotation, target_rotation, 15.0 * delta)
		
	move_and_slide()
