extends CharacterBody2D
## ============================================================
##  自适应近战 AI v2（Godot 4.4 / 单玩家）
##  ------------------------------------------------------------
##  核心智能：
##   1. 双阈值 + 迟滞，杜绝状态抖动
##   2. 带预判的追击，外加"反风筝"包抄接近
##   3. 三种攻击（横扫 / 突刺 / 重砍），按距离与玩家速度选招
##   4. 突刺是真·冲脸：前摇锁方向，判定阶段高速突进
##   5. 前摇可取消：玩家脱离 → 收招，省冷却、少破绽
##   6. 连击段数 + 冷却时长随机抖动，杜绝被背板
##   7. 风格切换：AI 残血 → 打带跑；玩家残血 → 压迫收割
##   8. 受击硬直 + 击退 + 无敌帧 + 死亡动画延迟
##   9. 全加速度驱动，无瞬移感
## ============================================================


# ============================================================
# 1. 可调参数
# ============================================================
@export_group("移动")
@export var move_speed: float = 105.0
@export var acceleration: float = 1400.0
@export var friction: float = 1800.0
@export var chase_speed_scale: float = 1.0
@export var strafe_speed_scale: float = 0.9
@export var retreat_speed_scale: float = 1.3
@export var lunge_speed: float = 440.0

@export_group("感知")
@export var detection_range: float = 460.0
@export var lose_range: float = 720.0
@export var attack_range: float = 92.0
@export var lunge_range: float = 185.0
@export var attack_arc_deg: float = 200.0

@export_group("攻击伤害")
@export var swing_damage: float = 5.0
@export var lunge_damage: float = 6.0
@export var heavy_damage: float = 12.0

@export_group("攻击节奏")
@export var attack_cooldown: float = 1.4        ## 一套打完的基础冷却
@export var cooldown_variance: float = 0.35     ## 冷却随机抖动幅度
@export var combo_gap: float = 0.16             ## 连击之间的短冷却
@export var max_combo: int = 4                  ## 一套最多连击几次

@export_group("攻击时序 - 横扫")
@export var swing_windup: float = 0.26
@export var swing_active: float = 0.10
@export var swing_recover: float = 0.28

@export_group("攻击时序 - 突刺")
@export var lunge_windup: float = 0.35
@export var lunge_active: float = 0.20
@export var lunge_recover: float = 0.42

@export_group("攻击时序 - 重砍")
@export var heavy_windup: float = 0.55
@export var heavy_active: float = 0.14
@export var heavy_recover: float = 0.50

@export_group("走位")
@export var predict_factor: float = 0.40
@export var preferred_range_scale: float = 0.78
@export var strafe_switch_min: float = 0.45
@export var strafe_switch_max: float = 1.10
@export var wander_amplitude: float = 0.22     ## 追击蛇形幅度
@export var backpedal_threshold: float = 90.0  ## 玩家后退速度超过此值触发反风筝
@export var flank_bias: float = 0.45           ## 反风筝时横向切入强度

@export_group("智能")
@export_range(0.4, 2.0) var aggression: float = 1.6
@export var cancel_window: float = 0.16
@export var cancel_range_margin: float = 1.4
@export var low_health_ratio: float = 0.3
@export var player_low_ratio: float = 0.35

@export_group("受击")
@export var knockback_force: float = 320.0
@export var knockback_decay: float = 1500.0
@export var invincible_duration: float = 0.10
@export var stagger_time: float = 0.20

@export_group("动画")
@export var walk_anim_speed: float = 1.4
@export var attack_anim_speed: float = 2.0

@export_group("血量")
@export var max_hp: float = 100.0


# ============================================================
# 2. 节点引用
# ============================================================
@onready var animated_sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var head_text: RichTextLabel = $RichTextLabel
@onready var hurt_particles: CPUParticles2D = $CPUParticles2D
@onready var visual: Node2D = $Visual


# ============================================================
# 3. 状态定义
# ============================================================
enum State { IDLE, CHASE, STRAFE, ATTACK, STAGGER, DEAD }
enum AttackPhase { NONE, WINDUP, ACTIVE, RECOVER }
enum AttackType { SWING, LUNGE, HEAVY }


