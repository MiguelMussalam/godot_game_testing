class_name CameraHandler
extends Node

## - nodes
@export_group("Nodes")

@export var character : CharacterBody3D
@export var camera : Camera3D
@export var camera_pivot : Node3D
@export var RCDOF_blur : RayCast3D

@export_group("FOV")
@export var ZOOM_FOV := 48.0
@export var DEFAULT_FOV := 60.0
@export var ZOOM_SPEED := 5.0
var target_fov := DEFAULT_FOV
var zooming = false

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

@export_group("Step Impulse")
@export var impulse_amplitude_y: float = 0.12   # Força do "tranco" vertical do passo
@export var impulse_amplitude_z_roll: float = 0.06 # Força do "tranco" lateral do passo
@export var impulse_decay_speed: float = 15     # Quão rápido o impulso desaparece

# Variáveis internas para controlar o impulso atual
var impulse_vector: Vector3 = Vector3.ZERO

@export_group("Depth of Field")
@export var blur_far_max := 20.0
@export var blur_far_min := 1.0
@export var blur_near_max := 2.0
@export var blur_near_min := 0.0
@export var RCBlur_range :=  -2.0
@export var RCBlur_range_zoomed :=  -6.0
@export var blur_lerp_speed := 10.0

func _ready() -> void:
	default_position = camera_pivot.position
	default_rotation = camera_pivot.rotation
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.2

func _unhandled_input(event) -> void:

	if event is InputEventMouseButton:
		if Input.is_action_just_pressed("zoom"):
			zooming = true
			target_fov = ZOOM_FOV

		elif Input.is_action_just_released("zoom"):
			zooming = false
			target_fov = DEFAULT_FOV

func _handle_fov(delta : float) -> void:
	camera.fov = lerp(camera.fov, target_fov, ZOOM_SPEED * delta)

func _handle_dof_blur(delta: float) -> void:
	if zooming:
		RCBlur_range = RCBlur_range_zoomed
	else:
		RCBlur_range = -2.0
	RCDOF_blur.target_position.z = RCBlur_range
	if RCDOF_blur.is_colliding():
		var origin = RCDOF_blur.global_transform.origin
		var collision_point = RCDOF_blur.get_collision_point()
		var distance = origin.distance_to(collision_point)
		camera.attributes.dof_blur_far_distance = lerpf(camera.attributes.dof_blur_far_distance, blur_far_min * distance, delta * blur_lerp_speed)
		camera.attributes.dof_blur_near_distance = lerpf(camera.attributes.dof_blur_near_distance, blur_near_min, delta * blur_lerp_speed)
	else:
		camera.attributes.dof_blur_far_distance = lerpf(camera.attributes.dof_blur_far_distance, blur_far_max, delta * 2)
		camera.attributes.dof_blur_near_distance = lerpf(camera.attributes.dof_blur_near_distance, blur_near_max, delta * 2)

func _on_step_was_taken(step_direction: int):
	current_impulse.x = impulse_amplitude_z_roll * step_direction
	# O impulso vertical é sempre para baixo
	current_impulse.y = -impulse_amplitude_y 

func _handle_head_bob(delta: float, velocity: Vector3, is_on_floor: bool,  movement_direction: float):
	if not is_on_floor and character.current_state != character.PlayerState.STEPPING_UP and character.current_state != character.PlayerState.STEPPING_DOWN:
		camera_pivot.position = camera_pivot.position.lerp(default_position, delta * 10.0)
		camera.rotation.z = lerp_angle(camera.rotation.z, default_rotation.z, delta * 10.0)
		return
	bob_time += delta * velocity.length() * bob_frequency
	var lerp_weight = delta * 10.0
	if character.current_state != character.PlayerState.IDLE:
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

	movement_direction = -movement_direction * 0.03
	camera_pivot.rotation.z = lerp_angle(camera_pivot.rotation.z, movement_direction, delta * 10)

func process_camera_effects(delta: float, velocity: Vector3, is_on_floor: bool, movement_direction: float):
	_handle_fov(delta)
	_handle_dof_blur(delta)
	_handle_head_bob(delta, velocity, is_on_floor, movement_direction)
