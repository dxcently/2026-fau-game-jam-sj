extends CharacterBody2D

# --- Variables ---
@export var speed: float = 100.0
@export var change_direction_time: float = 2.0

@onready var trigger_area: Area2D = $Trigger
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

var current_direction: Vector2 = Vector2.ZERO
var time_passed: float = 0.0


func _ready() -> void:
	# Randomize the seed so it's different every time you play
	randomize()
	_pick_random_direction()

	# Connect the Area2D signal via code so you don't have to do it in the editor
	trigger_area.body_entered.connect(_on_trigger_body_entered)


func _physics_process(delta: float) -> void:
	time_passed += delta

	# Wander randomly based on the timer
	if time_passed >= change_direction_time:
		_pick_random_direction()

	# Apply velocity
	velocity = current_direction * speed
	move_and_slide()

	# Steer away from walls:
	# If he bumps into a collision shape (like a wall), bounce off it
	if is_on_wall():
		var collision = get_last_slide_collision()
		if collision:
			# Bounce the current direction off the wall's normal
			current_direction = current_direction.bounce(collision.get_normal())
			time_passed = 0.0  # Reset the timer so he doesn't immediately turn back


func _pick_random_direction() -> void:
	# Pick a random angle (TAU is 2 * PI, representing a full circle)
	var random_angle = randf() * TAU
	current_direction = Vector2(cos(random_angle), sin(random_angle)).normalized()
	time_passed = 0.0


func _on_trigger_body_entered(body: Node2D) -> void:
	# Ignore the NPC itself so it doesn't trigger its own sound
	if body == self:
		return

	# Check if the body is a TileMap
	# (In Godot 4.3+, TileMap is being replaced by TileMapLayer, so we check both just in case)
	var is_tilemap = body is TileMap or body.get_class() == "TileMapLayer"

	# If it's a non-tilemap object, yell at them
	if not is_tilemap:
		# Check if it's already playing so it doesn't restart the sound every frame
		# if multiple bodies enter at once
		if not audio_player.playing:
			audio_player.play()
