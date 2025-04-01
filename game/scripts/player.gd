extends CharacterBody2D

const SPEED = 250


func _physics_process(delta):
	velocity = Vector2.ZERO
	
	if Input.is_action_pressed("Right"):
		velocity.x += SPEED
		$Sprite2D.flip_h = false
	if Input.is_action_pressed("Left"):
		velocity.x += -SPEED
		$Sprite2D.flip_h = true
	if Input.is_action_pressed("Up"):
		velocity.y += -SPEED
	if Input.is_action_pressed("Down"):
		velocity.y += SPEED
		
	velocity = velocity.normalized() * SPEED
	
	move_and_slide()
