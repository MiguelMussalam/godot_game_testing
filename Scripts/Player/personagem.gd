extends CharacterBody3D
@onready var camera := $CameraPivot/Camera3D
@onready var camera_pivot := $CameraPivot
@onready var lanterna := $"../Node3D/Lanterna"
@onready var som_lanterna := $"../Node3D/Lanterna/SomLanterna"

@onready var RCFrontHigh:= 	$Degrau/RayCastFrontHigh
@onready var RCFrontLow := 	$Degrau/RayCastFrontLow
@onready var RCFrontDown:=	$Degrau/RayCastFrontDown
@onready var RCTopDown  := 	$Degrau/RayCastTopDown
@onready var RCGrupoChao:=	$ChecaGrupoChao

enum PlayerState { IDLE, WALKING, WALKING_BACKWARDS, RUNNING, STEPPING_UP, STEPPING_DOWN}
var current_state = PlayerState.IDLE

@export_group("FOV")
@export var ZOOM_FOV := 48.0
@export var DEFAULT_FOV := 60.0
@export var ZOOM_SPEED := 5.0
var target_fov := DEFAULT_FOV

@export_group("Mouse")
@export_range(1, 100, 1) var mouse_sensitivity: int = 100
@export var max_pitch : float = 85
@export var min_pitch : float = -85
var mouse_delta := Vector2.ZERO
var smoothed_mouse_delta := Vector2.ZERO
const SMOOTHING = 0.5

@export_group("Velocidade")
@export var VELOCIDADE_ANDANDO := 2.5
@export var VELOCIDADE_CORRENDO := 9
@export var VELOCIDADE_COSTAS := 2.0
@export var VELOCIDADE_SUBINDO_ESCADA := 2.0
@export var VELOCIDADE_DESCENDO_ESCADA := 1.0
var velocidade_atual = VELOCIDADE_ANDANDO
var movendo := false
var costas := false
var correndo := false
var deu_passo := false
var estava_no_ar := false

@export_group("Passos")
@export var distancia_passo_andando: float = 1.8
@export var distancia_passo_correndo: float = 2.5
@export var distancia_passo_costas: float = 1.4
@export var distancia_escada_subindo: float = 1.0
@export var distancia_escada_descendo: float = 0.7

var distancia_percorrida: float = 0.0 # Acumulador da distância percorrida

## --- Variáveis do Head Bob ---
@export_group("Head Bob")
@export var bob_frequency = 2.0  # Quão rápidos são os "passos"
@export var bob_amplitude_y = 0.08 # Intensidade do sobe/desce
@export var bob_amplitude_z_roll = 0.02 # Intensidade da inclinação lateral
@export var noise_intensity_y: float = 0.3   # Quão forte o ruído afeta o movimento vertical
@export var noise_intensity_z_roll: float = 0.5 # Quão forte o ruído afeta a inclinação
@export var noise_speed_multiplier: float = 0.5 # Deixa o ruído mais lento que o bob para não parecer "tremido"
var bob_time := 0.0
var noise = FastNoiseLite.new()
var current_impulse: Vector2 = Vector2.ZERO # x para o roll, y para o vertical


@export_group("Idle Sway")
@export var idle_sway_frequency = 0.3
@export var idle_sway_amplitude = 0.01
var default_position := Vector3.ZERO
var default_rotation := Vector3.ZERO

# Adicione isso junto com suas outras variáveis de Head Bob
## NÃO IMPLEMENTADO!!
@export_group("Step Impulse")
@export var impulse_amplitude_y: float = 0.12   # Força do "tranco" vertical do passo
@export var impulse_amplitude_z_roll: float = 0.06 # Força do "tranco" lateral do passo
@export var impulse_decay_speed: float = 15     # Quão rápido o impulso desaparece

# Variáveis internas para controlar o impulso atual
var impulse_vector: Vector3 = Vector3.ZERO

