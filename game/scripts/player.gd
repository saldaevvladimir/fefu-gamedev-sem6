extends CharacterBody2D

const SPEED = 250
# usage not implemented yet
const HEALTH = 100
const SWORD1_DMG = 30
const SWORD2_DMG = 50
const BOW_DMG = 20

@onready var anim = $AnimatedSprite2D

func _physics_process(delta):
	# movement
	velocity = Vector2.ZERO
	
	if Input.is_action_pressed("Right"):
		velocity.x += SPEED
		anim.flip_h = false
	if Input.is_action_pressed("Left"):
		velocity.x += -SPEED
		anim.flip_h = true
	if Input.is_action_pressed("Up"):
		velocity.y += -SPEED
	if Input.is_action_pressed("Down"):
		velocity.y += SPEED
		
	velocity = velocity.normalized() * SPEED
	move_and_slide()
	
	# walk / idle animation
	if velocity.length() > 0:
		anim.play("Walk")
	else:
		anim.play("Idle")
	
	# attack animations
	if Input.is_action_just_pressed("Sword1"):
		anim.play("SwordAttack1")
	elif Input.is_action_just_pressed("Sword2"):
		anim.play("SwordAttack2")
	elif Input.is_action_just_pressed("Bow"):
		anim.play("BowAttack")

	# other..
	
