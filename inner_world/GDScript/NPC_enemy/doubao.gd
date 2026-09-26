extends CharacterBody2D

# ============================================================
# 【可调参数】
# ============================================================
@export var move_speed: float = 80.0
@export var detection_range: float = 400.0        # 正常发现玩家距离
@export var chase_memory_time: float = 1.2        # 丢失目标继续追击多久
@export var hurt_trigger_chase_memory:float = 3.0 # 被背后打之后强制追击的记忆时间
@export var attack_range: float = 100.0           # 攻击触发距离
@export var ideal_attack_distance: float = 75.0   # 希望和玩家保持的最优攻击距离
@export var attack_cooldown: float = 1.5
@export var knockback_force: float = 300.0
@export var invincible_duration: float = 0.1
@export var flip_speed_scale: float = 2.0         # 动画播放倍速
@export var attack_can_be_interrupted:bool = true # 是否允许受伤打断攻击动画
@export var enable_debug_log:bool = false

# ============================================================
# 【节点引用】
# ============================================================
@onready var animated_sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var head_text = $RichTextLabel
@onready var hurt_particles = $CPUParticles2D
@onready var AttackArea:Area2D = $Visual/AttackArea
@onready var Visual:Node2D = $Visual

# ============================================================
# 【状态枚举】
# ============================================================
enum State {
	IDLE,       # 待机
	CHASE,      # 追击玩家
	ATTACK,     # 正在攻击
}

var current_state: State = State.IDLE

# AI记忆变量
var can_attack: bool = true
var attack_cooldown_timer: float = 0.0
var chase_memory_timer:float = 0.0
var blood = 100
var is_invincible: bool = false
var enable = false

# ============================================================
# 初始化
# ============================================================
func _ready():
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished():
	var anim_name = animated_sprite.animation
	if anim_name == "sword":
		if current_state == State.ATTACK:
			transition_to(State.CHASE)

# ============================================================
# 【物理主循环】
# ============================================================
func _physics_process(delta: float) -> void:
	if not enable:
		return
	var player = Global_Player.player
	velocity = Vector2.ZERO

	if chase_memory_timer > 0:
		chase_memory_timer -= delta

	if not player:
		if current_state != State.IDLE:
			transition_to(State.IDLE)
		move_and_slide()
		return

	var distance = global_position.distance_to(player.global_position)
	var dir_to_player = (player.global_position - global_position).normalized()

	match current_state:
		State.IDLE:
			if distance < detection_range:
				chase_memory_timer = chase_memory_time
				transition_to(State.CHASE)

		State.CHASE:
			if distance > detection_range:
				if chase_memory_timer <= 0:
					transition_to(State.IDLE)
				else:
					move_toward_player(dir_to_player)
			else:
				chase_memory_timer = chase_memory_time
				if distance < attack_range and can_attack:
					transition_to(State.ATTACK)
				else:
					if distance > ideal_attack_distance:
						move_toward_player(dir_to_player)
					elif distance < ideal_attack_distance * 0.6:
						velocity = -dir_to_player * move_speed * 0.6

		State.ATTACK:
			pass

	# 更新攻击冷却
	if not can_attack:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer <= 0.0:
			can_attack = true

	move_and_slide()

# ============================================================
# 辅助函数：朝玩家移动 + 翻转精灵朝向
# ============================================================
func move_toward_player(dir:Vector2):
	velocity = dir * move_speed
	if dir.x != 0:
		Visual.scale.x = -1 if dir.x < 0 else 1

# ============================================================
# 状态切换 transition_to
# ============================================================
func transition_to(new_state: State, force:bool = false):
	if enable_debug_log:
		print("[EnemyAI] 状态切换 ",current_state," → ",new_state," force=",force)

	# 只有非强制情况下，才锁攻击状态；受伤传入force=true可以打断攻击
	if not force and current_state == State.ATTACK and new_state != State.ATTACK:
		return

	current_state = new_state

	match new_state:
		State.IDLE:
			animated_sprite.play("idle")
			velocity = Vector2.ZERO
		State.CHASE:
			animated_sprite.play("walk", flip_speed_scale)
		State.ATTACK:
			animated_sprite.play("sword", flip_speed_scale)
			velocity = Vector2.ZERO
			apply_attack_damage()
			can_attack = false
			attack_cooldown_timer = attack_cooldown

# ============================================================
# 统一攻击伤害逻辑
# ============================================================
func apply_attack_damage():
	var bodies = AttackArea.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			var direction = (body.global_position - global_position).normalized()
			body.injured(5, direction)

# ============================================================
# 受伤函数【重点修改：被打立刻锁定玩家，处理背后偷袭】
# ============================================================
func injured(attack_blood: float, attack_direction: Vector2 = Vector2.ZERO) -> void:
	if is_invincible:
		return

	blood -= attack_blood

	if attack_direction != Vector2.ZERO:
		velocity = attack_direction.normalized() * knockback_force
	else:
		var dir = -Vector2.RIGHT if Visual.scale.x < 0 else Vector2.RIGHT
		velocity = dir * knockback_force

	if hurt_particles:
		if attack_direction != Vector2.ZERO:
			hurt_particles.global_rotation = attack_direction.angle()
		else:
			hurt_particles.global_rotation = 0.0
		hurt_particles.restart()

	animated_sprite.modulate = Color(1, 0.5, 0.5)
	await get_tree().create_timer(0.3).timeout
	animated_sprite.modulate = Color.WHITE

	is_invincible = true
	await get_tree().create_timer(invincible_duration).timeout
	is_invincible = false

	# ========== 新增：被攻击之后强制响应玩家（背后偷袭处理） ==========
	var player = Global_Player.player
	if player:
		# 判断玩家是不是在攻击判定框内；不在=来自侧面/背后
		var bodies = AttackArea.get_overlapping_bodies()
		var player_in_front_area = false
		for b in bodies:
			if b.is_in_group("player"):
				player_in_front_area = true
				break

		if enable_debug_log:
			print("被攻击，玩家是否在前方攻击框内：",player_in_front_area)

		# 被打之后，不管距离多远，给长追击记忆
		chase_memory_timer = hurt_trigger_chase_memory

		# force=true 强制打断当前攻击状态，转身追击玩家
		if current_state != State.CHASE:
			transition_to(State.CHASE, attack_can_be_interrupted)

		# 立刻转向攻击者方向，不需要等physics
		var dir_to_hurt_source = (player.global_position - global_position).normalized()
		if dir_to_hurt_source.x != 0:
			Visual.scale.x = -1 if dir_to_hurt_source.x < 0 else 1
	# =========================================================

	if blood <= 0:
		die()

func die() -> void:
	queue_free()

func _process(delta: float) -> void:
	head_text.text = "Doubao "+"Healthy:"+str(blood)
