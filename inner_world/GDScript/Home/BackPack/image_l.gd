extends TextureRect

func play_disappear_animation(
	shake_intensity: float = 6.0,    # 抖动幅度（像素）
	shake_duration: float = 0.05,    # 每步抖动持续时间（秒）
	shake_steps: int = 6,            # 抖动次数（越多抖得越久）
	fade_duration: float = 0.8       # 淡出持续时间（秒）
):
	var tween = create_tween()
	var start_pos = position

	# ---- 生成随机抖动偏移序列 ----
	var offsets = []
	for i in range(shake_steps):
		var offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		offsets.append(offset)

	# ---- 抖动阶段 ----
	for offset in offsets:
		tween.tween_property(self, "position", start_pos + offset, shake_duration)

	# ---- 回到原位（短暂过渡） ----
	tween.tween_property(self, "position", start_pos, shake_duration * 2)

	# ---- 淡出消失 ----
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)

	# ---- 动画完成后隐藏节点（可选） ----
	tween.tween_callback(func(): visible = false)
	
