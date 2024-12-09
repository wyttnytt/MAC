extends RigidBody3D

const CROUCH_SPEED = 20.0
const WALK_SPEED = 50.0
const MAX_WALK_SPEED = 10.0
const AIR_SPEED = 1
const SPRINT_SPEED = 80.0
const SENSITIVITY = 0.004
const BOB_FREQ = 2.0
const BOB_AMP = 0.0
const JUMP_HEIGHT = 7.0
var t_bob = 0.0
const BASE_FOV = 75.0
const FOV_CHANGE = 1
var friction = 0
var crouch = 0
var was_on_floor 
var direction = Vector3()
var velocity = Vector3()
var is_on_floor = true
var front_collided = false
var left_collided = false
var right_collided = false
var back_collided = false
var is_roofed = false
var thirdperson = false
var jump_vector = Vector3(-100,-JUMP_HEIGHT,-100)
var crouch_check = false
var slide_check = false
var fixed_direction = 0
var lock_direction = false
var test1 = 0
var test2 = 0
var test3 = Vector3.ZERO
var last_input = Vector3.ZERO
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var coyote = $CoyoteTimer
@onready var collision = $CollisionShape3D
@onready var floor = $"../floor" 	
@onready var raycast = $RayCast3D
@onready var front = $Head/front
@onready var left = $Head/left
@onready var right = $Head/right
@onready var back = $Head/back
@onready var upboy = $upboy
@onready var othercamera = $Head/pivot/FOVcamera
@onready var pivot = $Head/pivot
@onready var label = $"../crouch_status"
@onready var label2 = $"../total_linear_velocity"
@onready var label3 = $"../Linear_x"
@onready var label4 = $"../Linear_v"
@onready var central_force_label_z := $"../central_force_z"
@onready var central_force_label_x := $"../central_force_x"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.set_contact_monitor(true)
	self.set_max_contacts_reported(999)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	linear_damp = 2
	raycast.enabled = true
	upboy.enabled = true
	front.set_monitoring(true)
	left.set_monitoring(true)
	right.set_monitoring(true)
	back.set_monitoring(true)
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if othercamera.current == true:
			head.rotate_y(-event.relative.x * SENSITIVITY)
			pivot.rotate_x(-event.relative.y * SENSITIVITY)
			pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-40), deg_to_rad(60))
		else:
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

func _uncrouch_collision() -> bool:
	upboy.force_raycast_update()  # Update the raycast position
	if upboy.is_colliding():
		var collision_point = upboy.get_collision_point()
		var collider = upboy.get_collider()
		return true
	return false
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _touching_wall(vector) -> Vector3:
	if front_collided:
		vector.z = clamp(vector.z,-0.5,1)
	if back_collided:
		vector.z = clamp(vector.z,-1,0.5)
	if left_collided:
		vector.x = clamp(vector.x,-0.5,1)
	if right_collided:
		vector.x = clamp(vector.x,-1,0.5)
	return vector

func _process(delta: float) -> void:
	label2.text = "Total absolute velocity= " + str(abs(linear_velocity.x)+abs(linear_velocity.z))
	label3.text = "velocity x = " + str(linear_velocity.x)
	label4.text = "velocity z = " + str(linear_velocity.z)
	var input:= Vector3.ZERO
	if not slide_check:
		input.x = Input.get_axis("left", "right")
		input.z = Input.get_axis("forward", "back")
		test1 = input.x
		test2 = input.z
		test3 = input
		linear_damp = 2
		
	input = _touching_wall(input)
	if slide_check:
		linear_damp = 0.1
		if not lock_direction:
			last_input = input
			fixed_direction = head.transform.basis
			#print((fixed_direction * Vector3(10, 0, 10)).normalized())
			apply_central_impulse(last_input * Vector3(10, 0, 10))
		input = (fixed_direction * input).normalized()
		lock_direction = true
	else:
		lock_direction = false
		input = (head.transform.basis * input).normalized()
	var v = sqrt(pow(linear_velocity.x,2)+pow(linear_velocity.y,2)+pow(linear_velocity.z,2))	
	is_on_floor = _touching_floor()
	is_roofed = _uncrouch_collision()
	if Input.is_action_just_pressed("jump") and is_on_floor:
		apply_central_impulse(Vector3(input.x,1.0*JUMP_HEIGHT,input.z))
	elif abs(v) < MAX_WALK_SPEED:
		if not is_on_floor:
			if crouch == -1:
				linear_damp = 0.2
			set_inertia(jump_vector)
			set_gravity_scale(1.5)
			apply_central_impulse(input*AIR_SPEED*delta)
		else:
			if crouch:
				apply_central_impulse(input*CROUCH_SPEED*delta)
			else:
				apply_central_impulse(input*WALK_SPEED*delta)
	else: 
		pass
	#crouching below
	if Input.is_action_just_pressed("crouch"):
		crouch = 1
	elif Input.is_action_just_released("crouch"):
		crouch = -1
	elif crouch == 1 and abs(linear_velocity.x)+abs(linear_velocity.z)<10 and not slide_check: 
		crouch = 0
		$"../AnimationPlayer".play("crouch")
		label.text = "crouch down"
		linear_damp = 8
		linear_velocity = Vector3(0,0,0)
		crouch_check = true
	if crouch == -1 and not is_roofed and abs(linear_velocity.x)+abs(linear_velocity.z)<10 and not slide_check:
		crouch = 0
		$"../AnimationPlayer".play_backwards("crouch")
		label.text = "crouch up"
		set_gravity_scale(1)
		linear_damp = 2
		crouch_check = false
	elif crouch == 1 and abs(linear_velocity.x)+abs(linear_velocity.z)>10 and not crouch_check: 
		crouch = 0
		slide_check = true
		$"../AnimationPlayer".play("crouch")
		label.text = "slide down"
	elif crouch == -1 and not is_roofed and not crouch_check:
		crouch = 0
		slide_check = false
		$"../AnimationPlayer".play_backwards("crouch")
		label.text = "slide up"
	if Input.is_action_just_pressed("thirdperson"):
		if not thirdperson:
			print("asd")
			thirdperson = true
			othercamera.current = true
		else:
			thirdperson = false
			camera.current = true
	central_force_label_x.text = str(head.transform.basis.x)
	central_force_label_z.text = str(head.transform.basis.z)



func _on_front_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	front_collided = true # Replace with function body.


func _on_front_body_shape_exited(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	front_collided = false # Replace with function body.


func _on_back_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	back_collided = true # Replace with function body.


func _on_back_body_shape_exited(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	back_collided = false # Replace with function body.


func _on_left_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	left_collided = true # Replace with function body.


func _on_left_body_shape_exited(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	left_collided = false # Replace with function body.


func _on_right_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	right_collided = true # Replace with function body.


func _on_right_body_shape_exited(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	right_collided = false # Replace with function body.
