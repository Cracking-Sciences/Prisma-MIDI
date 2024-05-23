extends Node

# macros
const NoteOn = 144
const NoteOff = 128
const ProgramChange = 192
const ControlChange = 176


# ui
const vertical_progression_slider_width = 20
const horizontal_widgets_width = 20

# utils
func sleep(seconds):
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = seconds
	timer.one_shot = true
	timer.start()
	await timer.timeout
	timer.queue_free()


func shorten_text_with_ellipsis(text: String, max_length: int) -> String:
	if text.length() <= max_length:
		return text
		
	var ellipsis = "..."
	var part_length = int((max_length - ellipsis.length()) / 2)
		
	var first_part = text.substr(0, part_length)
	var last_part = text.substr(text.length() - part_length, part_length)
		
	return first_part + ellipsis + last_part