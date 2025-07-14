extends Node3D

@onready var luz_defeito := $Lamparas/Lampara2_004/OmniLight3D
@onready var lampada := $Lamparas/Lampara2_004
@onready var som_luz     := $Lamparas/Lampara2_004/AudioStreamPlayer3D
@onready var som_estouro := $Lamparas/Lampara2_004/AudioStreamPlayer3D2
@onready var player_tv := $"Television /Tele_001/PlayerTV"

var entrou_quarto := false
var estourou := false
var tempo_proximo_piscar := 0.0
var intervalo_min = 0.3
var intervalo_max = 3.0
var pode_interagir := false
func _agendar_proximo_piscar():
	tempo_proximo_piscar = randf_range(intervalo_min, intervalo_max)

func _ready():
	_agendar_proximo_piscar()

func _process(delta: float) -> void:
	if estourou == false:
		tempo_proximo_piscar -= delta
	if tempo_proximo_piscar <= 0.0 and estourou == false:
		luz_defeito.visible = !luz_defeito.visible
		lampada.get_surface_override_material(0).emission_enabled = !lampada.get_surface_override_material(0).emission_enabled 
		if luz_defeito.visible:
			som_luz.play()
		else: 
			som_luz.stop()
		_agendar_proximo_piscar()

	if pode_interagir and Input.is_action_just_pressed("interagir") and player_tv.visible == false:
		player_tv.visible = true
		%VideoStreamPlayer.play()
		%AudioStreamPlayer3D.play()


func _on_area_interacao_body_entered(body: Node3D) -> void:
	if body.name == "Personagem":
		pode_interagir = true

func _on_area_interacao_body_exited(body: Node3D) -> void:
	if body.name == "Personagem":
		pode_interagir = false


func _on_audio_stream_player_3d_finished() -> void:
	player_tv.visible = false

func _on_entra_quarto_body_entered(body: Node3D) -> void:
	if body.name == "Personagem":
		entrou_quarto = true

func _on_lado_lampada_body_entered(body: Node3D) -> void:
	if body.name == "Personagem" and entrou_quarto:
		estourou = true
		luz_defeito.visible = true
		lampada.get_surface_override_material(0).emission_enabled = true
		som_luz.play()
		
		await get_tree().create_timer(0.3).timeout
		
		som_estouro.play()
		estourou = true
		lampada.get_surface_override_material(0).emission_enabled = false
		luz_defeito.visible = false
		som_luz.stop()
		$DetectaPersonagemQuebraLuz/LadoLampada.body_entered.disconnect(_on_lado_lampada_body_entered)