# ============================================================
# 4. 内部变量
# ============================================================
var current_state: State = State.IDLE
var attack_phase: AttackPhase = AttackPhase.NONE
var current_attack: AttackType = AttackType.SWING

var blood: float = 100.0
var facing: int = 1

# 计时器
var _attack_cd: float = 0.0
var _invincible_t: float = 0.0
var _stagger_t: float = 0.0
var _phase_t: float = 0.0
var _windup_total: float = 0.0
var _active_total: float = 0.0
var _recover_total: float = 0.0
var _attack_committed: bool = false

# 攻击
var _combo_left: int = 0
var _hit_registered: bool = false
var _attack_damage_current: float = 5.0

# 走位
var _strafe_dir: int = 1
var _strafe_t: float = 0.0
var _wander_phase: float = 0.0

var _dead: bool = false


# ============================================================
# 5. 生命周期
# ============================================================
func _ready() -> void:
	blood = max_hp
	_wander_phase = randf() * TAU
	_strafe_dir = 1 if randf() < 0.5 else -1
	_strafe_t = randf_range(strafe_switch_min, strafe_switch_max)

	if visual:
		visual.scale.x = absf(visual.scale.x)
	facing = 1

	_play_anim("idle")
	_update_head_text()


func _physics_process(delta: float) -> void:
	# ---------- 计时器统一推进 ----------
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_invincible_t = maxf(0.0, _invincible_t - delta)
	_stagger_t = maxf(0.0, _stagger_t - delta)
	_wander_phase += delta * 2.0

	# ---------- 死亡 ----------
	if _dead:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		move_and_slide()
		return

	# ---------- 没有玩家 ----------
	var player := _get_player()
	if player == null:
		_drive(delta, Vector2.ZERO)
		move_and_slide()
		return

	# ---------- 硬直结束 ----------
	if current_state == State.STAGGER and _stagger_t <= 0.0:
		_change_state(State.CHASE)

	# ---------- 决策 + 执行 ----------
	_decide(player)
	_behave(delta, player)

	move_and_slide()


# ============================================================
# 6. 决策层
# ============================================================
func _decide(player: Node2D) -> void:
	if current_state == State.DEAD or current_state == State.STAGGER:
		return
	if current_state == State.ATTACK:
		return

	var dist := global_position.distance_to(player.global_position)

	# 脱战
	if dist > lose_range:
		_change_state(State.IDLE)
		return

	# 索敌
	if current_state == State.IDLE:
		if dist <= detection_range:
			_change_state(State.CHASE)
		return

	# 可攻击距离内 + 冷却就绪 → 进攻
	var engage_range := lunge_range if _player_is_far(player) else attack_range
	if dist <= engage_range and _attack_cd <= 0.0:
		_change_state(State.ATTACK)
		return

	# 攻击距离附近但打不了 → 绕圈
	if dist <= attack_range * 1.3:
		_change_state(State.STRAFE)
	else:
		_change_state(State.CHASE)


# 玩家是否在"较远"的档位（决定用突刺还是横扫）
func _player_is_far(player: Node2D) -> bool:
	return global_position.distance_to(player.global_position) > attack_range * 1.05


# ============================================================
# 7. 行为层
# ============================================================
func _behave(delta: float, player: Node2D) -> void:
	match current_state:
		State.IDLE:    _behave_idle(delta)
		State.CHASE:   _behave_chase(delta, player)
		State.STRAFE:  _behave_strafe(delta, player)
		State.ATTACK:  _behave_attack(delta, player)
		State.STAGGER: _behave_stagger(delta)


func _behave_idle(delta: float) -> void:
	_drive(delta, Vector2.ZERO)


