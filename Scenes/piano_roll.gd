extends Control

var events_and_status: Utils.EventsAndStatus = null
var ready_to_play = false
var is_playing = false
var judge_line_ratio = 0.9 # notes can be hit out of order when falling over this ratio
var play_speed = 1.0
var fall_speed = 1.0
var auto_play = true
var stopped_prisma_note_count:int = 0
var prisma_tracks = []

@onready
var piano_roll_container = $PianoRollContainer
@onready
var note_area = $PianoRollContainer/NoteArea
@onready
var note_template = $PianoRollContainer/NoteArea/note
@onready
var piano = $PianoRollContainer/Piano

var parent = null



@onready
var judge_line_slider = $PianoRollContainer/HBoxContainerWidgets/HSliderJudgeLine
@onready
var height_slider = $PianoRollContainer/HBoxContainerWidgets/HSliderHeight
@onready
var octaves_slider= $PianoRollContainer/HBoxContainerWidgets/HSliderOctaves
@onready
var black_width_slider= $PianoRollContainer/HBoxContainerWidgets/HSliderBlackWidth
@onready
var black_height_slider= $PianoRollContainer/HBoxContainerWidgets/HSliderBlackHeight
@onready
var middle_octave_slider= $PianoRollContainer/HBoxContainerWidgets/HSliderMiddleOctave
@onready
var play_speed_slider= $PianoRollContainer/HBoxContainerPlay/HSliderPlaySpeed
@onready
var fall_speed_slider = $PianoRollContainer/HBoxContainerPlay/HSliderFallSpeed

@onready
var text_bpm = $PianoRollContainer/HBoxContainerPlay/LabelBPM
@onready
var button_play = $PianoRollContainer/HBoxContainerPlay/ButtonPlay
@onready
var progress_slider = $PianoRollContainer/HBoxContainerPlay/HSliderProgress

@onready
var buttom_mask = $ColorRectMask
@onready
var piano_mask = $PianoRollContainer/Piano/ColorRectPianoMask

# Called when the node enters the scene tree for the first time.
func _ready():
	resize_timer = Timer.new()
	add_child(resize_timer)
	resize_timer.wait_time = 0.3
	resize_timer.one_shot = true
	resize_timer.timeout.connect(set_all)
	set_all()
	resize_timer.start()

var last_delta
func _process(delta):
	if stopped_prisma_note_count > 0:
		note_is_falling_all(false)
		return
	if (not is_playing) or (not ready_to_play) or (events_and_status == null):
		return

	events_and_status.position += float(events_and_status.timebase) * delta * events_and_status.seconds_to_timebase * play_speed
	progress_slider.value = events_and_status.position / events_and_status.last_position * 100

	var length: int = len(events_and_status.events)
	if length < events_and_status.event_pointer:
		play_stop(false)
		return
	var current_position: int = int(ceil(events_and_status.position))

	while events_and_status.event_pointer < length:
		var event_chunk: Utils.MIDIEventChunkPlus = events_and_status.events[events_and_status.event_pointer]
		if current_position <= event_chunk.midi_event_chunk.time:
			break
		events_and_status.event_pointer += 1
		# maybe bpm change
		if (events_and_status.process_control_event(event_chunk) == "set tempo"):
			text_bpm.text = "BPM: " + "%.2f" % (events_and_status.tempo * play_speed)
		var event = event_chunk.midi_event_chunk.event

		match event.type:
			SMF.MIDIEventType.note_off:
				# print("note off, ", event.note)
				var note_time = event_chunk.midi_event_chunk.time
				var latency_time = float(events_and_status.position - note_time) / events_and_status.ticks_per_second # real time
				var latency_ratio = fall_speed * latency_time
				cut_tail(event.note, latency_ratio)
			SMF.MIDIEventType.note_on:
				# print("note on, ", event.note, " ", event.velocity)
				var note_time = event_chunk.midi_event_chunk.time
				var latency_time = float(events_and_status.position - note_time) / events_and_status.ticks_per_second # real time
				var latency_ratio = fall_speed * latency_time
				add_note_child(event.note, event.velocity, event_chunk.track_number, latency_ratio)
			_:
				pass
	last_delta = delta
	do_func_to_all_note_children([trigger_from_note_child, clear_fell_below_note_child])


# for notes
var note_children_map: Dictionary = {}

