extends CharacterBody3D

@onready var camera := $CameraPivot/Camera3D
@onready var camera_pivot := $CameraPivot
@onready var LANTERNA : SpotLight3D = $"../Node3D/Lanterna"


## player
@export var VELOCIDADE_ANDANDO := 2.5
@export var VELOCIDADE_CORRENDO := 3.5
@export var VELOCIDADE_COSTAS := 1.5
var velocidade_atual = VELOCIDADE_ANDANDO
var movendo := false
var costas := false
var correndo := false

## Contador de passos
var passo_andando := 0.6
var passo_correndo := 0.4
var passo_costas := 0.9
var passo_timer := passo_andando

## Mouse e câmera
@export var MOUSE_SENSITIVITY : float = 0.5
@export var tilt_up_limit = deg_to_rad(85)
@export var tilt_down_limit = deg_to_rad(-85)
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

## Depth of Field
var DEFAULT_DOF := 25.0
var ZOOM_DOF := 35.0
var DOF_SPEED := 3
var target_dof := DEFAULT_DOF

## Sons passos
var non_repeat_passos = []
var passo_dir_esq := 0
@onready var PASSOS : AudioStreamPlayer3D = $Passos
@onready var sons_de_passo : Dictionary = {
	"Grama": [
		load("res://Sound effects/PassosGrama/Footsteps_Walk_Grass_Mono_01.wav"),
		load("res://Sound effects/PassosGrama/Footsteps_Walk_Grass_Mono_02.wav"),
		load("res://Sound effects/PassosGrama/Footsteps_Walk_Grass_Mono_03.wav"),
		load("res://Sound effects/PassosGrama/Footsteps_Walk_Grass_Mono_04.wav"),
		load("res://Sound effects/PassosGrama/Footsteps_Walk_Grass_Mono_05.wav"),
		load("res://Sound effects/PassosGrama/Footsteps_Walk_Grass_Mono_06.wav"),
		load("res://Sound effects/PassosGrama/Footsteps_Walk_Grass_Mono_07.wav"),
		load("res://Sound effects/PassosGrama/Footsteps_Walk_Grass_Mono_08.wav"),
		load("res://Sound effects/PassosGrama/Footsteps_Walk_Grass_Mono_09.wav"),
		load("res://Sound effects/PassosGrama/Footsteps_Walk_Grass_Mono_10.wav"),
	],
	"Madeira": [
		load("res://Sound effects/PassosMadeira/Footsteps_Wood_Walk_01.wav"),
		load("res://Sound effects/PassosMadeira/Footsteps_Wood_Walk_02.wav"),
		load("res://Sound effects/PassosMadeira/Footsteps_Wood_Walk_03.wav"),
		load("res://Sound effects/PassosMadeira/Footsteps_Wood_Walk_04.wav"),
		load("res://Sound effects/PassosMadeira/Footsteps_Wood_Walk_05.wav"),
		load("res://Sound effects/PassosMadeira/Footsteps_Wood_Walk_06.wav"),
		load("res://Sound effects/PassosMadeira/Footsteps_Wood_Walk_07.wav"),
		load("res://Sound effects/PassosMadeira/Footsteps_Wood_Walk_08.wav"),
		load("res://Sound effects/PassosMadeira/Footsteps_Wood_Walk_09.wav"),
		load("res://Sound effects/PassosMadeira/Footsteps_Wood_Walk_10.wav"),
	],
	"Azuleijo": [
		load("res://Sound effects/PassosAzuleijo/Footsteps_Tile_Walk_01.wav"),
		load("res://Sound effects/PassosAzuleijo/Footsteps_Tile_Walk_02.wav"),
		load("res://Sound effects/PassosAzuleijo/Footsteps_Tile_Walk_03.wav"),
		load("res://Sound effects/PassosAzuleijo/Footsteps_Tile_Walk_04.wav"),
		load("res://Sound effects/PassosAzuleijo/Footsteps_Tile_Walk_05.wav"),
		load("res://Sound effects/PassosAzuleijo/Footsteps_Tile_Walk_06.wav"),
		load("res://Sound effects/PassosAzuleijo/Footsteps_Tile_Walk_07.wav"),
		load("res://Sound effects/PassosAzuleijo/Footsteps_Tile_Walk_08.wav"),
	],
	"Pedra": [
		load("res://Sound effects/PassosPedra/Footsteps_Rock_Walk_01.wav"),
		load("res://Sound effects/PassosPedra/Footsteps_Rock_Walk_02.wav"),
		load("res://Sound effects/PassosPedra/Footsteps_Rock_Walk_03.wav"),
		load("res://Sound effects/PassosPedra/Footsteps_Rock_Walk_04.wav"),
		load("res://Sound effects/PassosPedra/Footsteps_Rock_Walk_05.wav"),
		load("res://Sound effects/PassosPedra/Footsteps_Rock_Walk_06.wav"),
		load("res://Sound effects/PassosPedra/Footsteps_Rock_Walk_07.wav"),
		load("res://Sound effects/PassosPedra/Footsteps_Rock_Walk_08.wav"),
		load("res://Sound effects/PassosPedra/Footsteps_Rock_Walk_09.wav"),
	]
}

