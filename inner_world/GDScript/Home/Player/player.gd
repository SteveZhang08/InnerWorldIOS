extends CharacterBody2D

# ============================================================
# 1. 可调参数
# ============================================================
@export var move_speed: float = 200
@export var anim_speed: float = 2

# ============================================================
# 2. 节点引用
# ============================================================
@onready var player_sprite = $VisualContainer/Player
@onready var collision_shape = $CollisionShape2D
@onready var footstep_player = $FootstepPlayer
@onready var item = $VisualContainer/Item
@onready var VisualContainer = $VisualContainer
@onready var InventoryBar = get_node("/root/Main/UI/InventoryBar")
@onready var audio_listener: AudioListener2D = $AudioListener2D
@onready var Item_AnimationPlayer: AnimationPlayer = $VisualContainer/Item/AnimationPlayer
@onready var Sword_Slash_AnimationPlayer: AnimationPlayer = $VisualContainer/sword_flash/AnimationPlayer
@onready var Sword_flash_Sound: AudioStreamPlayer2D = $VisualContainer/sword_flash/flash
@onready var Camera:Camera2D = $Camera2D
@onready var AttackArea:Area2D = $VisualContainer/AttackArea
@onready var hurt_particles = $CPUParticles2D
@export var knockback_force: float = 300.0
@export var invincible_duration: float = 0.1

# ============================================================
# 3. 状态变量
# ============================================================
var blood = 100
var is_moving = false
var initially_x
var stop_action = false
var footstep_timer = 0.0
var position_x
var position_y
var last_position = null
var target_position
var is_attacking = false
var npc_in = false
var is_invincible = false

signal attack_started()

# ============================================================
# 4. 物品逐帧位置数据（保留备用）
# ============================================================
var item_frame = {
	"walk": {
		0: [-26, 35, true],
		1: [-21, 40, true],
		2: [-3, 31, true],
		3: [0, 31, true],
		5: [-21, 35, true]
	},
	"idle": {
		0: [-25, 35, true],
		2: [-25, 39, true],
		6: [-25, 35, true]
	},
	"sword": {
		0: [-25, 35, true],
		2: [-3, 30, true],
		3: [2, 31, true],
		4: [2, 27, true],
		5: [-25, 36, true],
	}
}

# ============================================================
# 5. 初始化
# ============================================================
func _ready() -> void:
	visible = true
	player_sprite.play("idle")
	initially_x = collision_shape.position.x
	Item_AnimationPlayer.speed_scale = 3.0
	Sword_Slash_AnimationPlayer.speed_scale = 2
	
	get_node("/root/Main/UI/Speak").player_action.connect(_action)
	get_node("/root/Main/UI/ImageViewer").player_action.connect(_action)

	audio_listener.make_current()

	player_sprite.animation_finished.connect(_on_player_animation_finished)
	Item_AnimationPlayer.animation_finished.connect(_on_sword_animation_finished)
	
	AttackArea.body_entered.connect(_on_attack_area_body_entered)
	AttackArea.body_exited.connect(_on_attack_area_body_exit)
	
# ============================================================
# 6. 公共方法
# ============================================================
func _action(tf: bool) -> void:
	stop_action = !tf

func _on_mouse_click_move(mouse_pos: Vector2) -> void:
	is_moving = true
	target_position = mouse_pos

# ============================================================
# 冻结帧（时间停滞）
# ============================================================
var hit_stop_tween: Tween

func hit_stop(duration: float = 0.08, scale: float = 0.0) -> void:
	# 如果已有 tween 在运行，先杀死避免冲突
	if hit_stop_tween and hit_stop_tween.is_running():
		hit_stop_tween.kill()

	# 设置时间缩放
	Engine.time_scale = scale

	# 创建 Tween 恢复时间
	hit_stop_tween = create_tween()
	hit_stop_tween.tween_callback(func():
		Engine.time_scale = 1.0
	).set_delay(duration)

# ============================================================
# 7. 辅助函数
# ============================================================
func isplaying(name: String) -> bool:
	return player_sprite.is_playing() and player_sprite.animation == name

# ============================================================
# 8. 动画结束回调
# ============================================================
func _on_player_animation_finished():
	if player_sprite.animation == "sword" or Item_AnimationPlayer.animation == "sword_return":
		is_attacking = false
		var has_movement = (
			Input.is_action_pressed("move_right") or
			Input.is_action_pressed("move_left") or
			Input.is_action_pressed("move_up") or
			Input.is_action_pressed("move_down")
		)
		if has_movement:
			player_sprite.play("walk", anim_speed)
		else:
			player_sprite.play("idle")

func _on_sword_animation_finished(anim_name):
	if anim_name == "slash":
		Item_AnimationPlayer.play("sword_return")
	if anim_name == "sword_return":
		z_index = 0
		is_attacking = false
		hit_stop(0.08,0.5)
		var has_movement = (
			Input.is_action_pressed("move_right") or
			Input.is_action_pressed("move_left") or
			Input.is_action_pressed("move_up") or
			Input.is_action_pressed("move_down")
		)
		if has_movement:
			player_sprite.play("walk", anim_speed)
		else:
			player_sprite.play("idle")

# ============================================================
# 9. 物理处理
# ============================================================
func _on_attack_area_body_entered(body):
	npc_in = true

