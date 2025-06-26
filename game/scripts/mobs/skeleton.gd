extends CharacterBody2D

const SPEED = 100
const ATTACK_RNG = 50
const ATTACK_DMG = 10
var health = 100
var is_chasing = false
var is_attacking = false
var is_taking_damage = false
var target = null

@onready var anim = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	if is_attacking or is_taking_damage or !is_alive():
		return

	var player = get_node_or_null("../../Player/Player")
	if player == null:
		return

	var position_delta = (player.position - self.position)

	if position_delta.length() <= ATTACK_RNG:
		is_chasing = false
	elif target != null:
		is_chasing = true

	var direction = position_delta.normalized()
	if is_chasing:
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	if velocity.length() > 0:
		anim.play("Walk")
		anim.flip_h = velocity.x < 0
	else:
		anim.play("Idle")

	if target != null and !is_chasing and target.is_alive():
		attack()

func _on_detector_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		is_chasing = true
		target = body

func _on_detector_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		is_chasing = false
		target = null

func is_alive():
	return health > 0

func death():
	health = 0
	anim.play("Death")

func take_damage(damage: int = 0):
	if !is_alive():
		return
	health -= damage
	is_taking_damage = true
	anim.play("TakeDamage")
	if !is_alive():
		death()
	print("skeleton health: ", health)

func attack():
	is_attacking = true
	anim.play("Attack")
	if target != null:
		target.take_damage(ATTACK_DMG)

func _on_animated_sprite_2d_animation_finished() -> void:
	is_attacking = false
	is_taking_damage = false
	if !is_alive():
		destroy()

func destroy():
	queue_free()