## RayCast de escada
var alvo_subida := -1.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	default_position = camera.position
	default_rot = LANTERNA.transform

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_rotation_input = -event.relative.x * MOUSE_SENSITIVITY
		_tilt_input = -event.relative.y * MOUSE_SENSITIVITY
		return

	if event is InputEventMouseButton:
		if Input.is_action_just_pressed("zoom"):
			target_fov = ZOOM_FOV
			target_dof = ZOOM_DOF

		elif Input.is_action_just_released("zoom"):
			target_fov = DEFAULT_FOV
			target_dof = DEFAULT_DOF

	if event is InputEventKey:
		if Input.is_action_just_pressed("lanterna"):
			LANTERNA.visible = !LANTERNA.visible

		elif Input.is_action_just_pressed("Correr"):
			correndo = true

		elif Input.is_action_just_released("Correr"):
			correndo = false
		return

func _update_camera(delta):
	_mouse_rotation.x += _tilt_input * delta
	_mouse_rotation.x = clamp(_mouse_rotation.x, tilt_down_limit, tilt_up_limit)
	_mouse_rotation.y += _rotation_input * delta

	_player_rotation = Vector3(0.0,_mouse_rotation.y,0.0)
	_camera_rotation = Vector3(_mouse_rotation.x,0.0,0.0)

	camera.transform.basis = Basis.from_euler(_camera_rotation)
	global_transform.basis = Basis.from_euler(_player_rotation)

	camera.rotation.z = 0.0

	_rotation_input = 0.0
	_tilt_input = 0.0

func passo(delta):
	if is_on_floor() and velocity.length() >= 0.1:
		passo_timer -= delta
		if passo_timer <= 0.0:
			_toca_som_passo()
			print("Passo!")
			if correndo:
				passo_timer = passo_correndo
			else:
				if costas:
					passo_timer = passo_costas
				else:
					passo_timer = passo_andando

func _toca_som_passo():
	var som_escolhido : AudioStreamWAV
	if %ChecaGrupoChao.is_colliding():
		var chao = %ChecaGrupoChao.get_collider()
		var lista_passos := []

		if chao.is_in_group("Grama"):
			lista_passos = sons_de_passo["Grama"]
		elif chao.is_in_group("Madeira"):
			lista_passos = sons_de_passo["Madeira"]
		elif chao.is_in_group("Azuleijo"):
			lista_passos = sons_de_passo["Azuleijo"]
		elif chao.is_in_group("Pedra"):
			lista_passos = sons_de_passo["Pedra"]
		else:
			return

		if lista_passos.size() > 0:
			if non_repeat_passos.size() >= lista_passos.size():
				non_repeat_passos.clear()

			som_escolhido = lista_passos[randi() % lista_passos.size()]
			while som_escolhido in non_repeat_passos:
				som_escolhido = lista_passos[randi() % lista_passos.size()]

			non_repeat_passos.append(som_escolhido)
	
	if passo_dir_esq == 0:
		PASSOS.position.x = -0.3
		passo_dir_esq = 1
	else:
		PASSOS.position.x = 0.3
		passo_dir_esq = 0
	
	PASSOS.stream = som_escolhido
	PASSOS.play()

