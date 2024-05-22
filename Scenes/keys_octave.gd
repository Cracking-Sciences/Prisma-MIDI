extends Control

var keys: Array = []
var height = 300.0
var width = 400.0
var white_gap_ratio = 0.1 			# leave some gap between keys
var black_height_ratio = 0.70 		# compare to single white key
var black_width_ratio = 0.65 		# compare to single white key

const key_scence= preload("res://Scenes/key.tscn")
# Called when the node enters the scene tree for the first time.

func _ready():
	for i in range(12):
		var new_key = key_scence.instantiate()
		if i in [1,3,6,8,10]:
			new_key.color = Color(0.1,0.1,0.1)
			new_key.start_color = new_key.color
			new_key.z_index = 1
		else:
			new_key.color = Color(0.9,0.9,0.9)
			new_key.start_color = new_key.color
			new_key.z_index = 0
		add_child(new_key)
		keys.append(new_key)
	resize()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func resize():
	var white_width = width / 7
	var white_height = height
	var black_width = white_width * black_width_ratio
	var black_height = white_height * black_height_ratio
	var twelve_equal = width / 12
	var white_gap = white_width * white_gap_ratio
	# place keys:
	var white_count = 0
	for i in range(12):
		var color_rect = keys[i]
		if i in [1, 3, 6, 8, 10]:
			color_rect.size = Vector2(black_width, black_height)
			color_rect.position = Vector2((i+0.5) * twelve_equal - black_width / 2, 0)
			color_rect.move_to_front()

		else:
			color_rect.size = Vector2(white_width - white_gap, white_height)
			color_rect.position = Vector2(white_count * white_width, 0)
			white_count += 1
