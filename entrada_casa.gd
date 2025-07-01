extends Node3D


@onready var bus_backroung := AudioServer.get_bus_index("Background")
var cutoff_alvo := 22000.0
var cutoff_atual := 22000.0

@onready var bus_musica := AudioServer.get_bus_index("Música")
var som_alvo := -80.0
var som_atual := -13.0

func _on_area_entrada_body_entered(body: Node3D) -> void:
	if body.name == "Personagem":
		cutoff_alvo = 1000.0
		som_alvo = -80.0

func _on_area_saída_body_entered(body: Node3D) -> void:
	if body.name == "Personagem":
		cutoff_alvo = 22000.0
		som_alvo = -10.0
		var nodo = get_tree().get_current_scene().get_node("Musica")
		if nodo.playing == false:
			nodo.play()

func _physics_process(delta: float) -> void:
	cutoff_atual = lerp(cutoff_atual, cutoff_alvo, delta * 4)
	som_atual = lerp(som_atual, som_alvo, delta * 0.2)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Música"), som_atual)
	var effect = AudioServer.get_bus_effect(bus_backroung, 0)  # Primeiro efeito
	if effect is AudioEffectLowPassFilter:
		effect.cutoff_hz = cutoff_atual