func do_func_to_all_note_children(funcs: Array[Callable]):
	var note_children_list = note_children_map.values()
	for note_children in note_children_list:
		for note_child in note_children:
			for f in funcs:
				f.call(note_children, note_child)

func clear_all_note_children():
	var note_children_list = note_children_map.values()
	for note_children in note_children_list:
		for note_child in note_children:
			note_on_off_note_child(false, note_child)
			note_area.remove_child(note_child)
			note_child.queue_free()
	note_children_map.clear()
	prisma_links.clear()
	stopped_prisma_note_count = 0

func note_off_all_note_children():
	var note_children_list = note_children_map.values()
	for note_children in note_children_list:
		for note_child in note_children:
			note_on_off_note_child(false, note_child)

func clear_fell_below_note_child(note_children, note_child):
	if note_child == null:
		return
	if note_child.fell_below:
		if note_child.track_number not in prisma_tracks:
			if not note_child.released:
				note_on_off_note_child(false, note_child)
				note_child.released = true
			if note_child.released:
				note_children.erase(note_child)
				note_area.remove_child(note_child)
				note_child.queue_free()

func add_note_child(note, velocity, track_number = 0, latency_ratio = 0.0):
	var note_child = note_template.duplicate()
	note_child.parent = note_area
	note_child.note = note
	note_child.velocity = velocity
	note_child.track_number = track_number
	note_child.falling_speed = fall_speed
	note_child.falling_ratio = latency_ratio # process-delta latency
	note_child.length_ratio = 1000.0 # long enough
	note_child.is_falling = (stopped_prisma_note_count == 0)
	note_child.modulate = Utils.get_color_for_note(note, velocity, track_number)
	note_child.reposition_y()
	note_reposition_x(null, note_child)
	if note not in note_children_map:
		note_children_map[note] = [note_child]
	else:
		note_children_map[note].append(note_child)
	note_area.add_child(note_child)
	note_child.visible = true

func cut_tail(note, latency_ratio = 0.0):
	if note in note_children_map:
		var note_children = note_children_map[note]
		for note_child in note_children:
			note_child.cut_tail(latency_ratio)

func note_reposition_x(_note_children, note_child):
	if note_child == null:
		return
	note_child.position.x = piano.get_note_x(note_child.note)
	note_child.size.x = piano.get_note_width()

var note_is_falling_all_last_action = false
func note_is_falling_all(is_falling = false):
	if note_is_falling_all_last_action == false and is_falling == false:
	# performance optimization
		return
	var note_children_list = note_children_map.values()
	for note_children in note_children_list:
		for note_child in note_children:
			note_child.is_falling = is_falling
	note_is_falling_all_last_action = is_falling

func trigger_from_note_child(_note_children, note_child):
	if note_child == null:
		return
	if not note_child.triggered:
		if note_child.falling_ratio >= 1: # hit the end
			if note_child.track_number in prisma_tracks:
				stopped_prisma_note_count += 1
				# note_is_falling_all(false)
			else:
				note_on_off_note_child(true, note_child)
				note_child.set_triggered()


func note_on_off_note_child(is_on, note_child):
	# TODO: precice trigger time (likely a play buffer)
	# var latency_ratio = max(fall_speed * last_delta - (note_child.falling_ratio - 1), 0)
	# var latency_time = latency_ratio / fall_speed
	if is_on:
		var key = piano.get_key(note_child.note)
		if key == null and parent != null:
			parent.note_on_off(true, note_child.note, note_child.velocity)
		else:
			key.activate(note_child.velocity, note_child.modulate)
		return
	else:
		var key = piano.get_key(note_child.note)
		if key == null and parent != null:
			parent.note_on_off(false, note_child.note, 100)
		else:
			key.deactivate(100)
		return



# func _notification(what):
# 	if what == NOTIFICATION_RESIZED:
# 		if piano_roll_container == null:
# 			return
# 		set_all()

var resize_timer: Timer

func on_resized():
	if resize_timer != null:
		resize_timer.start()

