extends Control

@onready var bar = $TextureProgressBar

func _process(delta: float) -> void:
	bar.value = Global.L_health
