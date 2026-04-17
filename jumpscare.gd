extends Area2D

# Get references to the child nodes
@onready var jumpscare_image = $Sprite2D
@onready var sound_effect = $AudioStreamPlayer2D

func _ready():
	# Ensure the image is hidden when the game starts
	jumpscare_image.visible = false
	
	# Connect the signal (you can also do this in the editor Node tab)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Check if the object entering is in the "player" group
	if body.is_in_group("player"):
		trigger_jumpscare()

func trigger_jumpscare():
	# 1. Show the image and play the sound
	jumpscare_image.visible = true
	sound_effect.play()
	
	# 2. Wait for 1 second
	await get_tree().create_timer(1.0).timeout
	
	# 3. Hide the image again
	jumpscare_image.visible = false
	
	# Optional: Delete the jumpscare node so it doesn't trigger again
	# queue_free()
