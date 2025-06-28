extends Node2D

const DMG = 3
const DMG_INTERVAL = 0.1
const SHOW_DURATION = 5.0
const HIDE_DURATION = 3.0

var target = null
var is_active = false

@onready var anim = $AnimatedSprite2D
@onready var show_timer = $Show_Timer
@onready var dmg_timer = $DMG_Timer

func _ready() -> void:
	show_timer.wait_time = SHOW_DURATION
	show_timer.start()
	
	dmg_timer.wait_time = DMG_INTERVAL
	
	hide_peaks()

func _process(delta: float) -> void:
	pass

func hide_peaks():
	is_active = false
	anim.play("Hide")
	
func show_peaks():
	is_active = true
	anim.play("Show")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		target = body

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		target = null

func _on_dmg_timer_timeout() -> void:
	if is_active and target != null:
		target.take_damage(DMG)

func _on_show_timer_timeout() -> void:
	if is_active:
		hide_peaks()
		show_timer.wait_time = HIDE_DURATION
	else:
		show_peaks()
		show_timer.wait_time = SHOW_DURATION
		dmg_timer.start()
	show_timer.start()

func _on_animated_sprite_2d_animation_finished() -> void:
	pass

func _on_animated_sprite_2d_animation_changed() -> void:
	pass
