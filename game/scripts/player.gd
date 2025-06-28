extends CharacterBody2D

const HIT_OPACITY = 0.6
const HIT_DURATION = 0.2

var SPEED = 250
var health = 100

@onready var anim = $AnimatedSprite2D
@onready var melee_shape = $Area2D/CollisionShape2D
@onready var hit_timer = $Hit_Timer

const arrow = preload("res://game/scenes/objects/Arrow.tscn")

var is_attacking = false
var active_weapon = null

# for ranged attacks
var last_move_direction = Vector2(-1, 0)

# for melee attacks
var bodies_in_melee_range = []

const WEAPONS = {
	"Sword1": {
		"animation": "SwordAttack1",
		"damage": 20,
		"type": "melee"
	},
	"Sword2": {
		"animation": "SwordAttack2",
		"damage": 50,
		"type": "melee"
	},
	"Bow": {
		"animation": "BowAttack",
		"damage": 30,
		"type": "ranged",
		"range": 300
	},
}

var WEAPONS_AMMO = {
	"Bow": arrow
}

var OBJECTS_COUNT = {
	arrow: 10,
	"SimpleKey": 0,
	"MysteryKey": 0,
}

func _on_ready() -> void:
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	uniform float hit_opacity : hint_range(0.0, 1.0);
	void fragment() {
		COLOR.rgb = mix(COLOR.rgb, vec3(1.0, 1.0, 1.0), hit_opacity);
	}
	"""
	var material = ShaderMaterial.new()
	material.shader = shader
	anim.material = material
	hit_timer.wait_time = HIT_DURATION
	pass

func _physics_process(delta):
	if is_attacking or !is_alive():
		return
	
	velocity = Vector2.ZERO
	
	if Input.is_action_pressed("Right"):
		velocity.x += SPEED
		anim.flip_h = false
		melee_shape.position.x = abs(melee_shape.position.x)
	if Input.is_action_pressed("Left"):
		velocity.x += -SPEED
		anim.flip_h = true
		melee_shape.position.x = -abs(melee_shape.position.x)
	if Input.is_action_pressed("Up"):
		velocity.y += -SPEED
	if Input.is_action_pressed("Down"):
		velocity.y += SPEED
	
	var direction = velocity.normalized()
	if direction != Vector2.ZERO:
		last_move_direction = direction
		
	velocity = direction * SPEED
	move_and_slide()
	
	if velocity.length() > 0:
		anim.play("Walk")
	else:
		anim.play("Idle")
	
	for weapon in ["Sword1", "Sword2", "Bow"]:
		if Input.is_action_just_pressed(weapon):
			attack(weapon)

func is_alive():
	return health > 0
	
func _on_animated_sprite_2d_animation_finished() -> void:
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
	
func get_ammo_by_weapon(weapon):
	if weapon in WEAPONS_AMMO:
		return WEAPONS_AMMO[weapon]
	
func attack(weapon):
	if weapon == null:
		return 
		
	is_attacking = true
	active_weapon = weapon
	anim.play(get_weapon_animation(weapon))
	
	if WEAPONS[weapon]["type"] == "melee":
		for body in bodies_in_melee_range:
			if body.has_method("take_damage"):
				print(body.name)
				body.take_damage(get_weapon_damage(weapon))
	elif WEAPONS[weapon]["type"] == "ranged":
		var ammo_type = get_ammo_by_weapon(weapon)
		if use_object(ammo_type):
			var ammo = ammo_type.instantiate()
			ammo.global_transform = $Node2D/Marker2D.global_transform
			ammo.set_shooter(self)
			ammo.set_direction(last_move_direction)
			ammo.set_damage(WEAPONS[weapon]["damage"])
			add_child(ammo)
		
func has_object(obj):
	if obj in OBJECTS_COUNT:
		return OBJECTS_COUNT[obj] > 0
	return false
		
func use_object(obj):
	if !has_object(obj):
		return false
	print("used object: ", obj)
	OBJECTS_COUNT[obj] -= 1
	return true

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body not in bodies_in_melee_range and body.name != "player":
		bodies_in_melee_range.append(body)
		
func _on_area_2d_body_exited(body: Node2D) -> void:
	if body in bodies_in_melee_range:
		bodies_in_melee_range.erase(body)

func take_damage(damage: int = 0):
	if !is_alive():
		return
		
	health -= damage
	
	anim.material.set_shader_parameter("hit_opacity", HIT_OPACITY)
	hit_timer.start()
	
	if !is_alive():
		death()
		
func death():
	health = 0
	anim.play("Death")
	print("player dead")
	
func _on_hit_timer_timeout() -> void:
	anim.material.set_shader_parameter("hit_opacity", 0.0)
	
func destroy():
	queue_free()
