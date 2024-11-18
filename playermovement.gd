extends RigidBody3D
const CROUCH_SPEED = 1.0
const WALK_SPEED = 75.0
const MAX_WALK_SPEED = 15.0
const AIR_SPEED = 10.0
const SPRINT_SPEED = 80.0
const SENSITIVITY = 0.004
const BOB_FREQ = 2.0
const BOB_AMP = 0.0
const JUMP_HEIGHT = 10.0
var t_bob = 0.0
const BASE_FOV = 75.0
const FOV_CHANGE = 1
var friction = 0
var was_on_floor 
var direction = Vector3()
var velocity = Vector3()
var is_on_floor = true
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var coyote = $CoyoteTimer
@onready var collision = $CollisionShape3D
@onready var floor = $"../floor" 	
@onready var raycast = $RayCast3D
@onready var front = $front
@onready var left = $left
@onready var right = $right
@onready var back = $back
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.set_contact_monitor(true)
	self.set_max_contacts_reported(999)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	linear_damp = friction
	raycast.enabled = true
	front.enabled = true
	left.enabled = true
	right.enabled = true
	back.enabled = true
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
		
func _touching_floor() -> bool:
	raycast.force_raycast_update()  # Update the raycast position
	if raycast.is_colliding():
		var collision_point = raycast.get_collision_point()
		var collider = raycast.get_collider()
		
		return true
	return false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _touching_wall(vector) -> Vector3:
	front.force_raycast_update() 
	back.force_raycast_update() 
	left.force_raycast_update() 
	right.force_raycast_update()
	if front.is_colliding():
		vector.z = clamp(vector.z,0,999)
	if back.is_colliding():
		vector.z = clamp(vector.z,-999,0)
	if left.is_colliding():
		vector.x = clamp(vector.x,-999,0)
	if right.is_colliding():
		vector.x = clamp(vector.x,0,999)
	return vector
	
func _process(delta: float) -> void:
	var input:= Vector3.ZERO
	input.x = Input.get_axis("left", "right")
	input.z = Input.get_axis("forward", "back")	
	input = (head.transform.basis * input).normalized()
	var v = sqrt(pow(linear_velocity.x,2)+pow(linear_velocity.y,2)+pow(linear_velocity.z,2))	
	is_on_floor = _touching_floor()
	input = _touching_wall(input)
	if Input.is_action_just_pressed("jump") and is_on_floor:
		apply_central_impulse(Vector3(0.0,1.0,0.0)*JUMP_HEIGHT)
	elif abs(v) < MAX_WALK_SPEED:
		if not is_on_floor:
			apply_central_impulse(input*AIR_SPEED*delta)
		else:
			if Input.is_action_just_pressed("crouch"):
				apply_central_impulse(input*CROUCH_SPEED*delta)
			else:
				apply_central_impulse(input*WALK_SPEED*delta)			
	else: 
		pass
	#crouching below
	if Input.is_action_just_pressed("crouch"):
		$"../AnimationPlayer".play("crouch")
		print ("whar")
	elif Input.is_action_just_released("crouch"):
		$"../AnimationPlayer".play_backwards("crouch")

func _on_rigid_body_3d_body_entered(body: Node) -> void:
	$"../AnimationPlayer".pause("crouch")
	print ("amongus")

func _on_rigid_body_3d_body_exited(body: Node) -> void:
	$"../AnimationPlayer".resume("crouch")
	print ("sus")
