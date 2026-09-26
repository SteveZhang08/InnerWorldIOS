extends RichTextLabel

var time
var date

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	date = GlobalTime.get_date_string()
	time = GlobalTime.get_time_string()

func convert_date_manual(input_date: String) -> String:
	var parts = input_date.split("-")
	if parts.size() != 3:
		return "无效日期格式" # 简单的错误处理
	var year = parts[0]
	var month = parts[1]
	var day = parts[2]
	return "斯威特历 %s年%s月%s日" % [year, month, day]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if time != GlobalTime.get_time_string():
		time = GlobalTime.get_time_string()
		date = GlobalTime.get_date_string()
		text = convert_date_manual(date) + "\n" + time
