extends CharacterBody3D

enum PlayerState { IDLE, WALKING, WALKING_BACKWARDS, RUNNING, STEPPING_UP, STEPPING_DOWN}
var current_state = PlayerState.IDLE

@export var movement_handler: MovementHandler
@export var mouse_handler: MouseHandler
@export var camera_handler: CameraHandler
@export var footsteps_handler: FootstepsHandler
@export var flashlight_handler: FlashlightHandler

var last_input_dir_x = 0

func _ready() -> void:
	footsteps_handler.step_was_taken.connect(camera_handler._on_step_was_taken)
	movement_handler.state_changed.connect(footsteps_handler._on_state_changed)

func _process(delta: float) -> void:
	camera_handler.process_camera_effects(delta, velocity, is_on_floor(), last_input_dir_x)
	flashlight_handler._update_flashlight(delta)

func _physics_process(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	last_input_dir_x = input_dir.x
	movement_handler.handle_movement(delta, input_dir)
	footsteps_handler.handle_step(delta, velocity, is_on_floor(), false)