## Parâmetros do swing
const SWING_AMOUNT = deg_to_rad(0.3)  # ângulo máximo (em radianos)
const SWING_SPEED = 5.0        # velocidade da oscilação
var swing_timer = 0.0
var default_rot = Transform3D()  # salvar rotação original

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
	"Grass": [
		load("res://Audio/SoundEffects/Footsteps/Grass/Footsteps_Walk_Grass_Mono_01.wav"),
		load("res://Audio/SoundEffects/Footsteps/Grass/Footsteps_Walk_Grass_Mono_02.wav"),
		load("res://Audio/SoundEffects/Footsteps/Grass/Footsteps_Walk_Grass_Mono_03.wav"),
		load("res://Audio/SoundEffects/Footsteps/Grass/Footsteps_Walk_Grass_Mono_04.wav"),
		load("res://Audio/SoundEffects/Footsteps/Grass/Footsteps_Walk_Grass_Mono_05.wav"),
		load("res://Audio/SoundEffects/Footsteps/Grass/Footsteps_Walk_Grass_Mono_06.wav"),
		load("res://Audio/SoundEffects/Footsteps/Grass/Footsteps_Walk_Grass_Mono_07.wav"),
		load("res://Audio/SoundEffects/Footsteps/Grass/Footsteps_Walk_Grass_Mono_08.wav"),
		load("res://Audio/SoundEffects/Footsteps/Grass/Footsteps_Walk_Grass_Mono_09.wav"),
		load("res://Audio/SoundEffects/Footsteps/Grass/Footsteps_Walk_Grass_Mono_10.wav")
	],
	"Wood": [
		load("res://Audio/SoundEffects/Footsteps/Wood/Footsteps_Wood_Walk_01.wav"),
		load("res://Audio/SoundEffects/Footsteps/Wood/Footsteps_Wood_Walk_02.wav"),
		load("res://Audio/SoundEffects/Footsteps/Wood/Footsteps_Wood_Walk_03.wav"),
		load("res://Audio/SoundEffects/Footsteps/Wood/Footsteps_Wood_Walk_04.wav"),
		load("res://Audio/SoundEffects/Footsteps/Wood/Footsteps_Wood_Walk_05.wav"),
		load("res://Audio/SoundEffects/Footsteps/Wood/Footsteps_Wood_Walk_06.wav"),
		load("res://Audio/SoundEffects/Footsteps/Wood/Footsteps_Wood_Walk_07.wav"),
		load("res://Audio/SoundEffects/Footsteps/Wood/Footsteps_Wood_Walk_08.wav"),
		load("res://Audio/SoundEffects/Footsteps/Wood/Footsteps_Wood_Walk_09.wav"),
		load("res://Audio/SoundEffects/Footsteps/Wood/Footsteps_Wood_Walk_10.wav")
	],
	"Tile": [
		load("res://Audio/SoundEffects/Footsteps/Tile/Footsteps_Tile_Walk_01.wav"),
		load("res://Audio/SoundEffects/Footsteps/Tile/Footsteps_Tile_Walk_02.wav"),
		load("res://Audio/SoundEffects/Footsteps/Tile/Footsteps_Tile_Walk_03.wav"),
		load("res://Audio/SoundEffects/Footsteps/Tile/Footsteps_Tile_Walk_04.wav"),
		load("res://Audio/SoundEffects/Footsteps/Tile/Footsteps_Tile_Walk_05.wav"),
		load("res://Audio/SoundEffects/Footsteps/Tile/Footsteps_Tile_Walk_06.wav"),
		load("res://Audio/SoundEffects/Footsteps/Tile/Footsteps_Tile_Walk_07.wav"),
		load("res://Audio/SoundEffects/Footsteps/Tile/Footsteps_Tile_Walk_08.wav")
	],
	"Rock": [
		load("res://Audio/SoundEffects/Footsteps/Rock/Footsteps_Rock_Walk_01.wav"),
		load("res://Audio/SoundEffects/Footsteps/Rock/Footsteps_Rock_Walk_02.wav"),
		load("res://Audio/SoundEffects/Footsteps/Rock/Footsteps_Rock_Walk_03.wav"),
		load("res://Audio/SoundEffects/Footsteps/Rock/Footsteps_Rock_Walk_04.wav"),
		load("res://Audio/SoundEffects/Footsteps/Rock/Footsteps_Rock_Walk_05.wav"),
		load("res://Audio/SoundEffects/Footsteps/Rock/Footsteps_Rock_Walk_06.wav"),
		load("res://Audio/SoundEffects/Footsteps/Rock/Footsteps_Rock_Walk_07.wav"),
		load("res://Audio/SoundEffects/Footsteps/Rock/Footsteps_Rock_Walk_08.wav"),
		load("res://Audio/SoundEffects/Footsteps/Rock/Footsteps_Rock_Walk_09.wav")
	]
}

