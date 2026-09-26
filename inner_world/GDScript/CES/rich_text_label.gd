extends RichTextLabel

var finish
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	finish = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if finish:
		return
	var time = "Finish Time:\n" + GlobalTime.get_date_string() + " -- " +GlobalTime.get_time_string()
	var str = "感谢你的测试，本次测试已结束。
请将此页面截图发送至SteveZhang08，并报告发现的BUG
调试数据：
" + time +"
再次感谢你的参与"
	text = str
	finish = true
