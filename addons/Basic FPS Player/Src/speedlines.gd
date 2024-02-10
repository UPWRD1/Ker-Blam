extends ColorRect

@onready var rc = $"."

var vis = 0.0
# Called when the node enters the scene tree for the first time.
func _ready():
	rc.material.set("shader_parameter/line_color", Vector4(255,255,255,0))# Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_basic_fps_player_enter_flow():
	while vis <= 0.7:
		rc.material.set("shader_parameter/line_color", Vector4(255,255,255,vis))
		vis += 0.1
		await get_tree().create_timer(0.5).timeout# Replace with function body.

func _on_basic_fps_player_exit_flow():
	while vis >= 0.0:
		rc.material.set("shader_parameter/line_color", Vector4(255,255,255,vis))
		vis -= 0.1
		await get_tree().create_timer(0.5).timeout# Replace with function body. # Replace with function body.
