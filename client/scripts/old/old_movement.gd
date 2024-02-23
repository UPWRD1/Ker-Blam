extends CharacterBody3D


#@export var crouch_enabled = true
@export var slide_enabled = true

@export var base_speed = 12
@export var sprint_speed = 16
@export var jump_velocity = 5
@export var sensitivity = 0.1
@export var accel = 10
@export var crouch_speed = 3
@export var slide_speed = 0
@export var wall_run_tilt_angle : float = 45.0
@export var dash_dist = 10

signal significant_action

signal display_bootmsg

var is_sigact = false
var speed = base_speed

var camera_fov_extents = [75.0, 85.0] #index 0 is normal, index 1 is sprinting
var base_player_y_scale = 1.0
var crouch_player_y_scale = 0.75
var wall_normal
var w_runnable = false

var slide_started = false  # New variable to track if slide has started

var jump_count = 0

@onready var parts = {
	"head": $Head,
	"camera": $Head/Camera3D,
	"body": $CollisionShape3D,
	"collision": $CollisionShape3D,
	"timer": $Timer,
}

enum St {
	WALKING,
	JUMPING,
	SLIDING,
	WALL_RUNNING,
	WALL_JUMPING,
	SLAMMING,
	FALLING,
}

@onready var world = get_parent()

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var direction = Vector3()
var state: St
var current_tilt_angle: float
var wallrun_angle = 15
var side = Vector3()

func show_glitch():
	pass
	#if is_sigact:
		#parts.bw_shader.visible = true
		#parts.glitch_shader.visible = true
	#else:
		#parts.glitch_shader.visible = false
		#parts.bw_shader.visible = false

func wall_run(delta):
	if w_runnable and is_on_wall():
		wall_normal = get_slide_collision(0).get_normal()
		velocity.y = 0
		side = wall_normal.cross(Vector3.UP)
		jump_count = 0
		direction = -wall_normal * speed
		#wall_running = true
		state = St.WALL_RUNNING
		speed = sprint_speed
		parts.camera.fov = lerp(parts.camera.fov, camera_fov_extents[1], 10*delta)
		parts.camera.rotation_degrees.y = lerp(parts.camera.rotation_degrees.y, 0.0, 1)
		if Input.is_action_just_pressed("MOVE_JUMP"):
			if state == St.WALL_RUNNING:
				state = St.WALL_JUMPING
				significant_action.emit()
				velocity += wall_normal * speed
				velocity.y += 3
				velocity.z += 3
				w_runnable = true
				jump_count = 0
		if not is_on_floor():
			var to_rot = 0
			if abs(fmod(parts.head.rotation_degrees.y, 180.0)) < 90.0:
				if side.dot(Vector3.RIGHT) > 0:
					to_rot = wallrun_angle
					print("a", to_rot , " " , abs(fmod(parts.head.rotation_degrees.y, 360.0)), " ", side.dot(Vector3.RIGHT))
				else:
					to_rot = -wallrun_angle
					print("b", to_rot , " " , abs(fmod(parts.head.rotation_degrees.y, 360.0)), " ", side.dot(Vector3.RIGHT))
			else:
				if side.dot(Vector3.RIGHT) <= 0:
					to_rot = wallrun_angle
					print("c", to_rot , " " , abs(fmod(parts.head.rotation_degrees.y, 360.0)), " ", side.dot(Vector3.RIGHT))
				else:
					to_rot = -wallrun_angle
					print("d", to_rot , " " , abs(fmod(parts.head.rotation_degrees.y, 360.0)), " ", side.dot(Vector3.RIGHT))

		# Set the rotation directly
			parts.camera.rotation_degrees.z = lerp(parts.camera.rotation_degrees.z, float(to_rot), 0.1)


func _reset_camera_rotation():
	parts.camera.rotation_degrees.z = lerp(parts.camera.rotation_degrees.z, 0.0, 0.1)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#world.pause.connect(_on_pause)
	#world.unpause.connect(_on_unpause)
	state = St.WALKING
	parts.camera.current = true

