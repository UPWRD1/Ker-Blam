extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	with_websocket() # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func with_multiplayer_api():
	var server = ENetMultiplayerPeer.new()
	var err = server.create_server(4242)
	if err != OK:
		print("Unable to start server!")
		set_process(false)
		return
	multiplayer.multiplayer_peer = server
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	print("Server created")

func with_websocket():
	var server = WebSocketMultiplayerPeer.new()
	var err = server.create_server(4242)
	if err != OK:
		print("Unable to start server!")
		set_process(false)
		return
	multiplayer.multiplayer_peer = server
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	print("Server created")

func add_player(peer_id):
	print("Player: ", peer_id, " connected!")
	rpc_id(0, "instance_player", peer_id, Vector3(0,0,0))
	#var player = Player.instantiate()
	#player.name = str(peer_id)
	#add_child(player)

func remove_player(peer_id):
	print("Player: ", peer_id, " disconnected!")
	#var player = get_node_or_null(str(peer_id))
	#if player:
		#player.queue_free()
