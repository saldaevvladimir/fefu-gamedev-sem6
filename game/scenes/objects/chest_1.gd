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
	if anim.animation != "Open":
		print("chest1 open")
		interactive = false
		anim.play("Open")
		return contained_objects

func add_object(obj, count):
	if obj in contained_objects:
		contained_objects[obj] += count
	else:
		contained_objects[obj] = count
