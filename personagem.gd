extends CharacterBody3D

@onready var camera := $CameraPivot/Camera3D
@onready var camera_pivot := $CameraPivot
@onready var LANTERNA : SpotLight3D = $"../Node3D/Lanterna"

enum PlayerState { IDLE, WALKING, WALKING_BACKWARDS, RUNNING }
var current_state = PlayerState.IDLE

## player
@export_group("Velocidade")
@export var VELOCIDADE_ANDANDO := 2.5
@export var VELOCIDADE_CORRENDO := 9
@export var VELOCIDADE_COSTAS := 2
var velocidade_atual = VELOCIDADE_ANDANDO
var movendo := false
var costas := false
var correndo := false
var deu_passo := false

@export_group("Passos")
@export var distancia_passo_andando: float = 1.8 # Distância em metros para um passo andando
@export var distancia_passo_correndo: float = 2.5 # Distância para um passo correndo
@export var distancia_passo_costas: float = 1.4 # Distância em metros para um passo andando de costas
var distancia_percorrida: float = 0.0 # Acumulador da distância percorrida

## Mouse e câmera
@export_group("Mouse")
@export_range(1, 100, 1) var mouse_sensitivity: int = 100
@export var max_pitch : float = 85
@export var min_pitch : float = -85
var mouse_delta := Vector2.ZERO
var smoothed_mouse_delta := Vector2.ZERO
const SMOOTHING = 0.5

## --- Variáveis do Head Bob ---
@export_group("Head Bob")
@export var bob_frequency = 2.0  # Quão rápidos são os "passos"
@export var bob_amplitude_y = 0.08 # Intensidade do sobe/desce
@export var bob_amplitude_z_roll = 0.02 # Intensidade da inclinação lateral
var bob_time := 0.0

@export_group("Idle Sway")
@export var idle_sway_frequency = 0.3
@export var idle_sway_amplitude = 0.01
var default_position := Vector3.ZERO
var default_rotation := Vector3.ZERO

## Parâmetros do swing
const SWING_AMOUNT = deg_to_rad(0.3)  # ângulo máximo (em radianos)
const SWING_SPEED = 5.0        # velocidade da oscilação
var swing_timer = 0.0
var default_rot = Transform3D()  # salvar rotação original

## Zoom
var ZOOM_FOV := 48.0
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
	Input.set_use_accumulated_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	default_position = camera_pivot.position
	default_rotation = camera_pivot.rotation
	default_rot = LANTERNA.transform

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		olhar(event)
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

func add_yaw(amount)->void:
	if is_zero_approx(amount):
		return
	
	self.rotate_object_local(Vector3.DOWN, deg_to_rad(amount))
	self.orthonormalize()

func add_pitch(amount)->void:
	if is_zero_approx(amount):
		return
	
	camera_pivot.rotate_object_local(Vector3.LEFT, deg_to_rad(amount))
	camera_pivot.orthonormalize()

func clamp_pitch()->void:
	if camera_pivot.rotation.x > deg_to_rad(min_pitch) and camera_pivot.rotation.x < deg_to_rad(max_pitch):
		return
	
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
	camera_pivot.orthonormalize()

func olhar(event: InputEventMouseMotion)-> void:
	var viewport_transform: Transform2D = get_tree().root.get_final_transform()
	var motion: Vector2 = event.xformed_by(viewport_transform).relative
	var degrees_per_unit: float = 0.001
	
	motion *= mouse_sensitivity
	motion *= degrees_per_unit
	
	add_yaw(motion.x)
	add_pitch(motion.y)
	clamp_pitch()