func _on_attack_area_body_exit(body):
	npc_in = false

func _physics_process(delta: float) -> void:
	if stop_action:
		return

	# ---------- 1. 获取键盘输入 ----------
	var move_direction = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		is_moving = false
		move_direction.x += 1
	if Input.is_action_pressed("move_left"):
		is_moving = false
		move_direction.x -= 1
	if Input.is_action_pressed("move_up"):
		is_moving = false
		move_direction.y -= 1
	if Input.is_action_pressed("move_down"):
		is_moving = false
		move_direction.y += 1

	# ---------- 2. 处理攻击输入 ----------
	if Input.is_action_just_pressed("attack") and not is_attacking and Global_Player._is_weapon():
		attack()

	# ---------- 3. 攻击打断检测（已移除移动打断，现在移动不会打断攻击） ----------
	# 只保留动画结束逻辑（已由信号处理）
	# 注意：不再因为移动输入而打断攻击

	# ---------- 4. 鼠标移动任务优先 ----------
	if is_moving:
		return

	# ---------- 5. 移动逻辑（无论是否攻击都执行） ----------
	if move_direction.length() > 0:
		move_direction = move_direction.normalized()
		velocity = move_direction * move_speed

		if move_direction.x != 0:
			VisualContainer.transform.x = Vector2(1, 0) if move_direction.x > 0 else Vector2(-1, 0)

		# 播放行走动画（攻击时不覆盖武器动画，角色本身动画播放行走）
		if player_sprite.animation != "walk":
			player_sprite.play("walk", anim_speed)
	else:
		velocity = Vector2.ZERO
		if player_sprite.animation != "idle" and not is_attacking:
			player_sprite.play("idle")
		# 注意：攻击时如果没有移动，保持 idle 或攻击武器动画，这里不强制切换

	# ---------- 6. 脚步声音效 ----------
	if velocity.length() > 0:
		footstep_timer += delta
		if footstep_timer >= 0.3:
			footstep_player.play()
			footstep_timer = 0.0
	else:
		footstep_timer = 0.0

	# ---------- 7. 更新坐标 ----------
	position_x = global_position.x
	position_y = global_position.y

	move_and_slide()

func attack():
	Item_AnimationPlayer.play("slash")
	Sword_Slash_AnimationPlayer.play("slash")
	is_attacking = true
	attack_started.emit()
	z_index = 3
	var bodies = AttackArea.get_overlapping_bodies()
	var attack_mode = true
	for body in bodies:
		if body.is_in_group("NPC"):
			var direction = (body.global_position - global_position).normalized()
			body.injured(5,direction)
			if attack_mode:
				Sword_flash_Sound.play()
				Camera.add_trauma(0.6)
				print("trauma")
				attack_mode = false

func injured(attack_blood: float, attack_direction: Vector2 = Vector2.ZERO) -> void:
	if is_invincible:
		return

	# 1. 扣血
	blood -= attack_blood

	# 2. 击退（立即施加，与闪红同时发生）
	if attack_direction != Vector2.ZERO:
		velocity = attack_direction.normalized() * knockback_force
	else:
		var dir = -Vector2.RIGHT if player_sprite.flip_h else Vector2.RIGHT
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
	player_sprite.modulate = Color(1, 0.5, 0.5)  # 偏红
	await get_tree().create_timer(0.5).timeout
	player_sprite.modulate = Color.WHITE
	
	Camera.add_trauma(0.8)
	
	# 4. 无敌状态（防止连续受伤）
	is_invincible = true
	await get_tree().create_timer(invincible_duration).timeout
	is_invincible = false

# ============================================================
# 10. 帧处理
# ============================================================
func _process(delta: float) -> void:
	# 10.1 更新手持物品
	var item_id = InventoryBar._get_item_id()
	var item_texture = InventoryBar._get_item_texture()

	if item_texture:
		if item_id in InventoryManager.no_scale:
			item.set_item_texture(load(item_texture), false)
		else:
			item.set_item_texture(load(item_texture))
	else:
		item.set_item_texture(null)

	# 10.2 根据角色动画帧调整物品位置
	var animation_name = player_sprite.animation
	var frame = player_sprite.frame
	var anim_data = item_frame.get(animation_name)

	if last_position:
		item.position = last_position

	if anim_data != null:
		var action = anim_data.get(frame)
		if action != null:
			item.position = Vector2(action[0], action[1])
			last_position = Vector2(action[0], action[1])
			item.visible = action[2]

	# 10.3 鼠标点击移动
	if is_moving:
		click_move()

# ============================================================
# 11. 鼠标点击移动逻辑
# ============================================================
func click_move():
	# 不再打断攻击（允许移动中攻击）
	var current_pos = global_position
	var direction = (target_position - current_pos).normalized()

	if current_pos.distance_to(target_position) < 2.0:
		is_moving = false
		velocity = Vector2.ZERO
		return

	velocity = direction * move_speed

	if velocity.x != 0:
		VisualContainer.transform.x = Vector2(1, 0) if velocity.x > 0 else Vector2(-1, 0)

	if player_sprite.animation != "walk":
		player_sprite.play("walk", anim_speed)

	position_x = global_position.x
	position_y = global_position.y

	move_and_slide()

	if velocity.length() < 1.0:
		is_moving = false
		blood -= 5
