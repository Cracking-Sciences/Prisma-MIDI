extends Panel

var note = 60

var falling_speed = 1 # % area.y per second
var falling_ratio = 0
var length_ratio = 0.1


var is_falling = false
var fell_below = false
var tail_cut = false

# Called when the node enters the scene tree for the first time.
func _ready():
	reposition_y()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_falling and not fell_below:
		falling_ratio += falling_speed * delta
		reposition_y()
		if length_ratio + 1.0 < falling_ratio:
			fell_below = true


func reposition_y():
	size.y = get_viewport_rect().size.y * length_ratio
	position.y = get_viewport_rect().size.y * falling_ratio - size.y

func cut_tail():
	if not tail_cut:
		length_ratio = falling_ratio
		reposition_y()
		tail_cut= true
