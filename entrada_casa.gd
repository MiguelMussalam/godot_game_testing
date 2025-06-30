extends Node3D

var cutoff_alvo := 22000.0
var cutoff_atual := 22000.0
@onready var bus_backroung := AudioServer.get_bus_index("Background")

func _on_area_entrada_body_entered(body: Node3D) -> void:
	if body.name == "Personagem":
		cutoff_alvo = 1000.0

func _on_area_saída_body_entered(body: Node3D) -> void:
	if body.name == "Personagem":
		cutoff_alvo = 22000.0

func _physics_process(delta: float) -> void:
	#print(cutoff_atual)
	cutoff_atual = lerp(cutoff_atual, cutoff_alvo, delta * 4)
	var effect = AudioServer.get_bus_effect(bus_backroung, 0)  # Primeiro efeito
	if effect is AudioEffectLowPassFilter:
		effect.cutoff_hz = cutoff_atual