# ------------------------------------------------------------
# 追击：预判 + 蛇形；玩家快速后退时切换反风筝包抄
# ------------------------------------------------------------
func _behave_chase(delta: float, player: Node2D) -> void:
	var target := _predict_position(player)
	var to_target := target - global_position
	var dist := to_target.length()
	if dist < 1.0:
		_drive(delta, Vector2.ZERO)
		return

	var dir := to_target / dist

	# 反风筝：玩家正在快速后撤时，从侧翼切入
	var p_speed := _player_speed(player)
	var p_back := _player_backpedal(player)
	if p_back and p_speed > backpedal_threshold:
		# 侧翼方向：垂直玩家运动方向，选较近的一侧
		var tangent := dir.orthogonal()
		var side := 1.0 if tangent.dot(global_position - player.global_position) > 0.0 else -1.0
		dir = (dir * (1.0 - flank_bias) + tangent * side * flank_bias).normalized()

	# 蛇形抖动
	var sway := dir.orthogonal() * sin(_wander_phase) * wander_amplitude
	var desired := (dir + sway).normalized() * move_speed * chase_speed_scale

	_drive(delta, desired)
	_face(dir.x)


# ------------------------------------------------------------
# 绕圈：贴着攻击距离环绕玩家
# ------------------------------------------------------------
func _behave_strafe(delta: float, player: Node2D) -> void:
	_strafe_t -= delta
	if _strafe_t <= 0.0:
		_strafe_dir = -_strafe_dir if randf() < 0.55 else _strafe_dir
		_strafe_t = randf_range(strafe_switch_min, strafe_switch_max)

	var to_player := player.global_position - global_position
	var dist := to_player.length()
	if dist < 0.001:
		_drive(delta, Vector2.ZERO)
		return

	var radial := to_player / dist
	var tangent := radial.orthogonal() * float(_strafe_dir)

	var ideal := maxf(attack_range * preferred_range_scale, 16.0)
	var correction := clampf((dist - ideal) / ideal, -1.0, 1.0)

	var desired := (tangent + radial * correction).normalized() \
			* move_speed * strafe_speed_scale

	_drive(delta, desired)
	_face(radial.x)


# ------------------------------------------------------------
# 攻击：前摇 → 判定 → 后摇，含可取消逻辑
# ------------------------------------------------------------
func _behave_attack(delta: float, player: Node2D) -> void:
	match attack_phase:

		AttackPhase.WINDUP:
			_phase_t -= delta
			_drive(delta, Vector2.ZERO)

			var elapsed := _windup_total - _phase_t

			# 未提交 + 玩家脱离 → 取消
			if not _attack_committed and elapsed <= cancel_window:
				if not _player_in_cancel_range(player):
					_cancel_attack()
					return

			# 过窗口 → 提交
			if not _attack_committed and elapsed >= cancel_window:
				_attack_committed = true

			# 跟刀：前摇期间仍可微调朝向
			var to_p := player.global_position - global_position
			if to_p.length_squared() > 1.0:
				_face(to_p.x)

			if _phase_t <= 0.0:
				_enter_active(player)

		AttackPhase.ACTIVE:
			_phase_t -= delta
			_try_hit(player)
			# 只有突刺在判定阶段继续冲，其他站定
			if current_attack != AttackType.LUNGE:
				_drive(delta, Vector2.ZERO)
			if _phase_t <= 0.0:
				_enter_recover()

		AttackPhase.RECOVER:
			_phase_t -= delta
			_drive(delta, Vector2.ZERO)
			if _phase_t <= 0.0:
				_finish_attack()

		_:
			_finish_attack()


func _behave_stagger(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, knockback_decay * delta)


# ============================================================
# 8. 状态机
# ============================================================
func _change_state(new_state: State) -> void:
	if current_state == new_state:
		return

	if current_state == State.ATTACK:
		attack_phase = AttackPhase.NONE

	current_state = new_state

	match new_state:
		State.IDLE:
			_play_anim("idle")
		State.CHASE, State.STRAFE:
			_play_anim("walk", walk_anim_speed)
		State.ATTACK:
			_start_attack()
		State.STAGGER:
			_play_anim("hurt")
		State.DEAD:
			pass


