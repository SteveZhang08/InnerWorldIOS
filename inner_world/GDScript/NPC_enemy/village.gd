extends CharacterBody2D

# ============================================================
# 1. 可调参数
# ============================================================
@export var move_speed: float = 80.0
@export var detection_range: float = 400.0
@export var attack_range: float = 100.0       
@export var attack_cooldown: float = 1.5
@export var knockback_force: float = 300.0
@export var invincible_duration: float = 0.1

# ============================================================
# 2. 节点引用
# ============================================================
@onready var animated_sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var head_text = $RichTextLabel
@onready var hurt_particles = $CPUParticles2D
@onready var AttackArea:Area2D = $Visual/AttackArea
@onready var Visual:Node2D = $Visual

# ============================================================
# 3. 状态变量
# ============================================================
enum State { IDLE, WALK, ATTACK }
var current_state: State = State.IDLE
var can_attack: bool = true
var attack_timer: float = 0.0
var blood = 100
var is_invincible: bool = false
var is_hurt: bool = false

var enable = false

# ============================================================
# 4. 核心逻辑
# ============================================================
func _ready():
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished():
	var anim_name = animated_sprite.animation
	if anim_name == "sword":
		var player = Global_Player.player
		if player:
			var distance = global_position.distance_to(player.global_position)
			if distance < attack_range and can_attack:
				perform_attack()
			else:
				if distance < detection_range:
					transition_to(State.WALK)
				else:
					transition_to(State.IDLE)
		else:
			transition_to(State.IDLE)

func perform_attack():
	if not can_attack:
		return
	z_index = 2
	animated_sprite.play("sword", 2)
	var bodies = AttackArea.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			var direction = (body.global_position - global_position).normalized()
			body.injured(5, direction)
	can_attack = false
	attack_timer = attack_cooldown
	velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if not enable:
		return
	# 获取玩家引用
	var player = Global_Player.player
	if not player:
		if current_state != State.IDLE:
			transition_to(State.IDLE)
		return

	# 计算到玩家的距离
	var distance = global_position.distance_to(player.global_position)

	# 状态机
	match current_state:
		State.IDLE:
			if distance < detection_range:
				transition_to(State.WALK)

		State.WALK:
			if distance > detection_range:
				transition_to(State.IDLE)
			elif distance < attack_range and can_attack:
				transition_to(State.ATTACK)
			else:
				var direction = (player.global_position - global_position).normalized()
				velocity = direction * move_speed
				if direction.x != 0:
					Visual.scale.x = -1 if direction.x < 0 else 1

		State.ATTACK:
			attack_timer -= delta
			if attack_timer <= 0.0:
				can_attack = true

			if distance < attack_range and can_attack:
				perform_attack()
			elif distance > attack_range:
				transition_to(State.WALK)
			elif distance > detection_range:
				transition_to(State.IDLE)

	move_and_slide()

# ============================================================
# 5. 状态切换
# ============================================================
func transition_to(new_state: State) -> void:
	match current_state:
		State.ATTACK:
			can_attack = true
			attack_timer = 0.0

	current_state = new_state

	match new_state:
		State.IDLE:
			animated_sprite.play("idle")
			velocity = Vector2.ZERO

		State.WALK:
			animated_sprite.play("walk",2)

		State.ATTACK:
			if can_attack:
				z_index = 2
				animated_sprite.play("sword",2)
				var bodies = AttackArea.get_overlapping_bodies()
				for body in bodies:
					if body.is_in_group("player"):
						var direction = (body.global_position - global_position).normalized()
						body.injured(5,direction)
				can_attack = false
				attack_timer = attack_cooldown
				velocity = Vector2.ZERO

# ============================================================
# 受伤函数（由攻击者调用）
# ============================================================
func injured(attack_blood: float, attack_direction: Vector2 = Vector2.ZERO) -> void:
	if is_invincible:
		return

	# 1. 扣血
	blood -= attack_blood

	# 2. 击退（立即施加，与闪红同时发生）
	if attack_direction != Vector2.ZERO:
		velocity = attack_direction.normalized() * knockback_force
	else:
		var dir = -Vector2.RIGHT if animated_sprite.flip_h else Vector2.RIGHT
		velocity = dir * knockback_force
	if hurt_particles:
		# 设置旋转，使粒子的发射方向指向攻击方向
		if attack_direction != Vector2.ZERO:
			hurt_particles.global_rotation = attack_direction.angle()
		else:
			# 如果没有方向，根据当前朝向决定（默认朝右）
			hurt_particles.global_rotation = 0.0
		hurt_particles.restart()   # 一次爆发式播放
	
	# 3. 闪红效果（同时进行，不等待击退完成）
	animated_sprite.modulate = Color(1, 0.5, 0.5)  # 偏红
	await get_tree().create_timer(0.3).timeout
	animated_sprite.modulate = Color.WHITE

	# 4. 无敌状态（防止连续受伤）
	is_invincible = true
	await get_tree().create_timer(invincible_duration).timeout
	is_invincible = false

	# 5. 死亡判断
	if blood <= 0:
		die()

# ============================================================
# 死亡函数
# ============================================================
func die() -> void:
	queue_free()

func _process(delta: float) -> void:
	head_text.text = "SteveZhang08 "+"Healthy:"+str(blood)
