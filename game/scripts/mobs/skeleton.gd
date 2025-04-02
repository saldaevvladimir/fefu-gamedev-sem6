extends CharacterBody2D

const SPEED = 100
const ATTACK_RNG = 80
const ATTACK_DMG = 10

var chase = false

@onready var anim = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	var player = $"../../Player/player"
	var position_delta = (player.position - self.position)
	var direction = position_delta.normalized()
	if chase:
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()
	
	# walk / idle animation
	if velocity.length() > 0:
		anim.play("Walk")
		anim.flip_h = velocity.x < 0
	else:
		anim.play("Idle")


func _on_detector_body_entered(body: Node2D) -> void:
	if body.name == "player":
		chase = true

func _on_detector_body_exited(body: Node2D) -> void:
	if body.name == "player":
		chase = false