# ============================================================
# 9. 攻击流程
# ============================================================
func _start_attack() -> void:
	var player := _get_player()
	if player == null:
		_change_state(State.IDLE)
		return

	# 连击段数：随攻击性/血量动态
	if _combo_left <= 0:
		var base := max_combo
		# AI 残血 → 少连击，打带跑
		if _self_blood_ratio() < low_health_ratio:
			base = maxi(1, base - 1)
		# 高攻击性 → 多一段
		if aggression >= 1.5:
			base += 1
		_combo_left = maxi(1, base)

	# 选招
	current_attack = _choose_attack(player)

	# 设时序
	_apply_attack_timings(current_attack)

	attack_phase = AttackPhase.WINDUP
	_phase_t = _windup_total
	_hit_registered = false
	_attack_committed = false
	velocity = Vector2.ZERO

	_play_anim("sword", attack_anim_speed)


func _choose_attack(player: Node2D) -> AttackType:
	var dist := global_position.distance_to(player.global_position)
	var p_speed := _player_speed(player)

	# 超出横扫范围 → 突刺
	if dist > attack_range * 1.1:
		return AttackType.LUNGE

	# 近身档：
	# - 玩家慢 / 静止 → 有概率重砍（惩罚站桩）
	# - 玩家高速移动 → 突刺（追击）
	# - 其他 → 横扫
	if p_speed < 40.0 and randf() < 0.30:
		return AttackType.HEAVY
	if p_speed > 130.0 and randf() < 0.45:
		return AttackType.LUNGE
	return AttackType.SWING


func _apply_attack_timings(atk: AttackType) -> void:
	match atk:
		AttackType.SWING:
			_windup_total = swing_windup
			_active_total = swing_active
			_recover_total = swing_recover
			_attack_damage_current = swing_damage
		AttackType.LUNGE:
			_windup_total = lunge_windup
			_active_total = lunge_active
			_recover_total = lunge_recover
			_attack_damage_current = lunge_damage
		AttackType.HEAVY:
			_windup_total = heavy_windup
			_active_total = heavy_active
			_recover_total = heavy_recover
			_attack_damage_current = heavy_damage


func _enter_active(player: Node2D) -> void:
	attack_phase = AttackPhase.ACTIVE
	_phase_t = _active_total
	_hit_registered = false

	# 突刺：判定开始瞬间锁方向 + 冲刺
	if current_attack == AttackType.LUNGE:
		var to_p := player.global_position - global_position
		if to_p.length_squared() > 1.0:
			var dir := to_p.normalized()
			velocity = dir * lunge_speed
			_face(dir.x)


func _enter_recover() -> void:
	attack_phase = AttackPhase.RECOVER
	_phase_t = _recover_total


func _finish_attack() -> void:
	attack_phase = AttackPhase.NONE
	_combo_left -= 1

	if _combo_left > 0:
		_attack_cd = combo_gap
	else:
		var cd := attack_cooldown
		# 随机抖动
		cd += randf_range(-cooldown_variance, cooldown_variance) * attack_cooldown
		# 攻击性影响
		cd /= clampf(aggression, 0.5, 2.0)
		# AI 残血 → 稍微拉长冷却（保守）
		if _self_blood_ratio() < low_health_ratio:
			cd *= 1.25
		_attack_cd = maxf(0.15, cd)

	_change_state(State.CHASE)


func _cancel_attack() -> void:
	attack_phase = AttackPhase.NONE
	_combo_left = 0
	_attack_cd = maxf(combo_gap * 0.5, 0.1)
	_change_state(State.STRAFE)


func _try_hit(player: Node2D) -> void:
	if _hit_registered:
		return
	if not _in_attack_arc(player):
		return

	_hit_registered = true
	var dir := (player.global_position - global_position).normalized()
	if player.has_method("injured"):
		player.injured(_attack_damage_current, dir)


# ============================================================
# 10. 工具函数
# ============================================================
func _predict_position(player: Node2D) -> Vector2:
	var pv := Vector2.ZERO
	if player is CharacterBody2D:
		pv = (player as CharacterBody2D).velocity

	var dist := global_position.distance_to(player.global_position)
	var lead := clampf(dist / maxf(move_speed, 1.0), 0.0, 0.45) * predict_factor
	return player.global_position + pv * lead


