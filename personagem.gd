extends CharacterBody3D

@onready var CAMERA : Camera3D = $CameraController/Camera3D
@onready var LANTERNA : SpotLight3D = $"../Node3D/Lanterna"

## player
@export var SPEED = 2.5
@export var JUMP_VELOCITY = 3
var _is_moving : bool = false

## Mouse e câmera
@export var MOUSE_SENSITIVITY : float = 0.5
@export var tilt_up_limit = deg_to_rad(85)
@export var tilt_down_limit = deg_to_rad(-85)
var _mouse_input : bool = false
var _mouse_rotation : Vector3
var _player_rotation : Vector3
var _camera_rotation : Vector3
var _rotation_input : float
var _tilt_input : float

## Headbobbing
const BOB_AMOUNT_Y = 0.06
const BOB_SPEED = 5
var bob_timer = 0.0
var default_position: Vector3
var last_offset_y = 0.0
var bob_phase = 1  # alterna entre -1 e 1
var target_head_tilt = 0.0  # valor alvo da rotação
var head_bob_multiplier = 3
const MAX_HEAD_TILT = deg_to_rad(5)

## Parâmetros do swing
const SWING_AMOUNT = deg_to_rad(0.3)  # ângulo máximo (em radianos)
const SWING_SPEED = 5.0        # velocidade da oscilação
var swing_timer = 0.0
var default_rot = Transform3D()  # salvar rotação original

## Zoom
var ZOOM_FOV := 40.0
var DEFAULT_FOV := 60.0
var ZOOM_SPEED := 5.0
var target_fov := DEFAULT_FOV

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	default_position = CAMERA.position
	default_rot = LANTERNA.transform

func _unhandled_input(event):
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		_rotation_input = -event.relative.x * MOUSE_SENSITIVITY
		_tilt_input = -event.relative.y * MOUSE_SENSITIVITY
	
	if Input.is_action_just_pressed("zoom"):
		target_fov = ZOOM_FOV
	elif Input.is_action_just_released("zoom"):
		target_fov = DEFAULT_FOV

func _update_camera(delta):
	_mouse_rotation.x += _tilt_input * delta
	_mouse_rotation.x = clamp(_mouse_rotation.x, tilt_down_limit, tilt_up_limit)
	_mouse_rotation.y += _rotation_input * delta
	
	_player_rotation = Vector3(0.0,_mouse_rotation.y,0.0)
	_camera_rotation = Vector3(_mouse_rotation.x,0.0,0.0)

	CAMERA.transform.basis = Basis.from_euler(_camera_rotation)
	global_transform.basis = Basis.from_euler(_player_rotation)
	
	CAMERA.rotation.z = 0.0

	_rotation_input = 0.0
	_tilt_input = 0.0

func _update_headbob(delta, is_moving):
	print(head_bob_multiplier)
	target_head_tilt = lerp(target_head_tilt, MAX_HEAD_TILT * bob_phase, head_bob_multiplier * delta)
	head_bob_multiplier = 3
	if is_moving:
		bob_timer += delta * BOB_SPEED
		var offset_y = abs(sin(bob_timer)) * BOB_AMOUNT_Y

		# Detecta a pisada (mínimo da curva)
		if last_offset_y > 0.01 and offset_y <= 0.01:
			bob_phase *= -1
			head_bob_multiplier = 8
			
		last_offset_y = offset_y
		CAMERA.position = default_position + Vector3(0, offset_y, 0)
	else:
		bob_timer = 0.0
		last_offset_y = 0.0
		target_head_tilt = 0.0  # volta ao centro
		CAMERA.position = CAMERA.position.lerp(default_position, 10 * delta)
	
	# Sempre suaviza para o alvo:
	CAMERA.rotation.z = lerp_angle(CAMERA.rotation.z, target_head_tilt, 10 * delta)

func _update_lanterna(delta, _is_moving):
	#if _is_moving:
	#	swing_timer += delta * SWING_SPEED
	#	var swing_angle = sin(swing_timer) * SWING_AMOUNT

	#	# Cria rotação em Z para "balanço lateral"
	#	var swing_rot = Basis.from_euler(Vector3(0, 0, swing_angle))
	#	LANTERNA.transform.basis = swing_rot * LANTERNA.transform.basis
	#else:
	#	# Volta suavemente ao centro
	#	LANTERNA.transform.basis = LANTERNA.transform.basis.slerp(LANTERNA.basis, 5 * delta)
	#	swing_timer = 0.0
	LANTERNA.position = CAMERA.global_position
	var target_dir = -CAMERA.global_transform.basis.z

	# Cria o novo Basis que olha na direção da câmera
	var target_basis = Basis.looking_at(target_dir, Vector3.UP)

	# Converte os dois Basis para Quaternions
	var from_quat = LANTERNA.global_transform.basis.get_rotation_quaternion()
	var to_quat = target_basis.get_rotation_quaternion()

	# Faz a interpolação esférica
	var slerped_quat = from_quat.slerp(to_quat, 5 * delta)

	# Aplica o resultado de volta na Basis da lanterna
	LANTERNA.global_transform.basis = Basis(slerped_quat)

func _physics_process(delta):
	CAMERA.fov = lerp(CAMERA.fov, target_fov, ZOOM_SPEED * delta)
	_update_camera(delta)
	_update_lanterna(delta, _is_moving)
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		_is_moving = true
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		_is_moving = false

	_update_headbob(delta, _is_moving)
	move_and_slide()
