extends CharacterBody2D

@export var mouse_sensitivity: float = 0.25
@export var max_reach: float = 120.0 
@export var drag_strength: float = 10.0

# --- NEW: Fixes the 90-degree offset ---
# If your character is facing the wrong way, change this to -90, 0, 90, or 180 in the Inspector.
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

func _physics_process(delta):
	if Input.is_action_just_pressed("click"):
		is_grabbing = true
		grab_anchor_global = hand_target.global_position

	if Input.is_action_just_released("click"):
		is_grabbing = false

	if is_grabbing:
		hand_target.global_position = grab_anchor_global
		var desired_shoulder_pos = grab_anchor_global - virtual_mouse_local
		var shoulder_offset = shoulder.global_position - global_position
		var desired_body_pos = desired_shoulder_pos - shoulder_offset
		velocity = (desired_body_pos - global_position) * drag_strength
	else:
		hand_target.global_position = shoulder.global_position + virtual_mouse_local
		velocity = velocity.move_toward(Vector2.ZERO, 10000 * delta)
		
	# --- UPDATED: Fixes the spinning ---
	# Increased the threshold from 5.0 to 50.0. 
	# Now it only rotates if the body is actually moving at a decent speed.
	if velocity.length() > 50.0:
		# Calculate the momentum angle and add our offset (converted to radians)
		var target_rotation = velocity.angle() + deg_to_rad(sprite_rotation_offset)
		
		# Smoothly rotate towards the target
		rotation = lerp_angle(rotation, target_rotation, 15.0 * delta)
		
	move_and_slide()
