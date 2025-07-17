extends AudioStreamPlayer3D

@export_group("Nodes")
@export var water_particle : GPUParticles3D
@export var water_collision_box : GPUParticlesCollisionBox3D

var audio_pack :=  [load("res://Audio/SoundEffects/SinkLeak/sink_leak-01.wav"), 
					load("res://Audio/SoundEffects/SinkLeak/sink_leak-02.wav"), 
					load("res://Audio/SoundEffects/SinkLeak/sink_leak-03.wav"), 
					load("res://Audio/SoundEffects/SinkLeak/sink_leak-04.wav"), 
					load("res://Audio/SoundEffects/SinkLeak/sink_leak-05.wav"), 
					load("res://Audio/SoundEffects/SinkLeak/sink_leak-06.wav"), 
					load("res://Audio/SoundEffects/SinkLeak/sink_leak-07.wav"), 
					load("res://Audio/SoundEffects/SinkLeak/sink_leak-08.wav"), 
					load("res://Audio/SoundEffects/SinkLeak/sink_leak-09.wav"), 
					load("res://Audio/SoundEffects/SinkLeak/sink_leak-10.wav"), 
					load("res://Audio/SoundEffects/SinkLeak/sink_leak-11.wav"), 
					load("res://Audio/SoundEffects/SinkLeak/sink_leak-12.wav"), 
					load("res://Audio/SoundEffects/SinkLeak/sink_leak-13.wav"), 
					load("res://Audio/SoundEffects/SinkLeak/sink_leak-14.wav")
]

var water_drop_timer := 2.0
var water_dropped_down := 9999.9

func _ready() -> void:
	water_particle.emitting = true
	water_dropped_down = 0.3

func _physics_process(delta: float) -> void:
	water_dropped_down -= delta
	water_drop_timer -= delta
	if water_drop_timer <= 0.0:
		water_particle.emitting = true
		water_drop_timer = 2.0
		water_dropped_down = 0.3
	if water_dropped_down <= 0.0:
		stream = audio_pack.pick_random()
		play()
		water_dropped_down = 9999.9
		
		
