extends Node3D

func _ready():
	await get_tree().create_timer(30.0).timeout
	queue_free()
