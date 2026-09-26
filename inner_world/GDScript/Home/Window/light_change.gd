extends PointLight2D

# ---------- 可调参数 ----------
@export var sun_energy: float = 1
@export var sun_color: Color = Color(1.0, 0.95, 0.85)   # 暖白

@export var moon_energy: float = 0.5
@export var moon_color: Color = Color(0.7, 0.8, 1.0)    # 冷蓝

var orp

# ---------- 生命周期 ----------
func _ready():
	_update_light(GlobalTime.get_time_hours())
	orp = global_position
	visible = true

func _process(delta):
	_update_light(GlobalTime.get_time_hours())

# ---------- 核心更新 ----------
func _update_light(hours: float):
	var target_energy: float
	var target_color: Color

	# 定义时间节点（24小时制）
	const DAWN_START = 5.0     # 黎明开始
	const DAY_START = 6.0      # 白昼开始
	const DUSK_START = 18.0    # 黄昏开始
	const NIGHT_START = 20.0   # 夜晚开始

	if hours >= DAY_START and hours < DUSK_START:
		# 白昼：太阳全亮
		target_energy = sun_energy
		target_color = sun_color
	elif hours >= DUSK_START and hours < NIGHT_START:
		# 黄昏：从太阳过渡到月亮
		var t = (hours - DUSK_START) / (NIGHT_START - DUSK_START)   # 0 → 1
		target_energy = lerp(sun_energy, moon_energy, t)
		target_color = sun_color.lerp(moon_color, t)
	elif hours >= NIGHT_START or hours < DAWN_START:
		# 夜晚：月亮全亮
		target_energy = moon_energy
		target_color = moon_color
	else:
		# 黎明：从月亮过渡到太阳（5:00 ~ 6:00）
		var t = (hours - DAWN_START) / (DAY_START - DAWN_START)   # 0 → 1
		target_energy = lerp(moon_energy, sun_energy, t)
		target_color = moon_color.lerp(sun_color, t)

	# 应用属性
	energy = target_energy
	color = target_color
