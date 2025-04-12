extends Label

const arrow = preload("res://game/scenes/objects/Arrow.tscn")

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	text = "arrows: " + str($"../../Player/player".OBJECTS_COUNT[arrow])
