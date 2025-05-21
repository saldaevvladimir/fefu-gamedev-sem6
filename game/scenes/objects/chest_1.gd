extends Node2D

signal chest_opened(objects)

@onready var anim = $AnimatedSprite2D

var contained_objects = {}

func _ready():
	anim.play("idle")
	add_to_group("chests")
	add_random_arrows()

func add_random_arrows():
	var arrow_count = randi() % 4  
	if arrow_count > 0:
		add_object("arrow", arrow_count)

func open():
	if anim.animation != "open":
		anim.play("open")
		chest_opened.emit(contained_objects)
		contained_objects.clear()

func add_object(obj, count):
	if obj in contained_objects:
		contained_objects[obj] += count
	else:
		contained_objects[obj] = count
