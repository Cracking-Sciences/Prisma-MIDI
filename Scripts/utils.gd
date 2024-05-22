extends Node

# macros
const NoteOn = 144
const NoteOff = 128
const ProgramChange = 192
const ControlChange = 176

# utils
func sleep(seconds):
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = seconds
	timer.one_shot = true
	timer.start()
	await timer.timeout
	timer.queue_free()