func set_all():
	if piano_roll_container == null:
		return
	piano.size.x = get_viewport_rect().size.x
	judge_line_slider.custom_minimum_size.y = Utils.horizontal_widgets_width
	change_judge_line(judge_line_slider.value)
	piano_roll_container.custom_minimum_size = get_viewport_rect().size
	note_area.custom_minimum_size.x = get_viewport_rect().size.x

	height_slider.custom_minimum_size.y = Utils.horizontal_widgets_width
	change_piano_height(height_slider.value)

	octaves_slider.custom_minimum_size.y = Utils.horizontal_widgets_width
	change_piano_octaves(octaves_slider.value)

	black_width_slider.custom_minimum_size.y = Utils.horizontal_widgets_width
	change_piano_black_width(black_width_slider.value)

	black_height_slider.custom_minimum_size.y = Utils.horizontal_widgets_width
	change_piano_black_height(black_height_slider.value)

	middle_octave_slider.custom_minimum_size.y = Utils.horizontal_widgets_width
	change_piano_middle_octave(middle_octave_slider.value)

	play_speed_slider.custom_minimum_size.y = Utils.horizontal_widgets_width
	change_play_speed(play_speed_slider.value)

	fall_speed_slider.custom_minimum_size.y = Utils.horizontal_widgets_width
	change_fall_speed(fall_speed_slider.value)

	progress_slider.custom_minimum_size.x = piano_roll_container.custom_minimum_size.x - 700
	progress_slider.custom_minimum_size.y = Utils.horizontal_widgets_width

	set_referece_lines()
	do_func_to_all_note_children([note_reposition_x])

	change_buttom_mask_size()

func change_buttom_mask_size():
	var widgets = $PianoRollContainer/HBoxContainerWidgets
	buttom_mask.size.y = widgets.size.y * 2
	buttom_mask.size.x = get_viewport_rect().size.x
	buttom_mask.position.x = 0
	buttom_mask.position.y = get_viewport_rect().size.y - buttom_mask.size.y

	piano_mask.color = buttom_mask.color

func change_piano_height(ratio):
	# and note_area, judgeline
	var height = get_viewport_rect().size.y * ratio
	piano.custom_minimum_size.y = height
	var widgets = $PianoRollContainer/HBoxContainerWidgets
	note_area.custom_minimum_size.y = get_viewport_rect().size.y * (1 - ratio) - widgets.size.y * 2
	note_area.custom_minimum_size.x = get_viewport_rect().size.x
	change_judge_line(judge_line_ratio)
	set_referece_lines()

func change_piano_octaves(num):
	piano.num_octaves = num
	piano.set_octaves()
	piano.resize_keys()
	do_func_to_all_note_children([note_reposition_x])
	middle_octave_slider.value = 0
	$PianoRollContainer/HBoxContainerWidgets/LabelOctaves.text = str(num)
	set_referece_lines()

func change_piano_black_width(ratio):
	piano.black_width_ratio = ratio
	piano.resize_keys()

func change_piano_black_height(ratio):
	piano.black_height_ratio = ratio
	piano.resize_keys()

func change_piano_middle_octave(value):
	piano.middle_octave = value
	piano.set_octaves()
	piano.resize_keys()
	do_func_to_all_note_children([note_reposition_x])
	$PianoRollContainer/HBoxContainerWidgets/LabelOct.text = str(value)

func change_judge_line(ratio):
	judge_line_ratio = ratio
	note_area.get_node("JudgeLine").size.x = note_area.custom_minimum_size.x
	note_area.get_node("JudgeLine").size.y = 1 + get_viewport_rect().size.y / 500
	note_area.get_node("JudgeLine").position.y = note_area.custom_minimum_size.y * (1 - judge_line_ratio)


func change_fall_speed(value):
	fall_speed = value
	$PianoRollContainer/HBoxContainerPlay/LabelFallSpeed.text = str(fall_speed)
	var note_children_list = note_children_map.values()
	for note_children in note_children_list:
		for note_child in note_children:
			note_child.falling_speed = fall_speed

func change_play_speed(value):
	play_speed = value
	if events_and_status != null:
		text_bpm.text = "BPM: " + "%.2f" % (events_and_status.tempo * play_speed)
	$PianoRollContainer/HBoxContainerPlay/LabelPlaySpeed.text = str(play_speed)

var manual_change_is_playing_backup: bool

func manual_change_progress_end(_value):
	if events_and_status != null:
		clear_all_note_children()
		var to_position = progress_slider.value / 100 * events_and_status.last_position
		events_and_status.seek(to_position)
		play_stop(manual_change_is_playing_backup)

func manual_change_progress_start():
	manual_change_is_playing_backup = is_playing
	play_stop(false)

func clear_map():
	clear_all_note_children()
	events_and_status = null
	ready_to_play = false

