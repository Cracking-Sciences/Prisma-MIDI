extends Panel

var note = 60
var velocity = 100

var falling_speed = 1 # % area.y per second
var falling_ratio = 0
var length_ratio = 0.1


var is_falling = false
var fell_below = false # and should release
var tail_cut = false

var triggered = false


func _ready():
	reposition_y()


func _process(delta):
	if is_falling and not fell_below:
		var delta_ratio = falling_speed * delta
		if falling_ratio <= 1.0 + delta_ratio:
			falling_ratio += delta_ratio
		else:
			length_ratio -= delta_ratio
		reposition_y()
		if length_ratio + 1.0 < falling_ratio:
			fell_below = true


func reposition_y():
	size.y = get_parent().custom_minimum_size.y * length_ratio
	position.y = get_parent().custom_minimum_size.y * falling_ratio - size.y

func cut_tail():
	if not tail_cut:
		length_ratio = falling_ratio
		reposition_y()
		tail_cut= true
