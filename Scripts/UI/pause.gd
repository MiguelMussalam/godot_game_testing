extends Node

func _unhandled_input(event):
	if event is InputEvent:
		if Input.is_action_just_pressed('quit'):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().paused = true
		elif Input.is_action_just_pressed("click") and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_tree().paused = false
