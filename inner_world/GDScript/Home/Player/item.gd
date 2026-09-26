extends Sprite2D

var target_size: Vector2 = Vector2(32, 32)

var target_x = 32

@onready var info = get_node("/root/Main/UI/Panel/info")

func set_item_texture(new_texture: Texture2D,scaled=true):
	texture = new_texture
	if texture:
		var original_size = texture.get_size()
		if scaled:
			if original_size.x > target_x:
				scale = Vector2(target_x, original_size.y) / original_size
			else:
				scale = Vector2(2.01,2.01)
			var x = target_x/original_size.x
			scale = Vector2(x, x)
		else:
			scale = Vector2(1, 1)
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		offset = Vector2(0, -original_size.y)
		position = Vector2(28,35)
	else:
		texture = null
	info.text = str(scale)
