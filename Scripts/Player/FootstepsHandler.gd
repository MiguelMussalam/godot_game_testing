extends Node

@export_group("Nodes")
@export var character : CharacterBody3D
@export var step_sound : AudioStreamPlayer3D
@export var camera_handler : Node
@export var RCGroundGroup : RayCast3D

@export_group("Passos")
@export var step_distance_walking: float = 1.8
@export var step_distance_running: float = 2.5
@export var step_distance_backwards: float = 1.4
@export var step_distance_stepping_up: float = 1.0
@export var step_distance_stepping_down: float = 0.7

var travelled_distance: float = 0.0 # Acumulador da distância percorrida
var stepped := false

## Sons passos
var non_repeatable_steps = []
var step_right := false

@onready var sound_pack : Dictionary = {
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

## A nova função de passo baseada em distância
func handle_step(delta : float, force_step : bool):
	var necessary_distance: float
	
	if force_step:
		necessary_distance = 0.0
		if travelled_distance > necessary_distance:
			stepped = true
			handle_step_sound()
			# O sinal do roll alterna a cada passo (esquerda/direita)
			var dir : int
			if step_right:
				dir = 1
			else:
				dir = -1
			camera_handler.current_impulse.x = camera_handler.impulse_amplitude_z_roll * dir
			# O impulso vertical é sempre para baixo
			camera_handler.current_impulse.y = -camera_handler.impulse_amplitude_y 
			travelled_distance -= necessary_distance
		else:
			stepped = false
		return
	if not character.is_on_floor():
		stepped = false
		return

	if character.is_on_floor() and character.current_state != character.PlayerState.IDLE and force_step == false:
		var horizontal_velocity = character.velocity * Vector3(1, 0, 1)
		travelled_distance += horizontal_velocity.length() * delta
	
		if character.current_state == character.PlayerState.RUNNING:
			necessary_distance = step_distance_running
		elif character.current_state == character.PlayerState.WALKING:
			necessary_distance = step_distance_walking
		elif character.current_state == character.PlayerState.WALKING_BACKWARDS:
			necessary_distance = step_distance_backwards
		elif character.current_state == character.PlayerState.STEPPING_UP:
			necessary_distance = step_distance_stepping_up
		elif character.current_state == character.PlayerState.STEPPING_DOWN:
			necessary_distance = step_distance_stepping_down

		if travelled_distance > necessary_distance:
			stepped = true
			handle_step_sound()
			# O sinal do roll alterna a cada passo (esquerda/direita)
			var dir : int
			if step_right:
				dir = 1
			else:
				dir = -1
			camera_handler.current_impulse.x = camera_handler.impulse_amplitude_z_roll * dir
			# O impulso vertical é sempre para baixo
			camera_handler.current_impulse.y = -camera_handler.impulse_amplitude_y 
			travelled_distance -= necessary_distance
		else:
			stepped = false

func handle_step_sound():
	var audio_picked : AudioStreamWAV
	if RCGroundGroup.is_colliding():
		var chao = RCGroundGroup.get_collider()
		var step_sound_list := []
		if chao.is_in_group("Grass"):
			step_sound_list = sound_pack["Grass"]
		elif chao.is_in_group("Wood"):
			step_sound_list = sound_pack["Wood"]
		elif chao.is_in_group("Tile"):
			step_sound_list = sound_pack["Tile"]
		elif chao.is_in_group("Rock"):
			step_sound_list = sound_pack["Rock"]
		else:
			return

		if step_sound_list.size() > 0:
			if non_repeatable_steps.size() >= step_sound_list.size():
				non_repeatable_steps.clear()

			audio_picked = step_sound_list[randi() % step_sound_list.size()]
			while audio_picked in non_repeatable_steps:
				audio_picked = step_sound_list[randi() % step_sound_list.size()]

			non_repeatable_steps.append(audio_picked)
	
	if step_right == false:
		step_sound.position.x = -0.3
		step_right = true
	else:
		step_sound.position.x = 0.3
		step_right = false
	
	step_sound.stream = audio_picked
	step_sound.play()
