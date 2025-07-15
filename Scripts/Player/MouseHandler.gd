class_name MouseHandler
extends Node

## - CODE FROM "Yo Soy Freeman" -> github: https://yosoyfreeman.github.io/

## - nodes
@export_group("Nodes")

## - Character root node.
@export var character : CharacterBody3D

## - Head node.
@export var camera_pivot : Node3D

## - Settings.
@export_group("Settings")

## - Mouse settings.
@export_subgroup("Mouse settings")

## - Mouse sensitivity.
@export_range(1, 1000, 1) var mouse_sensitivity: int = 100

## - Pitch clamp settings.
@export_subgroup("Clamp settings")

## - Max pitch in degrees.
@export var max_pitch : float = 80

## - Min pitch in degrees.
@export var min_pitch : float = -80

func _ready():
	Input.set_use_accumulated_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event)->void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		aim_look(event)


## - Handles aim look with the mouse.
func aim_look(event: InputEventMouseMotion)-> void:
	var motion: Vector2 = event.relative
	var degrees_per_unit: float = 0.001
	
	motion *= mouse_sensitivity
	motion *= degrees_per_unit
	
	add_yaw(motion.x)
	add_pitch(motion.y)
	clamp_pitch()


## - Rotates the character around the local Y axis by a given amount (In degrees) to achieve yaw.
func add_yaw(amount)->void:
	if is_zero_approx(amount):
		return
	
	character.rotate_object_local(Vector3.DOWN, deg_to_rad(amount))
	character.orthonormalize()


## - Rotates the camera_pivot around the local x axis by a given amount (In degrees) to achieve pitch.
func add_pitch(amount)->void:
	if is_zero_approx(amount):
		return
	
	camera_pivot.rotate_object_local(Vector3.LEFT, deg_to_rad(amount))
	camera_pivot.orthonormalize()


## - Clamps the pitch between min_pitch and max_pitch.
func clamp_pitch()->void:
	if camera_pivot.rotation.x > deg_to_rad(min_pitch) and camera_pivot.rotation.x < deg_to_rad(max_pitch):
		return
	
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
	camera_pivot.orthonormalize()
