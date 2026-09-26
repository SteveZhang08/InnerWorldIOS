extends Camera2D

# ============================================================
# 1. 可调参数
# ============================================================
@export var max_offset: float = 20.0      # 最大偏移像素
@export var max_rotation: float = 0.05    # 最大旋转弧度（约 2.86 度）
@export var decay: float = 2.0            # 衰减速度（值越大恢复越快）

# ============================================================
# 2. 状态变量
# ============================================================
var trauma: float = 0.0                   # 冲击值 (0 ~ 1)
var trauma_power: float = 2.0             # 冲击幂次（2 = 平方，使衰减更自然）

# ============================================================
# 3. 公共方法
# ============================================================
# 添加冲击（攻击命中时调用）
func add_trauma(amount: float) -> void:
	trauma = min(trauma + amount, 1.0)

# 立刻停止震动
func stop_shake() -> void:
	trauma = 0.0
	offset = Vector2.ZERO
	rotation = 0.0

# ============================================================
# 4. 核心更新
# ============================================================
func _process(delta: float) -> void:
	if trauma <= 0.0:
		offset = Vector2.ZERO
		rotation = 0.0
		return

	# 衰减冲击值
	trauma = max(trauma - decay * delta, 0.0)

	# 计算当前强度（幂次调整使小冲击更柔和）
	var intensity = pow(trauma, trauma_power)

	# 生成随机偏移
	var noise_x = randf_range(-1.0, 1.0)
	var noise_y = randf_range(-1.0, 1.0)

	offset = Vector2(
		noise_x * max_offset * intensity,
		noise_y * max_offset * intensity
	)

	# 生成随机旋转
	var noise_rot = randf_range(-1.0, 1.0)
	rotation = noise_rot * max_rotation * intensity
