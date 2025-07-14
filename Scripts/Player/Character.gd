extends CharacterBody3D


enum PlayerState { IDLE, WALKING, WALKING_BACKWARDS, RUNNING, STEPPING_UP, STEPPING_DOWN}
var current_state = PlayerState.IDLE

@export var movement_handler: Node
@export var mouse_handler: Node
@export var camera_handler: Node
@export var footsteps_handler: Node
@export var flashlight_handler: Node

func _ready() -> void:
	print(mouse_handler.is_node_ready())
	print(camera_handler.is_node_ready())
	print(flashlight_handler.is_node_ready())
	print(movement_handler.is_node_ready())

func _unhandled_input(event: InputEvent) -> void:
	#mouse_handler._unhandled_input(event)
	#camera_handler._unhandled_input(event)
	#flashlight_handler._unhandled_input(event)
	#movement_handler._unhandled_input(event)
	pass



func _physics_process(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	movement_handler.handle_movement(delta, input_dir)
	camera_handler._handle_fov(delta)
	camera_handler._handle_dof_blur(delta)
	camera_handler._handle_head_bob(delta, input_dir.x)
	footsteps_handler.handle_step(delta, false)
	flashlight_handler._update_flashlight(delta)
	
	move_and_slide()