func headbob(delta,direcao, movendo):
	if movendo and is_on_floor():
		direcao = -direcao * 0.03
		camera_pivot.rotation.z = lerp_angle(camera_pivot.rotation.z, direcao, delta * 5)
	if movendo == false or is_on_floor() == false:
		camera_pivot.rotation.z = lerp_angle(camera_pivot.rotation.z, 0.0, delta * 10)


"
func _update_headbob(delta, is_moving):
	target_head_tilt = lerp(target_head_tilt, MAX_HEAD_TILT * bob_phase, head_bob_multiplier * delta)
	head_bob_multiplier = 3
	if is_moving and is_on_floor():
		bob_timer += delta * BOB_SPEED
		var offset_y = abs(sin(bob_timer)) * BOB_AMOUNT_Y
		# Detecta a pisada (mínimo da curva)
		if last_offset_y > 0.01 and offset_y <= 0.01:
			bob_phase *= -1
			head_bob_multiplier = 8
			_toca_som_passo()
			
		last_offset_y = offset_y
		camera.position = default_position + Vector3(0, offset_y, 0)
	else:
		bob_timer = 0.0
		last_offset_y = 0.0
		target_head_tilt = 0.0  # volta ao centro
		camera.position = camera.position.lerp(default_position, 10 * delta)
	# Sempre suaviza para o alvo:
	camera.rotation.z = lerp_angle(camera.rotation.z, target_head_tilt, 10 * delta)
"

func _update_lanterna(delta, is_moving):
	if movendo:
		swing_timer += delta * SWING_SPEED
		var swing_angle = sin(swing_timer) * SWING_AMOUNT

		# Cria rotação em Z para "balanço lateral"
		var swing_rot = Basis.from_euler(Vector3(0, 0, swing_angle))
		LANTERNA.transform.basis = swing_rot * LANTERNA.transform.basis
	else:
		# Volta suavemente ao centro
		LANTERNA.transform.basis = LANTERNA.transform.basis.slerp(LANTERNA.basis, 5 * delta)
		swing_timer = 0.0
	LANTERNA.position = camera.global_position
	var target_dir = -camera.global_transform.basis.z

	# Cria o novo Basis que olha na direção da câmera
	var target_basis = Basis.looking_at(target_dir, Vector3.UP)

	# Converte os dois Basis para Quaternions
	var from_quat = LANTERNA.global_transform.basis.get_rotation_quaternion()
	var to_quat = target_basis.get_rotation_quaternion()

	# Faz a interpolação esférica
	var slerped_quat = from_quat.slerp(to_quat, 5 * delta)

	# Aplica o resultado de volta na Basis da lanterna
	LANTERNA.global_transform.basis = Basis(slerped_quat)

func checa_degrau():
	if is_on_wall():
		var low_hit = %RayCastFrontLow.is_colliding()
		var high_clear = not %RayCastFrontHigh.is_colliding()

		if low_hit and high_clear and %RayCastTopDown.is_colliding():
			var hit_y = %RayCastTopDown.get_collision_point().y
			alvo_subida = hit_y + 0.7  # ou ajuste fino com +0.1 ou +0.3
			global_position.y = alvo_subida

func _physics_process(delta):

	camera.fov = lerp(camera.fov, target_fov, ZOOM_SPEED * delta)
	camera.attributes.dof_blur_far_distance = lerp(camera.attributes.dof_blur_far_distance, target_dof, DOF_SPEED * delta)

	_update_camera(delta)
	_update_lanterna(delta, movendo)
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		if correndo == true:
			velocidade_atual = VELOCIDADE_CORRENDO
		else:
			if input_dir.y == 1:
				velocidade_atual = VELOCIDADE_COSTAS
				costas = true
			else:
				velocidade_atual = VELOCIDADE_ANDANDO
				costas = false
		velocity.x = direction.x * velocidade_atual
		velocity.z = direction.z * velocidade_atual
		movendo = true
	else:
		velocity.x = move_toward(velocity.x, 0, velocidade_atual)
		velocity.z = move_toward(velocity.z, 0, velocidade_atual)
		movendo = false

	passo(delta)
	checa_degrau()
	headbob(delta, input_dir.x, movendo)
	move_and_slide()
