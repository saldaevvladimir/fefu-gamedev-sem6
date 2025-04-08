extends CharacterBody2D

var SPEED = 250
var health = 100
const BOW_DMG = 20

const WEAPONS = {
	"Sword1": {
		"animation": "SwordAttack1",
		"damage": 20
	},
	"Sword2": {
		"animation": "SwordAttack2",
		"damage": 50
	},
	"Bow": {
		"animation": "BowAttack",
		"damage": 15
	},
}

@onready var anim = $AnimatedSprite2D
var is_attacking = false
var active_weapon = null

func _physics_process(delta):
	if is_attacking or !is_alive():
		return
	
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
	if Input.is_action_pressed("Sword1"):
		attack("Sword1")
	elif Input.is_action_pressed("Sword2"):
		attack("Sword2")
	elif Input.is_action_pressed("Bow"):
		death()
		#attack("Bow")

func is_alive():
	return health > 0

func _on_animated_sprite_2d_animation_finished() -> void:
	print("animation finished")
	is_attacking = false
	active_weapon = null
	
func get_weapon_damage(weapon):
	if weapon != null:
		return WEAPONS[weapon]["damage"]
	return 0
	
func get_weapon_animation(weapon):
	if weapon:
		return WEAPONS[weapon]["animation"]
	return null
	
func attack(weapon):
	if weapon == null:
		return 
		
	is_attacking = true
	active_weapon = weapon
	anim.play(get_weapon_animation(weapon))
		
func take_damage():
	health -= 1
	if health <= 0:
		death()
		
func death():
	health = 0
	anim.play("Death")
	on_death()
	
func on_death():
	print("player dead")
	
