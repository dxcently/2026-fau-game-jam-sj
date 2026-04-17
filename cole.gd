extends CharacterBody2D

@export var mouse_sensitivity: float = 0.25
@export var max_reach: float = 120.0 
@export var drag_strength: float = 10.0 # How tight the body snaps to your mouse pulls

@onready var shoulder = $Arm/Shoulder
@onready var hand_target = $HandTarget

var is_grabbing: bool = false
var grab_anchor_global: Vector2
var virtual_mouse_local: Vector2 = Vector2(0, 50) 

func _ready():
	hand_target.top_level = true
	# Capture the mouse so it doesn't leave the window
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# We now track mouse motion AT ALL TIMES, even when grabbing!
	if event is InputEventMouseMotion:
		# Update the intended hand position relative to the shoulder
		virtual_mouse_local += event.relative * mouse_sensitivity
		
		# Clamp the reach so the arm never breaks its socket
		if virtual_mouse_local.length() > max_reach:
			virtual_mouse_local = virtual_mouse_local.normalized() * max_reach

func _physics_process(delta):
	if Input.is_action_just_pressed("click"):
		is_grabbing = true
		# Lock the exact world coordinate we are gripping
		grab_anchor_global = hand_target.global_position

	if Input.is_action_just_released("click"):
		is_grabbing = false

	if is_grabbing:
		# 1. Keep the physical hand locked to the floor
		hand_target.global_position = grab_anchor_global
		
		# 2. Calculate where the shoulder NEEDS to be based on how far you pulled your mouse
		var desired_shoulder_pos = grab_anchor_global - virtual_mouse_local
		
		# 3. Calculate where the body needs to be to put the shoulder in that spot
		var shoulder_offset = shoulder.global_position - global_position
		var desired_body_pos = desired_shoulder_pos - shoulder_offset
		
		# 4. Spring the body towards that desired position 
		velocity = (desired_body_pos - global_position) * drag_strength
		
	else:
		# Freely move the hand around while not grabbing
		hand_target.global_position = shoulder.global_position + virtual_mouse_local
		
		# Smoothly slide to a stop when we let go (friction)
		velocity = velocity.move_toward(Vector2.ZERO, 10000 * delta)
		
	move_and_slide()
