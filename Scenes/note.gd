extends Panel

var note = 60
var velocity = 100
var track_number = 0

var falling_speed = 1 # % area.y per second
var falling_ratio = 0
var length_ratio = 0.1


var is_falling = false
var fell_below = false # and should release
var tail_cut = false

var triggered = false
var released = false

var parent = null

func _ready():
	pass

func _process(delta):
	if is_falling and not fell_below:
		var delta_ratio = falling_speed * delta
		falling_ratio += delta_ratio
		reposition_y()
		if length_ratio + 1.0 < falling_ratio:
			fell_below = true


func reposition_y():
	size.y = parent.custom_minimum_size.y * length_ratio
	position.y = parent.custom_minimum_size.y * falling_ratio - size.y

func cut_tail(latency_ratio = 0.0):
	if not tail_cut:
		length_ratio = falling_ratio - latency_ratio
		reposition_y()
		tail_cut= true

func set_triggered():
	triggered = true
	# modulate = (modulate * 1.3).clamp(Color(0, 0, 0, 0), Color(1, 1, 1, 1))

func set_released():
	if released:
		return
	triggered = true
	released = true
	modulate = (modulate * 0.5).clamp(Color(0, 0, 0, 0), Color(1, 1, 1, 1))

func brighter():
	modulate = (modulate * 1.3).clamp(Color(0, 0, 0, 0), Color(1, 1, 1, 1))