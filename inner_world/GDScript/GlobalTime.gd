extends Node

# ---------- 时间配置 ----------
const START_HOUR = 8                 # 起始时间：8:00
const DAY_SECONDS = 86400            # 一天的秒数
const MONTH_DAYS = 30                # 固定每月30天
const YEAR_MONTHS = 12               # 一年12个月

# ---------- 时间参数 ----------
var elapsed_seconds: float = 0.0     # 从起始时间（8:00）开始经过的游戏秒数
var time_speed: float = 72         # 现实1秒对应游戏72秒（20分钟 = 游戏1天）
var paused: bool = false             # 暂停标志

# 起始日期
var base_year: int = 1373
var base_month: int = 1
var base_day: int = 11

# ---------- 时间更新 ----------
func _process(delta: float) -> void:
	if not paused:
		elapsed_seconds += delta * time_speed

# ---------- 公共函数 ----------

# 获取当前24小时制时间（如 "08:00"）
func get_time_string() -> String:
	var total_sec = START_HOUR * 3600 + elapsed_seconds
	var day_sec = fmod(total_sec, DAY_SECONDS)
	var hours = int(day_sec / 3600)
	var minutes = int(fmod(day_sec, 3600) / 60)
	return "%02d:%02d" % [hours, minutes]

# 获取当前日期（如 "1373-01-11"）
func get_date_string() -> String:
	var total_sec = START_HOUR * 3600 + elapsed_seconds
	var days_passed = int(floor(total_sec / DAY_SECONDS))
	
	var year = base_year
	var month = base_month
	var day = base_day + days_passed
	
	# 处理月份进位
	while day > MONTH_DAYS:
		day -= MONTH_DAYS
		month += 1
		if month > YEAR_MONTHS:
			month = 1
			year += 1
	
	return "%04d-%02d-%02d" % [year, month, day]

func pause_time() -> void:
	paused = true

func resume_time() -> void:
	paused = false

func toggle_pause() -> void:
	paused = !paused

# 获取当前游戏速度倍率（现实1秒 = 游戏X秒）
func get_time_speed() -> float:
	return time_speed

func set_time_speed(speed: float) -> void:
	time_speed = speed

# 获取当前时间的小时数（浮点数，如 18.5 表示 18:30）
func get_time_hours() -> float:
	var total_sec = START_HOUR * 3600 + elapsed_seconds
	var day_sec = fmod(total_sec, DAY_SECONDS)
	return day_sec / 3600.0
