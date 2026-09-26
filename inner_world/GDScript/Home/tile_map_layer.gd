extends TileMapLayer

@onready var sound = $AudioStreamPlayer
@onready var timer = Timer.new()

var min_interval: float = 20   # 最短间隔（秒）
var max_interval: float = 60.0  # 最长间隔（秒）

func _ready():
	# 初始化定时器
	add_child(timer)
	timer.timeout.connect(_on_timer_timeout)
	timer.one_shot = true
	# 设置第一次随机等待
	_reset_timer()

func _reset_timer():
	var wait_time = randf_range(min_interval, max_interval)
	timer.wait_time = wait_time
	timer.start()

func _on_timer_timeout():
	sound.play()
	_reset_timer()
