extends RichTextLabel

var full_text := ""
@export var typing_speed := 0.025
var finish := true
var typing_tween: Tween

@onready var sound = $input
var playing = false

func show_text(new_text: String, font_size):
	finish = false
	add_theme_font_size_override("normal_font_size", font_size)
	full_text = new_text
	visible_characters = 0
	text = full_text
	# 启动打字并等待完成
	sound.play()
	playing = true
	await _start_typing()
	playing = false
	sound.stop()
	finish = true
	# 返回一个信号表示完成（可选）
	
func _start_typing() -> Signal:
	var total_chars = get_total_character_count()
	if visible_characters >= total_chars:
		# 没有字符，立即发出完成信号
		return Signal()
	
	if typing_tween and typing_tween.is_running():
		typing_tween.kill()
	
	typing_tween = create_tween()
	typing_tween.tween_property(self, "visible_characters", total_chars, typing_speed * (total_chars - visible_characters))
	# ★ 等待 Tween 完成
	await typing_tween.finished
	# 返回一个信号（为了类型一致）
	return Signal()

func skip_typing():
	if typing_tween and typing_tween.is_running():
		typing_tween.kill()
	visible_characters = get_total_character_count()
	playing = false
	sound.stop()
	finish = true

func _process(delta: float) -> void:
	pass
	#if playing:
	#	sound.pitch_scale = randf_range(0.8, 3.0)
