extends Node3D

@onready var noises := $"../InsideHouseNoises"

@onready var background := AudioServer.get_bus_index("Background")
var cutoff_alvo := 22000.0
var cutoff_atual := 22000.0

@onready var bus_musica := AudioServer.get_bus_index("Music")
var som_alvo_musica := -80.0
var som_atual_musica := -13.0

var som_alvo_inside_house := -80.0
var som_atual_inside_house := -4.0
var inside_house := false

func _on_area_entrada_body_entered(body: CharacterBody3D) -> void:
	if body.name == "Character":
		cutoff_alvo = 1000.0
		som_alvo_musica = -80.0
		som_alvo_inside_house = -4.0
		noises.play()
		inside_house = true

func _on_area_saída_body_entered(body: CharacterBody3D) -> void:
	if body.name == "Character":
		cutoff_alvo = 22000.0
		som_alvo_musica = -10.0
		som_alvo_inside_house = -80.0
		if inside_house == true:
			var music = get_tree().get_current_scene().get_node("Music")
			if music.playing == false:
				music.play()
		inside_house = false

func _physics_process(delta: float) -> void:
	cutoff_atual = lerp(cutoff_atual, cutoff_alvo, delta * 4)
	som_atual_musica = lerp(som_atual_musica, som_alvo_musica, delta * 0.5)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), som_atual_musica)
	var effect = AudioServer.get_bus_effect(background, 0)  # Primeiro efeito
	if effect is AudioEffectLowPassFilter:
		effect.cutoff_hz = cutoff_atual

	som_atual_inside_house = lerp(som_atual_inside_house, som_alvo_musica, delta * 2)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("InsideHouseNoises"), som_alvo_inside_house)
