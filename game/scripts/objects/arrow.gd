extends Area2D

# временно тут определю
const POSSIBLE_TARGETS = [
	"player",
	"skeleton"
]

var damage = null
var speed = 400
var range = 200
var shooter = null
var direction = null
var start_position = null

func _ready() -> void:
	start_position = position
	var scale_factor = 2
	$AnimatedSprite2D.scale = Vector2(scale_factor, scale_factor)

func _process(delta: float) -> void:
	if (position - start_position).length() >= range:
		destroy()
	if direction != Vector2.ZERO:
		position += direction * speed * delta
	
func set_shooter(new_shooter):
	shooter = new_shooter
	
func set_direction(dir):
	direction = dir
	if direction.length() > 0:
		rotation = direction.angle()
		
func set_damage(dmg):
	damage = dmg
	
func set_range(rng):
	range = rng

func _on_body_entered(body: Node2D) -> void:
	if body != shooter and body.name in POSSIBLE_TARGETS:
		if damage:
			body.take_damage(damage)
		destroy()

func destroy():
	queue_free()