## Sons Lanterna
@onready var sons_lanterna = [
		load("res://Audio/SoundEffects/Flashlight/som_lanterna-01.wav"),
		load("res://Audio/SoundEffects/Flashlight/som_lanterna-02.wav"),
		load("res://Audio/SoundEffects/Flashlight/som_lanterna-04.wav"),
		load("res://Audio/SoundEffects/Flashlight/som_lanterna-09.wav"),
		load("res://Audio/SoundEffects/Flashlight/som_lanterna-10.wav")
]


## RayCast de escada
var alvo_subida := -1.0

func _ready():
	Input.set_use_accumulated_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	default_position = camera_pivot.position
	default_rotation = camera_pivot.rotation
	default_rot = lanterna.transform
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.2
	som_lanterna.position = lanterna.position


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
			ativa_lanterna()

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
func passo(delta, forca_passo):
	var distancia_necessaria: float
	
	if forca_passo:
		distancia_necessaria = 0.0
		if distancia_percorrida > distancia_necessaria:
			deu_passo = true
			som_passo()
			# O sinal do roll alterna a cada passo (esquerda/direita)
			current_impulse.x = impulse_amplitude_z_roll * pow(-1, passo_dir_esq)
			# O impulso vertical é sempre para baixo
			current_impulse.y = -impulse_amplitude_y 
			distancia_percorrida -= distancia_necessaria
		else:
			deu_passo = false
		return
	if not is_on_floor():
		deu_passo = false
		return

	if is_on_floor() and current_state != PlayerState.IDLE and forca_passo == false:
		var velocidade_horizontal = velocity * Vector3(1, 0, 1)
		distancia_percorrida += velocidade_horizontal.length() * delta
	
		if current_state == PlayerState.RUNNING:
			distancia_necessaria = distancia_passo_correndo
		elif current_state == PlayerState.WALKING:
			distancia_necessaria = distancia_passo_andando
		elif current_state == PlayerState.WALKING_BACKWARDS:
			distancia_necessaria = distancia_passo_costas
		elif current_state == PlayerState.STEPPING_UP:
			distancia_necessaria = distancia_escada_subindo
		elif current_state == PlayerState.STEPPING_DOWN:
			distancia_necessaria = distancia_escada_descendo

		if distancia_percorrida > distancia_necessaria:
			deu_passo = true
			som_passo()
			# O sinal do roll alterna a cada passo (esquerda/direita)
			current_impulse.x = impulse_amplitude_z_roll * pow(-1, passo_dir_esq)
			# O impulso vertical é sempre para baixo
			current_impulse.y = -impulse_amplitude_y 
			distancia_percorrida -= distancia_necessaria
		else:
			deu_passo = false

