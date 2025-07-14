extends CharacterBody3D

enum PlayerState { IDLE, WALKING, WALKING_BACKWARDS, RUNNING, STEPPING_UP, STEPPING_DOWN}
var current_state = PlayerState.IDLE

@export var movement_handler: Node
@export var mouse_handler: Node
@export var camera_handler: Node
@export var footsteps_handler: Node
@export var flashlight_handler: Node

func _ready() -> void:
	footsteps_handler.step_was_taken.connect(camera_handler._on_step_was_taken)
	movement_handler.state_changed.connect(footsteps_handler._on_state_changed)

func _physics_process(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	movement_handler.handle_movement(delta, input_dir)
	camera_handler._handle_fov(delta)
	camera_handler._handle_dof_blur(delta)
	camera_handler._handle_head_bob(delta, velocity, is_on_floor(), input_dir.x)
	footsteps_handler.handle_step(delta, velocity, is_on_floor(), false)
	flashlight_handler._update_flashlight(delta)
