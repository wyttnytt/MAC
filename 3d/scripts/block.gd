extends RigidBody3D
@onready var coll = $CollisionShape3D
@onready var block = $"."
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	coll.scale.x = block.scale.x
	coll.scale.y = block.scale.y
	coll.scale.z = block.scale.z
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