func som_passo():
	var som_escolhido : AudioStreamWAV
	if RCGrupoChao.is_colliding():
		var chao = RCGrupoChao.get_collider()
		var lista_passos := []
		if chao.is_in_group("Grass"):
			lista_passos = sons_de_passo["Grass"]
		elif chao.is_in_group("Wood"):
			lista_passos = sons_de_passo["Wood"]
		elif chao.is_in_group("Tile"):
			lista_passos = sons_de_passo["Tile"]
		elif chao.is_in_group("Rock"):
			lista_passos = sons_de_passo["Rock"]
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

func ativa_lanterna():
	if !som_lanterna.is_playing():
		var som_escolhido = AudioStreamWAV
		som_escolhido = sons_lanterna.pick_random()
		som_lanterna.stream = som_escolhido
		som_lanterna.play()
		# Conecta o signal `finished` só uma vez
		if not som_lanterna.is_connected("finished", Callable(self, "_on_som_lanterna_finished")):
			som_lanterna.finished.connect(_on_som_lanterna_finished)

func _on_som_lanterna_finished():
	lanterna.visible = !lanterna.visible
	som_lanterna.finished.disconnect(_on_som_lanterna_finished) # desconecta para evitar múltiplas execuções

func _handle_head_bob(delta, direcao):
	if not is_on_floor() and current_state != PlayerState.STEPPING_UP and current_state != PlayerState.STEPPING_DOWN:
		camera_pivot.position = camera_pivot.position.lerp(default_position, delta * 10.0)
		camera.rotation.z = lerp_angle(camera.rotation.z, default_rotation.z, delta * 10.0)
		return
	bob_time += delta * velocity.length() * bob_frequency
	var lerp_weight = delta * 10.0
	if current_state != PlayerState.IDLE:
		var base_bob_y = sin(bob_time * bob_frequency) * bob_amplitude_y
		var base_bob_z_roll = cos(bob_time * bob_frequency) * bob_amplitude_z_roll

		var noise_sample_y = noise.get_noise_1d(bob_time * noise_speed_multiplier)
		var noise_sample_z_roll = noise.get_noise_2d(bob_time * noise_speed_multiplier, 1.0) # 2D noise com um eixo constante

		var final_pos_y = default_position.y + base_bob_y + (noise_sample_y * noise_intensity_y * bob_amplitude_y)
		var final_rot_z = default_rotation.z + base_bob_z_roll + (noise_sample_z_roll * noise_intensity_z_roll * bob_amplitude_z_roll)

		current_impulse = current_impulse.lerp(Vector2.ZERO, delta * impulse_decay_speed)

		var target_head_pos = Vector3(default_position.x, final_pos_y + current_impulse.y, default_position.z)
		var target_cam_rot_z = final_rot_z + current_impulse.x

		camera_pivot.position = camera_pivot.position.lerp(target_head_pos, lerp_weight)
		camera.rotation.z = lerp_angle(camera.rotation.z, target_cam_rot_z, lerp_weight)
	else:
		bob_time += delta * idle_sway_frequency
		
		var sway_pos_y = default_position.y + sin(bob_time) * idle_sway_amplitude
		var sway_rot_z = default_rotation.z + cos(bob_time) * idle_sway_amplitude * 0.5

		var target_head_pos = Vector3(default_position.x, sway_pos_y, default_position.z)
		var target_cam_rot = Vector3(camera.rotation.x, camera.rotation.y, sway_rot_z)

		camera_pivot.position = camera_pivot.position.lerp(target_head_pos, lerp_weight)
		camera.rotation = camera.rotation.lerp(target_cam_rot, lerp_weight)

	direcao = -direcao * 0.03
	camera_pivot.rotation.z = lerp_angle(camera_pivot.rotation.z, direcao, delta * 10)
		