func generate_map(smf_data:SMF.SMFData, selected_tracks):
	clear_all_note_children()
	events_and_status = Utils.get_events_and_status(smf_data, selected_tracks)
	if events_and_status==null:
		return
	ready_to_play = true

func get_prisma_tracks(_tracks):
	prisma_tracks = _tracks

func play_stop(is_play):
	if is_play and ready_to_play:
		button_play.text = "Stop"
		button_play.button_pressed = true
		is_playing = true
		note_is_falling_all(true)
	else:
		button_play.text = "Play"
		button_play.button_pressed = false
		is_playing = false
		note_is_falling_all(false)
		note_off_all_note_children()
		prisma_links.clear()

var referece_lines: Array

func set_referece_lines():
	for line in referece_lines:
		note_area.remove_child(line)
		line.queue_free()
	referece_lines.clear()
	var reference_xs = piano.get_reference_xs()
	for x in reference_xs:
		var new_line = note_area.get_node("ReferenceLine").duplicate()
		note_area.add_child(new_line)
		referece_lines.append(new_line)
		new_line.visible = true
		new_line.position.x = x
		new_line.position.y = 0
		new_line.size.y = note_area.custom_minimum_size.y
		new_line.size.x = 1 + get_viewport_rect().size.y / 500

var prisma_links: Dictionary = {} # key to linked prisma notes


func manual_note_on_off(is_on, note, velocity, from_key):
	# find a neareast prisma note
	if is_on:
		# print(stopped_prisma_note_count)
		var min_distance = 10000.0 # ratio
		var chosen_note_child = null
		var note_children_list = note_children_map.values()
		var above_judge_line = true
		for note_children in note_children_list:
			for note_child in note_children:
				if note_child.track_number not in prisma_tracks:
					continue
				if note_child.triggered:
					continue
				var weighted_distance
				var vertical_dist_ratio = 1 - note_child.falling_ratio
				if vertical_dist_ratio <= judge_line_slider.value:
					# beneath the judge line
					var horizontal_dist_ratio = abs(piano.get_note_x(note) - note_child.position.x) / piano.size.x
					weighted_distance = horizontal_dist_ratio + vertical_dist_ratio
					above_judge_line = false
				else:
					weighted_distance = vertical_dist_ratio * 1000
				if weighted_distance < min_distance:
					min_distance = weighted_distance
					chosen_note_child = note_child
		# 		print(note_child.note, " ", weighted_distance)
		# print(chosen_note_child.note)
		if chosen_note_child == null:
			# normal action:
			keyless_note_on_off(from_key, is_on, note, velocity)
		else:
			# prisma action:
			var key = piano.get_key(chosen_note_child.note)
			keyless_note_on_off(key, is_on, chosen_note_child.note, velocity, chosen_note_child.modulate)
			chosen_note_child.set_triggered()
			chosen_note_child.brighter()
			if note not in prisma_links:
				prisma_links[note] = []
			prisma_links[note].append(chosen_note_child)

			if chosen_note_child.falling_ratio >= 1:
				stopped_prisma_note_count -= 1
				if stopped_prisma_note_count <= 0:
					stopped_prisma_note_count = 0
					note_is_falling_all(true)
			# print(stopped_prisma_note_count)

			# add length
			if above_judge_line:
				# skip some time
				var skipped_ratio = 1 - judge_line_slider.value - chosen_note_child.falling_ratio
				# all notes skip down!
				note_children_list = note_children_map.values()
				for note_children in note_children_list:
					for note_child in note_children:
						note_child.falling_ratio += skipped_ratio
				# timeline skip
				events_and_status.position += float(events_and_status.timebase) * skipped_ratio / fall_speed * events_and_status.seconds_to_timebase * play_speed
			chosen_note_child.length_ratio += 1 - chosen_note_child.falling_ratio
			chosen_note_child.falling_ratio = 1
	else:
		var key = piano.get_key(note)
		keyless_note_on_off(key, is_on, note, velocity) # normal key should deactivate too
		if note in prisma_links:
			for note_child in prisma_links[note]:
				if note_child != null:
					key = piano.get_key(note_child.note)
					keyless_note_on_off(key, is_on, note_child.note, velocity)
					note_child.set_released()
			prisma_links[note].clear()

func keyless_note_on_off(key, is_on, note, velocity, color = null):
	if key != null:
		if is_on:
			key.activate(velocity, color)
		else:
			key.deactivate(velocity)
	if get_parent() != null:
		get_parent().note_on_off(is_on, note, velocity)