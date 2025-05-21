extends CharacterBody2D

const Globals = preload("res://game/scripts/globals.gd")

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

var interactive_objects = []

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
	"SimpleKey": 5,
	"MysteryKey": 5,
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
		if Input.is_action_pressed(weapon):
			attack(weapon)
			
	if Input.is_action_pressed("Chest"):
		interact_with_object()

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
	
	if WEAPONS[weapon]["type"] == "melee":
		anim.play(get_weapon_animation(weapon))
		for body in bodies_in_melee_range:
			if body.has_method("take_damage"):
				print(body.name)
				body.take_damage(get_weapon_damage(weapon))
	elif WEAPONS[weapon]["type"] == "ranged":
		var ammo_type = get_ammo_by_weapon(weapon)
		if use_object(ammo_type):
			anim.play(get_weapon_animation(weapon))
			var ammo = ammo_type.instantiate()
			ammo.global_transform = $Node2D/Marker2D.global_transform
			ammo.set_shooter(self)
			ammo.set_direction(last_move_direction)
			ammo.set_damage(WEAPONS[weapon]["damage"])
			add_child(ammo)

func interact_with_object():
	var nearest = null
	var min_distance = INF
	
	for body in interactive_objects:
		#if body.is_in_group("chests"):
		var distance = body.global_position.distance_to(global_position)
		if distance < min_distance:
			min_distance = distance
			nearest = body
			
	if nearest:
		if nearest.is_in_group("chests"):
			var key_type = "SimpleKey" if nearest.name == "Chest1" else "MysteryKey"
			if use_object(key_type):
				var objects = nearest.interact()
				_on_chest_opened(objects)

func _on_chest_opened(objects):
	if not objects:
		return
	for obj_name in objects:
		var obj_count = objects[obj_name]
		receive_object(obj_name, obj_count)

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
	
func receive_object(obj_name, count):
	if obj_name in OBJECTS_COUNT:
		OBJECTS_COUNT[obj_name] += count
		print("Received object: ", obj_name, " - ", count)
	else:
		OBJECTS_COUNT[obj_name] = count
		print("Received new object: ", obj_name, " - ", count)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body not in bodies_in_melee_range and body.name != "player":
		bodies_in_melee_range.append(body)
		print("body entered: ", body)
		
func _on_area_2d_body_exited(body: Node2D) -> void:
	if body in bodies_in_melee_range:
		bodies_in_melee_range.erase(body)
		print("body exit: ", body)

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
	
func handle_object_entry(obj):
	if obj.name in Globals.EXISTING_OBJECTS and obj.is_interactive():
		print("object entered: ", obj.name)
		if obj.auto_interact():
			obj.interact()
		else:
			interactive_objects.append(obj)
		
func handle_object_exit(obj):
	if obj in interactive_objects:
		interactive_objects.erase(obj)
		print("object exited: ", obj.name)

func _on_area_2d_area_entered(area: Area2D) -> void:
	# all OBJECTS must have Area2D as root node
	handle_object_entry(area)

func _on_area_2d_area_exited(area: Area2D) -> void:
	handle_object_exit(area)