func _update_lanterna(delta, is_moving):
	lanterna.position = camera.global_position
	var target_dir = -camera.global_transform.basis.z

	# Cria o novo Basis que olha na direção da câmera
	var target_basis = Basis.looking_at(target_dir, Vector3.UP)

	# Converte os dois Basis para Quaternions
	var from_quat = lanterna.global_transform.basis.get_rotation_quaternion()
	var to_quat = target_basis.get_rotation_quaternion()

	# Faz a interpolação esférica
	var slerped_quat = from_quat.slerp(to_quat, 5 * delta)

	# Aplica o resultado de volta na Basis da lanterna
	lanterna.global_transform.basis = Basis(slerped_quat)

func checa_degrau(delta):
	var baixo_colide = RCFrontLow.is_colliding()
	var alto_colide = RCFrontHigh.is_colliding()
	var altura_degrau : float
	
	## subindo degrau
	if baixo_colide and not alto_colide:
		current_state = PlayerState.STEPPING_UP
		RCFrontHigh.force_raycast_update()
		altura_degrau = RCTopDown.get_collision_point().y
		altura_degrau = altura_degrau - $"Pé".global_position.y
		altura_degrau = altura_degrau + global_position.y + 0.5
		global_position.y = lerp(global_position.y, altura_degrau, 2.5 * delta)
	
	var degrau_abaixo = RCFrontDown.is_colliding()
	var distancia_bate = !RCTopDown.is_colliding()
	
	## Descendo degrau
	if degrau_abaixo and distancia_bate and current_state != PlayerState.STEPPING_UP:
		if not is_on_floor():
			current_state = PlayerState.STEPPING_DOWN
			velocity.y = -2.5

func _update_step_raycasts(direction):
	$Degrau.look_at($Degrau.global_position + direction)
	
func _update_state(input_dir):
	if correndo:
		current_state = PlayerState.RUNNING
	else:
		if input_dir.y == 1: # Andando para trás
			current_state = PlayerState.WALKING_BACKWARDS
		else: # Andando para frente/lados
			current_state = PlayerState.WALKING
	
func _update_velocidade():
	if current_state == PlayerState.RUNNING:
		velocidade_atual = VELOCIDADE_CORRENDO
	elif current_state == PlayerState.WALKING:
		velocidade_atual = VELOCIDADE_ANDANDO
	elif current_state == PlayerState.WALKING_BACKWARDS:
		velocidade_atual = VELOCIDADE_COSTAS
	elif current_state == PlayerState.STEPPING_UP:
		velocidade_atual = VELOCIDADE_SUBINDO_ESCADA
	elif current_state == PlayerState.STEPPING_DOWN:
		velocidade_atual = VELOCIDADE_DESCENDO_ESCADA

func _physics_process(delta):
	print(is_on_floor(), current_state)
	#if estava_no_ar and is_on_floor() and current_state != PlayerState.STEPPING_UP and current_state != PlayerState.STEPPING_DOWN:
	#	passo(delta,1)
	estava_no_ar = !is_on_floor()
	# Atualiza efeitos de câmera
	#camera.fov = lerp(camera.fov, target_fov, ZOOM_SPEED * delta)
	#camera.attributes.dof_blur_far_distance = lerp(camera.attributes.dof_blur_far_distance, target_dof, DOF_SPEED * delta)
	_update_lanterna(delta, movendo)
	
	# Aplica gravidade
	if not is_on_floor() or not is_on_wall():
		velocity += get_gravity() * delta

	# Pega o input de movimento
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Lógica de Movimento e Estado
	if direction:
		_update_step_raycasts(direction)
		_update_state(input_dir)
		checa_degrau(delta)
		_update_velocidade()
		
		velocity.x = direction.x * velocidade_atual
		velocity.z = direction.z * velocidade_atual
	else:
		velocity.x = move_toward(velocity.x, 0, velocidade_atual)
		velocity.z = move_toward(velocity.z, 0, velocidade_atual)
		current_state = PlayerState.IDLE

	move_and_slide()
	# Funções de Passo, Degrau e Head Bob
	passo(delta, false)
	_handle_head_bob(delta,input_dir.x) # Renomeei sua função para seguir a convenção
