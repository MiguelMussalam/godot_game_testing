extends Node

## - nodes
@export_group("Nodes")

@export var flashlight : SpotLight3D
@export var flashlight_pivot : Node3D
@export var flashlight_sound : AudioStreamPlayer3D
@export var camera : Camera3D

var default_rot : Transform3D

## Sons Lanterna
@onready var sounds_pack = [
		load("res://Audio/SoundEffects/Flashlight/flashlight_sound-01.wav"),
		load("res://Audio/SoundEffects/Flashlight/flashlight_sound-02.wav"),
		load("res://Audio/SoundEffects/Flashlight/flashlight_sound-03.wav"),
		load("res://Audio/SoundEffects/Flashlight/flashlight_sound-04.wav"),
		load("res://Audio/SoundEffects/Flashlight/flashlight_sound-05.wav")
]

func _ready() -> void:
	flashlight_pivot.set_as_top_level(true)
	default_rot = flashlight_pivot.transform
	flashlight_sound.position = flashlight_pivot.position
	
func _unhandled_input(event: InputEvent) -> void:
		if Input.is_action_just_pressed("flashlight"):
			activate_flashlight()

func activate_flashlight():
	if !flashlight_sound.is_playing():
		var audio_picked = AudioStreamWAV
		audio_picked = sounds_pack.pick_random()
		flashlight_sound.stream = audio_picked
		flashlight_sound.play()
		if not flashlight_sound.is_connected("finished", Callable(self, "_on_flashlight_sound")):
			flashlight_sound.finished.connect(_on_flashlight_sound)

func _on_flashlight_sound():
	flashlight.visible = !flashlight.visible
	flashlight_sound.finished.disconnect(_on_flashlight_sound)

func _update_flashlight(delta: float):
	# 1. DEFINE O ALVO
	# O alvo ideal é a posição e orientação da câmera.
	var target_transform = camera.global_transform

	# 2. INTERPOLAR A ROTAÇÃO
	# Pega a rotação atual do pivô e a rotação alvo.
	var from_quat = flashlight_pivot.global_transform.basis.get_rotation_quaternion()
	var to_quat = target_transform.basis.get_rotation_quaternion()
	
	# Interpola suavemente entre as duas rotações.
	# Ajuste o "8.0" para uma interpolação mais rápida ou mais lenta.
	var slerped_quat = from_quat.slerp(to_quat, delta * 8.0)

	# 3. INTERPOLAR A POSIÇÃO
	# Também interpolamos a posição para um movimento ainda mais suave,
	# especialmente se a câmera tiver headbob.
	var new_pos = flashlight_pivot.global_position.lerp(target_transform.origin, delta * 8.0)

	# 4. APLICA A NOVA TRANSFORMAÇÃO GLOBAL
	# Combina a nova posição e a nova rotação.
	flashlight_pivot.global_transform.origin = new_pos
	flashlight_pivot.global_transform.basis = Basis(slerped_quat)
