extends AudioStreamPlayer3D

@onready var audio_positions = [
	Vector3(-30.96, 0.6, -126.6), Vector3(-33.28, 0.512, -135.6), Vector3(-32.09, 0.111, -120.7),
	Vector3(-41.13, -0.161, -122.2), Vector3(-57.31, -0.161, -128.8),
	Vector3(-44.39, 3.455, -126.3), Vector3(-35.33, 3.455, -126.3),
	Vector3(-25.10, 3.455, -121.2), Vector3(-22.06, 3.455, -125.9),
	Vector3(-31.27, 3.455, -130.7)
]

@onready var sound_pack := [
	load("res://Audio/SoundEffects/WoodCrack/wood_floor_creaks-01.wav"), 
	load("res://Audio/SoundEffects/WoodCrack/wood_floor_creaks-02.wav"),
	load("res://Audio/SoundEffects/WoodCrack/wood_floor_creaks-03.wav"),
	load("res://Audio/SoundEffects/WoodCrack/wood_floor_creaks-04.wav"), 
	load("res://Audio/SoundEffects/WoodCrack/wood_floor_creaks-05.wav"),
	load("res://Audio/SoundEffects/WoodCrack/wood_floor_creaks-06.wav"),
	load("res://Audio/SoundEffects/WoodCrack/wood_floor_creaks-07.wav"),
	load("res://Audio/SoundEffects/WoodCrack/wood_floor_creaks-08.wav"), 
	load("res://Audio/SoundEffects/WoodCrack/wood_floor_creaks-09.wav"), 
	load("res://Audio/SoundEffects/WoodCrack/wood_floor_creaks-10.wav"), 
	load("res://Audio/SoundEffects/WoodCrack/wood_floor_creaks-11.wav")
]
var non_repeat_list := []
var noise_timer := 10.0

func _ready() -> void:
	global_transform.origin = audio_positions.pick_random()

func _get_random_sound():
	if non_repeat_list.size() == 6:
		non_repeat_list.clear()
	var choosen_sound = null
	while choosen_sound == null or choosen_sound in non_repeat_list:
		choosen_sound = sound_pack.pick_random()
	non_repeat_list.append(choosen_sound)
	return choosen_sound

func _process(delta: float) -> void:
	noise_timer -= delta
	if noise_timer <= 0.0:
		print("entrou")
		global_transform.origin = audio_positions.pick_random()
		print(global_transform.origin)
		self.stream = _get_random_sound()
		self.play()
		noise_timer = randf_range(10.0, 20.0)