## A nova função de passo baseada em distância
func passo(delta):
	if not is_on_floor():
		deu_passo = false
		return

	if is_on_floor() and current_state != PlayerState.IDLE:
		var velocidade_horizontal = velocity * Vector3(1, 0, 1)
		distancia_percorrida += velocidade_horizontal.length() * delta
		
		var distancia_necessaria: float
		if current_state == PlayerState.RUNNING:
			distancia_necessaria = distancia_passo_correndo
		elif current_state == PlayerState.WALKING:
			distancia_necessaria = distancia_passo_andando
		elif current_state == PlayerState.WALKING_BACKWARDS:
			distancia_necessaria = distancia_passo_costas

		if distancia_percorrida > distancia_necessaria:
			deu_passo = true
			_toca_som_passo()
			
			distancia_percorrida -= distancia_necessaria
		else:
			deu_passo = false

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

func _handle_head_bob(delta, direcao):
	if not is_on_floor():
		camera_pivot.position = camera_pivot.position.lerp(default_position, delta * 10.0)
		camera.rotation.z = lerp_angle(camera.rotation.z, default_rotation.z, delta * 10.0)
		return
	
	var lerp_weight = delta * 10.0
	if current_state != PlayerState.IDLE:
		if deu_passo:
			bob_time = 0.0
		
		bob_time += delta * velocity.length() * bob_frequency
		
		# Cálculos de Bob
		var bob_pos_y = default_position.y + sin(bob_time) * bob_amplitude_y
		var bob_rot_z = default_rotation.z + cos(bob_time * 0.5) * bob_amplitude_z_roll
		
		# Aplicação com lerp
		var target_head_pos = Vector3(default_position.x, bob_pos_y, default_position.z)
		camera_pivot.position = camera_pivot.position.lerp(target_head_pos, lerp_weight)
		camera.rotation.z = lerp_angle(camera.rotation.z, bob_rot_z, lerp_weight)
	else:
		bob_time += delta * idle_sway_frequency
		
		var sway_pos_y = default_position.y + sin(bob_time) * idle_sway_amplitude
		var sway_rot_z = default_rotation.z + cos(bob_time) * idle_sway_amplitude * 0.5
		
		# Aplicação com lerp
		var target_head_pos = Vector3(default_position.x, sway_pos_y, default_position.z)
		var target_cam_rot = Vector3(camera.rotation.x, camera.rotation.y, sway_rot_z)
		
		camera_pivot.position = camera_pivot.position.lerp(target_head_pos, lerp_weight)
		camera.rotation = camera.rotation.lerp(target_cam_rot, lerp_weight)

	direcao = -direcao * 0.03
	camera_pivot.rotation.z = lerp_angle(camera_pivot.rotation.z, direcao, delta * 10)
		
func _update_lanterna(delta, is_moving):
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
	# Atualiza efeitos de câmera
	camera.fov = lerp(camera.fov, target_fov, ZOOM_SPEED * delta)
	camera.attributes.dof_blur_far_distance = lerp(camera.attributes.dof_blur_far_distance, target_dof, DOF_SPEED * delta)

	_update_lanterna(delta, movendo)
	
	# Aplica gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Pega o input de movimento
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Lógica de Movimento e Estado
	if direction:
		if correndo:
			velocidade_atual = VELOCIDADE_CORRENDO
			current_state = PlayerState.RUNNING
		else:
			if input_dir.y == 1: # Andando para trás
				velocidade_atual = VELOCIDADE_COSTAS
				current_state = PlayerState.WALKING_BACKWARDS
			else: # Andando para frente/lados
				velocidade_atual = VELOCIDADE_ANDANDO
				current_state = PlayerState.WALKING
		
		velocity.x = direction.x * velocidade_atual
		velocity.z = direction.z * velocidade_atual
	else:
		velocity.x = move_toward(velocity.x, 0, velocidade_atual)
		velocity.z = move_toward(velocity.z, 0, velocidade_atual)
		current_state = PlayerState.IDLE

	move_and_slide()
	
	# Funções de Passo, Degrau e Head Bob
	passo(delta)
	checa_degrau()
	_handle_head_bob(delta,input_dir.x) # Renomeei sua função para seguir a convenção