func _process(delta):
	wall_run(delta)
	show_glitch()
	break_sigact()
	if Input.is_action_pressed("MOVE_SLIDE") and not (state == St.WALL_RUNNING):
		if Input.is_action_just_pressed("MOVE_JUMP"):
			state = St.JUMPING
			jump()
			significant_action.emit()
		var slide_direction = Vector3()
		if !slide_started:
			slide_direction = Vector3(direction.x, 0, direction.z).normalized()
			slide_started = true

		#sliding = true
		state = St.SLIDING
		speed = slide_speed

		parts.camera.fov = lerp(parts.camera.fov, camera_fov_extents[1], 10*delta)
		parts.body.scale.y = lerp(parts.body.scale.y, crouch_player_y_scale, 20*delta) #change this to starting a crouching animation or whatever
		parts.collision.scale.y = lerp(parts.collision.scale.y, crouch_player_y_scale, 20*delta)
		velocity.x += (slide_direction.x * slide_speed) / (10 * delta)
		velocity.z += (slide_direction.z * slide_speed) / (10 * delta)
		
	else:
		state = St.WALKING
		speed = base_speed
		sensitivity = 0.1


		if slide_enabled:
			parts.camera.fov = lerp(parts.camera.fov, camera_fov_extents[0], 10*delta)

func slam():
	if not is_on_floor() and (state == St.SLAMMING):
		significant_action.emit()
		velocity = Vector3.DOWN * 100
		state = St.SLAMMING

func jump():
	if is_on_floor() or jump_count < 2 and state == St.JUMPING:
		velocity.y += jump_velocity
		jump_count += 1
		parts.timer.start()

func fall(delta):
	velocity.y -= (gravity * 1.3) * delta
	w_runnable = true
	state = St.FALLING

func move(delta):
	velocity.x = lerp(velocity.x, direction.x * speed, accel * delta)
	velocity.z = lerp(velocity.z, direction.z * speed, accel * delta)
			#jump_count = 0

func animation_bob(input_dir):
	pass

func look(event):
	self.rotation_degrees.y -= event.relative.x * sensitivity
	self.rotation_degrees.x -= event.relative.y * sensitivity
	self.rotation.x = clamp(parts.head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	#parts.head.rotation_degrees.y -= event.relative.x * sensitivity
	#parts.head.rotation_degrees.x -= event.relative.y * sensitivity
	#parts.head.rotation.x = clamp(parts.head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
func _physics_process(delta):
	wall_run(delta)
	do_sigact()
	if not is_on_floor():
		fall(delta)
	else:
		if not state == St.SLIDING:
			state = St.WALKING
			move(delta)
			#jump_count = 0
		w_runnable = false
		jump_count = 0  # Reset jump count when the jump key is released
	
	if not is_on_wall():
		_reset_camera_rotation()
		
	if Input.is_action_just_pressed("MOVE_SLAM"):
		if not is_on_floor() and not (state == St.WALL_RUNNING):
			state = St.SLAMMING
			slam()
		# Reset camera rotation when on floor

	if Input.is_action_just_pressed("MOVE_JUMP"):
		if state == St.WALL_RUNNING:
			pass
		else:
			state = St.JUMPING
			jump()

	var input_dir = Input.get_vector("MOVE_LEFT", "MOVE_RIGHT", "MOVE_FORWARD", "MOVE_BACKWARD")
	direction = input_dir.normalized().rotated(-parts.head.rotation.y)
	direction = Vector3(direction.x, 0, direction.y)

	if state == St.WALL_RUNNING:
		move(delta)

	# bob head
	animation_bob(input_dir)

	move_and_slide()

func _input(event):
	if event is InputEventMouseMotion:
		if not state == St.WALL_RUNNING:
			look(event)

func _on_pause():
	pass

func _on_unpause():
	pass

func _on_timer_timeout():
	w_runnable = false # Replace with function body.

func break_sigact():
	pass

func do_sigact():
	pass
		#if Input.is_action_pressed("do_sigact"):
			#is_sigact = true
			#Engine.time_scale = 0.1
			##velocity = Vector3.ZERO
			#await get_tree().create_timer(0.1).timeout
			#while Engine.time_scale < 1:
				#Engine.time_scale = lerp(Engine.time_scale, 1.0, 0.5)
			#is_sigact = false