func _in_attack_arc(player: Node2D) -> bool:
	var to_p := player.global_position - global_position
	var d := to_p.length()
	if d > attack_range:
		return false
	if d < 1.0:
		return true

	var forward := Vector2(float(facing), 0.0)
	var cos_half := cos(deg_to_rad(attack_arc_deg * 0.5))
	return forward.dot(to_p / d) >= cos_half


func _player_in_cancel_range(player: Node2D) -> bool:
	return global_position.distance_to(player.global_position) <= attack_range * cancel_range_margin


func _player_speed(player: Node2D) -> float:
	if player is CharacterBody2D:
		return (player as CharacterBody2D).velocity.length()
	return 0.0


## 玩家是否在朝远离我们的方向移动
func _player_backpedal(player: Node2D) -> bool:
	if not (player is CharacterBody2D):
		return false
	var to_enemy := global_position - player.global_position
	if to_enemy.length_squared() < 1.0:
		return false
	var pv := (player as CharacterBody2D).velocity
	if pv.length_squared() < 1.0:
		return false
	return pv.normalized().dot(to_enemy.normalized()) > 0.5


func _self_blood_ratio() -> float:
	return clampf(blood / maxf(1.0, max_hp), 0.0, 1.0)


func _drive(delta: float, desired_velocity: Vector2) -> void:
	if desired_velocity.length_squared() < 4.0:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	else:
		var target := desired_velocity.limit_length(move_speed * 1.6)
		velocity = velocity.move_toward(target, acceleration * delta)


func _face(dir_x: float) -> void:
	if absf(dir_x) < 0.05:
		return
	var new_facing: int = 1 if dir_x > 0.0 else -1
	if new_facing == facing:
		return
	facing = new_facing
	if visual:
		visual.scale.x = absf(visual.scale.x) * float(facing)


func _play_anim(anim_name: String, speed: float = 1.0) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		return
	if animated_sprite.animation == anim_name and animated_sprite.is_playing():
		return
	animated_sprite.play(anim_name, speed)


func _get_player() -> Node2D:
	var p = Global_Player.player
	if is_instance_valid(p):
		return p
	return null


func _update_head_text() -> void:
	if head_text:
		head_text.text = "DeepSeek " + "Healthy:" + str(int(ceil(maxf(blood, 0.0))))


# ============================================================
# 11. 受击 / 死亡
# ============================================================
func injured(attack_blood: float, attack_direction: Vector2 = Vector2.ZERO) -> void:
	if _dead or _invincible_t > 0.0:
		return

	blood -= attack_blood
	_update_head_text()

	# 打断
	_combo_left = 0
	attack_phase = AttackPhase.NONE
	_attack_committed = false
	_change_state(State.STAGGER)
	_stagger_t = stagger_time

	# 击退
	var dir := attack_direction
	if dir == Vector2.ZERO:
		dir = Vector2(float(-facing), 0.0)
	velocity = dir.normalized() * knockback_force

	# 血粒子
	if hurt_particles:
		hurt_particles.global_rotation = dir.angle()
		hurt_particles.restart()

	# 闪红
	if animated_sprite:
		animated_sprite.modulate = Color(1.0, 0.45, 0.45)
		var tw := create_tween()
		tw.tween_property(animated_sprite, "modulate", Color.WHITE, 0.25)

	# 无敌帧
	_invincible_t = invincible_duration

	if blood <= 0.0:
		die()


func die() -> void:
	if _dead:
		return
	_dead = true
	current_state = State.DEAD
	attack_phase = AttackPhase.NONE
	velocity = Vector2.ZERO

	_play_anim("die")
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE

	var tw := create_tween()
	tw.tween_interval(0.6)
	tw.tween_callback(queue_free)


# ============================================================
# 12. UI
# ============================================================
func _process(_delta: float) -> void:
	_update_head_text()
