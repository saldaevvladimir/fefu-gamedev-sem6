extends Node2D

signal interacted(objects)

const Globals = preload("res://game/scripts/globals.gd")

@onready var anim = $AnimatedSprite2D
var contained_objects = {}
var interactive = true

func is_interactive():
	return interactive

func auto_interact():
	return false

func _ready():
	anim.play("Idle")
	add_to_group("chests")
	add_random()

func add_random():
	var arrow_count = randi() % 4
	if arrow_count > 0:
		add_object(Globals.arrow, arrow_count)

func interact():
	if interactive and anim.animation != "Open":
		interactive = false
		print("chest1 open")
		anim.play("Open")
		return contained_objects
	return null

func add_object(obj, count):
	if obj in contained_objects:
		contained_objects[obj] += count
	else:
		contained_objects[obj] = count

func _on_animated_sprite_2d_animation_finished():
	if anim.animation == "Open":
		# Здесь можно добавить код для обработки завершения анимации открытия
		pass
