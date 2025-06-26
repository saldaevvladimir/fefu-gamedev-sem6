extends Label

const arrow = preload("res://game/scenes/objects/Arrow.tscn")

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	text = str($"../../Player/Player".OBJECTS_COUNT[arrow])
