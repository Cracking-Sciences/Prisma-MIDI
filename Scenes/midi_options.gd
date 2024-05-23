extends Node2D


# Called when the node enters the scene tree for the first time.

var selected_midi_out_name = ""
var selected_midi_in_name = ""
var time = 0.0
var message_out: PackedByteArray
var message_in: PackedByteArray

@onready
var midi_out = $MidiOut
@onready
var midi_in = $MidiIn
@onready
var select_midi_out = $HBoxContainerWidgets/SelectMidiOut
@onready
var select_midi_in = $HBoxContainerWidgets/SelectMidiIn


func _ready():
	refresh()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += delta

func refresh():
# button refresh
# midi out
	select_midi_out.clear()
	select_midi_out.text = "Select MIDI Output"
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
	select_midi_in.text = "Select MIDI Input"
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
func _on_button_pressed():
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
