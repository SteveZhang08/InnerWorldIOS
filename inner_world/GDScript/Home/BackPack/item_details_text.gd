extends RichTextLabel

# 显示文本，直接完整显示
func show_text(new_text: String, font_size: int):
	# 设置字体大小
	add_theme_font_size_override("normal_font_size", font_size)
	add_theme_color_override("default_color", Color.BLACK)
	# 直接显示完整文本
	text = new_text
	# 确保所有字符可见（-1 表示显示全部）
	visible_characters = -1
