extends Control

var events_and_status: Utils.EventsAndStatus = null
var ready_to_play = false
var is_playing = false
var judge_line_ratio = 0.9 # notes can be hit out of order when falling over this ratio
var play_speed = 1.0



@onready
var piano_roll_container = $PianoRollContainer
@onready
var note_area = $PianoRollContainer/NoteArea
@onready
var note_template = $PianoRollContainer/NoteArea/note
@onready
var piano = $PianoRollContainer/Piano



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
var button_play = $PianoRollContainer/HBoxContainerPlay/ButtonPlay
@onready
var progress_slider = $PianoRollContainer/HBoxContainerPlay/HSliderProgress


# Called when the node enters the scene tree for the first time.
func _ready():
	# piano_roll_container.set_anchors_preset(Control.LayoutPreset.PRESET_FULL_RECT)
	set_all()

func _process(delta):
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
		events_and_status.process_control_event(event_chunk)
		var event = event_chunk.midi_event_chunk.event
		match event.type:
			SMF.MIDIEventType.note_off:
				# print("note off, ", event.note)
				cut_tail(event.note)
			SMF.MIDIEventType.note_on:
				# print("note on, ", event.note, " ", event.velocity)
				add_note_child(event.note)
			_:
				pass

	clear_fell_below_note_children()

# for notes
var note_children_map: Dictionary = {}
func clear_all_note_children():
	var note_children_list = note_children_map.values()
	for note_children in note_children_list:
		for note_child in note_children:
			note_area.remove_child(note_child)
			note_child.queue_free()
	note_children_map.clear()

func clear_fell_below_note_children():
	var note_children_list = note_children_map.values()
	for note_children in note_children_list:
		for note_child in note_children:
			if note_child.fell_below:
				note_children.erase(note_child)
				note_area.remove_child(note_child)
				note_child.queue_free()

func add_note_child(note):
	var note_child = note_template.duplicate()
	note_child.note = note
	note_child.falling_ratio = 0.0
	note_child.length_ratio = 100.0
	note_child.is_falling = true
	note_child.visible = true
	note_reposition_x(note_child)
	if note not in note_children_map:
		note_children_map[note] = [note_child]
	else:
		note_children_map[note].append(note_child)
	note_area.add_child(note_child)

func cut_tail(note):
	if note in note_children_map:
		var note_children = note_children_map[note]
		for note_child in note_children:
			note_child.cut_tail()

func note_reposition_x(note_child):
	note_child.position.x = piano.get_note_x(note_child.note)
	note_child.size.x = piano.get_note_width()
	

func note_reposition_x_all():
	var note_children_list = note_children_map.values()
	for note_children in note_children_list:
		for note_child in note_children:
			note_reposition_x(note_child)

func note_is_falling_all(is_falling = false):
	var note_children_list = note_children_map.values()
	for note_children in note_children_list:
		for note_child in note_children:
			note_child.is_falling = is_falling

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		if piano_roll_container == null:
			return
		set_all()

func set_all():
	
	judge_line_slider.custom_minimum_size.y = Utils.horizontal_widgets_width
	change_judge_line(judge_line_slider.value)
	piano_roll_container.custom_minimum_size = get_viewport_rect().size
	
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
	
	progress_slider.custom_minimum_size.x = piano_roll_container.custom_minimum_size.x - 600
	progress_slider.custom_minimum_size.y = Utils.horizontal_widgets_width

func change_piano_height(ratio):
	# and note area, judgeline
	var height = get_viewport_rect().size.y * ratio
	piano.custom_minimum_size.y = height
	var widgets = $PianoRollContainer/HBoxContainerWidgets
	note_area.custom_minimum_size.y = get_viewport_rect().size.y * (1 - ratio) - widgets.size.y - 50
	note_area.custom_minimum_size.x = get_viewport_rect().size.x
	change_judge_line(judge_line_ratio)

func change_piano_octaves(num):
	piano.num_octaves = num
	piano.set_octaves()
	piano.resize_keys()
	note_reposition_x_all()
	middle_octave_slider.value = 0
	$PianoRollContainer/HBoxContainerWidgets/LabelOctaves.text = str(num)

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
	note_reposition_x_all()
	$PianoRollContainer/HBoxContainerWidgets/LabelOct.text = str(value)

func change_judge_line(ratio):
	judge_line_ratio = ratio
	note_area.get_node("JudgeLine").size.x = note_area.custom_minimum_size.x
	note_area.get_node("JudgeLine").size.y = 1 + get_viewport_rect().size.y / 500
	note_area.get_node("JudgeLine").position.y = note_area.custom_minimum_size.y * judge_line_ratio

func change_play_speed(value):
	play_speed = value
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

func generate_map(smf_data:SMF.SMFData):
	events_and_status = Utils.get_events_and_status(smf_data)
	ready_to_play = true

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
