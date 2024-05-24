extends Node2D


# Called when the node enters the scene tree for the first time.

var selected_midi_out_name = ""
var selected_midi_in_name = ""
var time = 0.0
var message_out: PackedByteArray
var message_in: PackedByteArray
var smf_result: SMF.SMFParseResult = null

@onready
var midi_out = $MidiOut
@onready
var midi_in = $MidiIn
@onready
var select_midi_out = $VBoxContainer/HBoxContainerDevice/SelectMidiOut
@onready
var select_midi_in = $VBoxContainer/HBoxContainerDevice/SelectMidiIn
@onready
var file_dialog = $FileDialog
@onready
var file_name = $VBoxContainer/HBoxContainerScore/TextFileName
@onready
var button_select_tracks = $VBoxContainer/HBoxContainerScore/ButtonSelectTracks
@onready
var popup_menu_select_tracks = $VBoxContainer/HBoxContainerScore/ButtonSelectTracks/PopupMenuSelectTracks
@onready
var select_tracks_container = $VBoxContainer/HBoxContainerScore/ButtonSelectTracks/PopupMenuSelectTracks/ScrollContainer/VBoxContainer
@onready
var button_generate_map = $VBoxContainer/HBoxContainerScore/ButtonGenerateMap

func _ready():
	refresh()
	get_viewport().files_dropped.connect(on_files_dropped)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += delta

func refresh():
# button refresh
# midi out
	select_midi_out.clear()
	select_midi_out.text = "MIDI Output"
	var num_ports = MidiOut.get_port_count()
	var have_selected = false
	for i in range(num_ports):
		var port_name = MidiOut.get_port_name(i)
		select_midi_out.add_item(port_name)
		if port_name == selected_midi_out_name:
			select_midi_out.selected = i
			have_selected = true
	if not have_selected and num_ports > 0:
		select_midi_out.selected = 0
		on_select_midi_out(0)
# midi in
	select_midi_in.clear()
	select_midi_in.text = "MIDI Input"
	num_ports = MidiIn.get_port_count()
	have_selected = false
	for i in range(num_ports):
		var port_name = MidiIn.get_port_name(i)
		select_midi_in.add_item(port_name)
		if port_name == selected_midi_in_name:
			select_midi_in.selected = i
			have_selected = true
	if not have_selected and num_ports > 0:
		select_midi_in.selected = 0
		on_select_midi_in(0)

func on_select_midi_out(index):
	selected_midi_out_name = select_midi_out.get_item_text(index)
	midi_out.close_port()
	midi_out.open_port(index)

func on_select_midi_in(index):
	selected_midi_in_name = select_midi_in.get_item_text(index)
	midi_in.close_port()
	midi_in.open_port(index)
	midi_in.ignore_types(false, false, false)
	if midi_in.midi_message.is_connected(on_midi_message):
		midi_in.midi_message.disconnect(on_midi_message)
	midi_in.midi_message.connect(on_midi_message)

func send_midi_message(data: Array, target: MidiOut = null):
	if target == null:
# TODO: internal music instrument
		return
	message_out.clear()
	for item in data:
		message_out.push_back(item)
	midi_out.send_message(message_out)

# demo
func on_send_some_notes():
	# send_midi_message([Utils.ProgramChange,5], midi_out)
	# send_midi_message([Utils.ControlChange,7,100], midi_out)
	var note = randi_range(20,80)
	send_midi_message([Utils.NoteOn, note, 90], midi_out)
	await Utils.sleep(0.5)
	send_midi_message([Utils.NoteOff, note, 40], midi_out)

signal get_midi_in_message(deltatime, message)

func on_midi_message(deltatime, message):
	# print(deltatime)
	# print(message)
	get_midi_in_message.emit(deltatime, message)

func on_open_file_dialog():
	file_dialog.popup_centered()

func on_files_dropped(files):
	on_file_dialog_selected(files[0])

func on_file_dialog_selected(path):
	var smf_reader: = SMF.new( )
	smf_result = smf_reader.read_file(path)
	if smf_result == null or smf_result.error != OK:
		file_name.text = "[Invalid] (drag file here)"
		smf_result = null
		return
	file_name.text = Utils.shorten_text_with_ellipsis(path.get_file(), 40)
	update_popup_menu_select_tracks(smf_result.data.tracks)


func on_button_select_tracks_pressed():
	popup_menu_select_tracks.position = button_select_tracks.position + Vector2(0,80)
	popup_menu_select_tracks.popup()

func update_popup_menu_select_tracks(tracks:Array[SMF.MIDITrack]):
	for child in select_tracks_container.get_children():
		if child.name != "CheckBoxTemplate":
			select_tracks_container.remove_child(child)
			child.queue_free()
	for track in tracks:
		var new_checkbox = select_tracks_container.get_node("CheckBoxTemplate").duplicate()
		new_checkbox.name = str(track.track_number)
		new_checkbox.text = Utils.get_track_name(track)
		new_checkbox.track_number = track.track_number
		new_checkbox.button_pressed = true
		new_checkbox.visible = true
		select_tracks_container.add_child(new_checkbox)

func get_selected_tracks() -> Array[SMF.MIDITrack]:
	var array:Array[SMF.MIDITrack] = []
	for child in select_tracks_container.get_children():
		if child.name == "CheckBoxTemplate":
			continue
		if child.button_pressed:
			array.append(smf_result.data.tracks[child.track_number])
	return array

signal generate_map

func on_button_generate_map():
	generate_map.emit()