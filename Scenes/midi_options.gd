extends Control


var selected_midi_out_name = ""
var selected_midi_in_name = ""
var time = 0.0
var message_out: PackedByteArray
var message_in: PackedByteArray
var smf_result: SMF.SMFParseResult = null

var disabled_midi_name = "*Disabled"
@onready var midi_out = $MidiOut
@onready var midi_in = $MidiIn
@onready var select_midi_out = $VBoxContainer/HBoxContainerDevice/SelectMidiOut
@onready var select_midi_in = $VBoxContainer/HBoxContainerDevice/SelectMidiIn
@onready var file_dialog = $FileDialog
@onready var file_name = $VBoxContainer/HBoxContainerScore/TextFileName
@onready var button_generate_map = $VBoxContainer/HBoxContainerScore/ButtonGenerateMap

@onready var button_tracks = $VBoxContainer/HBoxContainerScore/ButtonTracks
@onready var popup_panel_tracks = $VBoxContainer/HBoxContainerScore/ButtonTracks/PopupPanelTracks
@onready var tracks_container = $VBoxContainer/HBoxContainerScore/ButtonTracks/PopupPanelTracks/ScrollContainer/TracksContainer

var track_row_scene = preload("res://Scenes/TrackRow.tscn")


func _ready():
	refresh()
	get_viewport().files_dropped.connect(on_files_dropped)


func _process(delta):
	time += delta


func refresh():
	# midi out
	select_midi_out.clear()
	select_midi_out.text = "MIDI Output"
	var num_ports = MidiOut.get_port_count()
	var have_selected = false
	select_midi_out.add_item(disabled_midi_name)
	for i in range(num_ports):
		var port_name = MidiOut.get_port_name(i)
		select_midi_out.add_item(port_name)
		if port_name == selected_midi_out_name:
			select_midi_out.selected = i + 1
			have_selected = true
	if not have_selected:
		select_midi_out.selected = 0
		on_select_midi_out(0)
	# midi in
	select_midi_in.clear()
	select_midi_in.text = "MIDI Input"
	num_ports = MidiIn.get_port_count()
	have_selected = false
	select_midi_in.add_item(disabled_midi_name)
	for i in range(num_ports):
		var port_name = MidiIn.get_port_name(i)
		select_midi_in.add_item(port_name)
		if port_name == selected_midi_in_name:
			select_midi_in.selected = i + 1
			have_selected = true
	if not have_selected:
		select_midi_in.selected = 0
		on_select_midi_in(0)


func on_select_midi_out(index):
	selected_midi_out_name = select_midi_out.get_item_text(index)
	midi_out.close_port()
	if index == 0:
		return
	# index 0 is special for "disabled"
	midi_out.open_port(index - 1)


func on_select_midi_in(index):
	selected_midi_in_name = select_midi_in.get_item_text(index)
	midi_in.close_port()
	if index == 0:
		return
	midi_in.open_port(index - 1)
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
	var note = randi_range(20, 80)
	send_midi_message([Utils.NoteOn, note, 90], midi_out)
	await Utils.sleep(0.5)
	send_midi_message([Utils.NoteOff, note, 40], midi_out)


func on_key_off_all():
	for i in range(0, 127):
		send_midi_message([Utils.NoteOff, i, 40], midi_out)


signal get_midi_in_message(deltatime, message)


func on_midi_message(deltatime, message):
	get_midi_in_message.emit(deltatime, message)


func on_open_file_dialog():
	file_dialog.popup_centered()


func on_files_dropped(files):
	on_file_dialog_selected(files[0])


func on_file_dialog_selected(path):
	var smf_reader := SMF.new()
	smf_result = smf_reader.read_file(path)
	if smf_result == null or smf_result.error != OK:
		file_name.text = "[Invalid] (drag file here)"
		smf_result = null
		return
	file_name.text = Utils.shorten_text_with_ellipsis(path.get_file(), 40)
	update_track_panel(smf_result.data.tracks)


signal generate_map


func on_button_generate_map():
	generate_map.emit()


func _on_select_midi_out_pressed():
	refresh()


func _on_select_midi_in_pressed():
	refresh()


# ── Tracks panel ──────────────────────────────────────────────────────────────

func on_button_tracks_pressed():
	popup_panel_tracks.position = button_tracks.global_position + Vector2(0, button_tracks.size.y)
	popup_panel_tracks.popup()


func update_track_panel(tracks: Array[SMF.MIDITrack]):
	var to_remove = []
	for child in tracks_container.get_children():
		if child.name != "HeaderRow":
			to_remove.append(child)
	for child in to_remove:
		tracks_container.remove_child(child)
		child.queue_free()
	for track in tracks:
		var row: TrackRow = track_row_scene.instantiate()
		row.name = str(track.track_number)
		tracks_container.add_child(row)
		row.track_number = track.track_number
		row.label_track_name.text = Utils.get_track_name(track)
		row.is_enabled = true
		row.is_prisma = false
		row.send_to_output = true


func get_new_enabled_tracks() -> Array:
	var result = []
	for child in tracks_container.get_children():
		if child is TrackRow and child.is_enabled:
			result.append(child.track_number)
	return result


func get_new_prisma_tracks() -> Array:
	var result = []
	for child in tracks_container.get_children():
		if child is TrackRow and child.is_prisma:
			result.append(child.track_number)
	return result


func get_new_silent_tracks() -> Array:
	var result = []
	for child in tracks_container.get_children():
		if child is TrackRow and not child.send_to_output:
			result.append(child.track_number)
	return result
