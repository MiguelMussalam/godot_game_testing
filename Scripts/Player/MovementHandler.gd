extends Node


@export_group("Nodes")
@export var character : CharacterBody3D
@export var foot : Node3D
@export var stairstepRCGroup : Node3D
@export var RCFrontHigh : RayCast3D
@export var RCFrontLow  : RayCast3D
@export var RCFrontDown : RayCast3D
@export var RCTopDown   : RayCast3D

@export_group("Velocidade")
@export var walk_speed := 2.5
@export var run_speed := 9
@export var backwards_speed := 2.0
@export var stepping_up_speed := 2.0
@export var stepping_down_speed := 1.0
var speed = walk_speed
var movendo := false
var costas := false
var running := false
var deu_passo := false
var estava_no_ar := false

signal state_changed(new_state: int)
signal new_velocity(new_velocity: float)

func _unhandled_input(event) -> void:

	if event is InputEventKey:

		if Input.is_action_just_pressed("run"):
			running = true

		elif Input.is_action_just_released("run"):
			running = false

func _update_state(input_dir) -> void:
	if running:
		character.current_state = character.PlayerState.RUNNING
	else:
		if input_dir.y == 1: # Andando para trás
			character.current_state = character.PlayerState.WALKING_BACKWARDS
		else: # Andando para frente/lados
			character.current_state = character.PlayerState.WALKING
	state_changed.emit(character.current_state)

func _update_speed() -> void:
	if character.current_state == character.PlayerState.RUNNING:
		speed = run_speed
	elif character.current_state == character.PlayerState.WALKING:
		speed = walk_speed
	elif character.current_state == character.PlayerState.WALKING_BACKWARDS:
		speed = backwards_speed
	elif character.current_state == character.PlayerState.STEPPING_UP:
		speed = stepping_up_speed
	elif character.current_state == character.PlayerState.STEPPING_DOWN:
		speed = stepping_down_speed

func apply_gravity(delta) -> void:
	if not character.is_on_floor() or not character.is_on_wall():
		character.velocity += character.get_gravity() * delta

func stairstep_check(delta : float) -> void:
	var low_collide = RCFrontLow.is_colliding()
	var high_collide = RCFrontHigh.is_colliding()
	var step_height : float
	
	## subindo degrau
	if low_collide and not high_collide:
		if character.current_state != character.PlayerState.STEPPING_UP:
			character.current_state = character.PlayerState.STEPPING_UP
			state_changed.emit(character.current_state)
		RCFrontHigh.force_raycast_update()
		step_height = RCTopDown.get_collision_point().y
		step_height = step_height - foot.global_position.y
		step_height = step_height + character.global_position.y + 0.5
		character.global_position.y = lerp(character.global_position.y, step_height, 2.5 * delta)
	
	var collision_below = RCFrontDown.is_colliding()
	var in_range = !RCTopDown.is_colliding()
	
	## Descendo degrau
	if collision_below and in_range and character.current_state != character.PlayerState.STEPPING_UP:
		if not character.is_on_floor():
			if character.current_state != character.PlayerState.STEPPING_DOWN:
				character.current_state = character.PlayerState.STEPPING_DOWN
				state_changed.emit(character.current_state)
			character.velocity.y = -2.5

func _update_step_raycasts(direction) -> void:
	stairstepRCGroup.look_at(stairstepRCGroup.global_position + direction)

func handle_movement(delta : float, input_dir : Vector2) -> void:
	apply_gravity(delta)
	var direction := (character.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Lógica de Movimento e Estado
	if direction:
		_update_step_raycasts(direction)
		_update_state(input_dir)
		stairstep_check(delta)
		_update_speed()
		
		character.velocity.x = direction.x * speed
		character.velocity.z = direction.z * speed
	else:
		character.velocity.x = move_toward(character.velocity.x, 0, speed)
		character.velocity.z = move_toward(character.velocity.z, 0, speed)
		if character.current_state != character.PlayerState.IDLE:
			character.current_state = character.PlayerState.IDLE
			state_changed.emit(character.current_state)

	character.move_and_slide()
