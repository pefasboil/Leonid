extends CharacterBody2D

signal health_changed(new_health)
enum {
	IDLE,
	MOVE,
	ATTACK,
	ATTACK2,
	ATTACK3,
	BLOCK,
	DAMAGE,
	DEATH,
	SLIDE
}

const SPEED = 200.0
const JUMP_VELOCITY = -320.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var anim = $AnimatedSprite2D
@onready var animPlayer = $AnimationPlayer
var max_health = 120
var health
var gold = 0
var state = MOVE
var run_speed = 1
var combo = false
var attack_cooldown = false
var player_pos
var damage_basic = 20
var damage_multiplier = 1
var damage_current


func _ready():
	Signals.connect("enemy_attack", Callable (self, "_on_damage_received"))
	health = max_health
	
func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	if velocity.y > 0:
		animPlayer.play("Fall")
	damage_current = damage_basic * damage_multiplier
	match state:
		MOVE:
			move_state()
		ATTACK:
			attack_state()
		ATTACK2:
			attack2_state()
		ATTACK3:
			attack3_state()
		SLIDE:
			slide_state()
		BLOCK:
			block_state()
		DAMAGE:
			damage_state()
		DEATH:
			death_state()


	move_and_slide()
	
	player_pos = self.position
	Signals.emit_signal("player_position_update", player_pos)
	
	
func move_state():
	var direction = Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED * run_speed
		if velocity.y == 0:
			if run_speed == 1:
				animPlayer.play("Walk")
			else:
				animPlayer.play("Run")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if velocity.y == 0:
			animPlayer.play("Idle")
	if direction == -1:
		anim.flip_h = true
		$AttackDirection.rotation_degrees = 100
	elif direction == 1:
		anim.flip_h = false
		$AttackDirection.rotation_degrees = 0
		
	if Input.is_action_pressed("run"):
		run_speed = 1.5
	else:
		run_speed = 1
	if Input.is_action_pressed("slide"):
		if velocity.x == 0:
			state = BLOCK
		else:
			state = SLIDE
	if Input.is_action_just_pressed("attack") and attack_cooldown == false:
		state = ATTACK

func block_state():
	velocity.x = 0
	animPlayer.play("Block")
	if Input.is_action_just_released("slide"):
		state = MOVE
func slide_state():
	animPlayer.play("Slide")
	await animPlayer.animation_finished
	state = MOVE
func attack_state():
	damage_multiplier = 1
	if Input.is_action_just_pressed("attack") and combo == true:
		state = ATTACK2
	velocity.x = 0
	animPlayer.play("Attack")
	await animPlayer.animation_finished
	attack_freeze()
	state = MOVE
func death_state():
	velocity.x = 0
	anim.play("Death")
	await anim.animation_finished
	queue_free()
	get_tree().change_scene_to_file("res://menu/menu.tscn")
func attack2_state():
	damage_multiplier = 1.2
	if Input.is_action_just_pressed("attack") and combo == true:
		state = ATTACK3
	animPlayer.play("Attack2")
	await animPlayer.animation_finished
	state = MOVE
func attack3_state():
	damage_multiplier = 2
	animPlayer.play("Attack3")
	await animPlayer.animation_finished
	state = MOVE
func combo1():
	combo = true
	await animPlayer.animation_finished
	combo = false
func attack_freeze():
	attack_cooldown = true
	await get_tree().create_timer(0.3).timeout
	attack_cooldown = false
func damage_state():
	velocity.x = 0
	anim.play("Damage")
	await anim.animation_finished
	state = MOVE
func _on_damage_received(enemy_damage):
	if state == BLOCK:
		enemy_damage /= 2
	elif state == SLIDE:
		enemy_damage = 0
	else:
		state = DAMAGE
	health -= enemy_damage
	if health <= 0:
		health = 0
		state = DEATH
	
	else:
		state =DAMAGE
	emit_signal("health_changed", health)
	print(health)


func _on_hitbox_area_entered(area):
	Signals.emit_signal("player_attack", damage_current)
