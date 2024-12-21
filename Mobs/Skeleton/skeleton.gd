extends CharacterBody2D

enum {
	IDLE,
	ATTACK,
	CHASE,
	RECOVER,
	DEATH,
	DAMAGE
}
var state: int = 0:
		set(value):
			state = value
			match state:
				IDLE:
					idle_state()
				ATTACK:
					attаck_state()
				DAMAGE:
					damage_state()
				DEATH:
					death_state()
				RECOVER:
					recover_state()

@onready var animPlayer = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var player
var direction
var speed = 50
var damage = 20
var health = 100
var chase = false
func _ready():
	Signals.connect("player_position_update", Callable (self, "_on_player_position_update"))
	Signals.connect("player_attack", Callable (self, "_on_damage_received"))
func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
		
	if state == CHASE:
		chase_state()
	var player =$"../../Player/Player"
	var direction = (player.position - self.position).normalized()
	if chase == true:
		velocity.x = direction.x * speed
	
	move_and_slide()

func _on_player_position_update(player_pos):
	player = player_pos

func _on_attack_range_body_entered(_body):
	state = ATTACK
	
func idle_state():
	animPlayer.play("Idle")
	state = CHASE
	
func attаck_state():
	animPlayer.play("Attack")
	await animPlayer.animation_finished
	state = IDLE
	
func chase_state():
	direction = (player - self.position).normalized()
	if direction.x < 0:
		sprite.flip_h = true
		$AttackDirection.rotation_degrees = 180
	else:
		sprite.flip_h = false
		$AttackDirection.rotation_degrees = 0
		

func damage_state():
	animPlayer.play("Damage")
	await animPlayer.animation_finished
	state = IDLE
	
func death_state():
	animPlayer.play("Death")
	await animPlayer.animation_finished
	queue_free()
	
func recover_state():
	animPlayer.play("Recover")
	await animPlayer.animation_finished
	state = IDLE
	
func _on_hitbox_area_entered(area):
	Signals.emit_signal("enemy_attack", damage)
	

func _on_mob_health_no_health():
	state = DEATH


func _on_mob_health_damage_received():
	state = IDLE
	state = DAMAGE


func _on_detector_body_entered(body):
	if body.name == "Player":
		chase = true
