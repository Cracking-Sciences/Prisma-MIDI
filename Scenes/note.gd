class_name Note
extends Panel

var note = 60
var velocity = 100
var track_number = 0
var send_to_output = true
var strict = false

var falling_speed = 1 # % area.y per second
var falling_ratio = 0
var length_ratio = 0.1


var is_falling = false
var fell_below = false # and should release
var tail_cut = false

var triggered = false
var released = false

var parent = null

var is_prisma = false
@onready var diamond_marker = $DiamondMarker

func _ready():
	if note % 12 in [1,3,6,8,10]:
		color_mul(1.0, 1.2)
	diamond_marker.visible = is_prisma
	reshape_diamond()
	# Compensate parent modulate so diamond always renders in its own pure color
	var m = modulate
	diamond_marker.modulate = Color(
		(1.0 / m.r) if m.r > 0.001 else 1.0,
		(1.0 / m.g) if m.g > 0.001 else 1.0,
		(1.0 / m.b) if m.b > 0.001 else 1.0,
		(1.0 / m.a) if m.a > 0.001 else 1.0,
	)

func _process(delta):
	if is_falling and not fell_below:
		var delta_ratio = falling_speed * delta
		falling_ratio += delta_ratio
		reposition_y()
		if length_ratio + 1 + delta_ratio < falling_ratio:
			fell_below = true


func reposition_y():
	size.y = parent.custom_minimum_size.y * length_ratio
	position.y = parent.custom_minimum_size.y * falling_ratio - size.y
	# Diamond moves with parent automatically; no redraw needed here

func reshape_diamond():
	if diamond_marker == null or not diamond_marker.visible:
		return
	var half = size.x / 2.0
	# Place origin at diamond center so scale animates outward from center
	diamond_marker.position = Vector2(half, size.y)
	diamond_marker.scale = Vector2.ONE
	diamond_marker.polygon = PackedVector2Array([
		Vector2(0.0,  -half), # 顶点
		Vector2(half,  0.0),  # 右顶点
		Vector2(0.0,   half), # 底点
		Vector2(-half, 0.0),  # 左顶点
	])

func cut_tail(latency_ratio = 0.0):
	if not tail_cut:
		length_ratio = max(falling_ratio - latency_ratio, 0.01) # lower bound, make it visible
		reposition_y()
		reshape_diamond() # size.y changed, bottom anchor moved
		tail_cut= true
		return true
	return false

func set_triggered():
	triggered = true
	if diamond_marker != null and diamond_marker.visible:
		_play_diamond_exit()
	# modulate = (modulate * 1.3).clamp(Color(0, 0, 0, 0), Color(1, 1, 1, 1))

func _play_diamond_exit():
	var marker = diamond_marker
	diamond_marker = null  # Clear ref so note no longer touches this node
	# Reparent to note_area keeping global transform → marker stays in place while note falls
	marker.reparent(parent, true)
	marker.color = Color.WHITE
	marker.scale = Vector2.ONE * 2
	marker.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var tween = marker.create_tween()  # Tween owned by marker, survives note being freed
	tween.tween_property(marker, "scale", Vector2(4.0, 0.0), 0.2)
	tween.parallel().tween_property(marker, "modulate:a", 0.0, 0.2)
	tween.tween_callback(marker.queue_free)

func set_released():
	if released:
		return
	triggered = true
	released = true
	color_mul(0.5, 0.75)

func color_mul(mul: float, a_mul: float = 1):
	var a_backup = modulate.a
	modulate = (modulate * mul).clamp(Color(0, 0, 0, 0), Color(1, 1, 1, 1))
	modulate.a = a_backup * a_mul
