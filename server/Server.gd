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
	var location = Vector3(0,10,0)
	print("Player: ", peer_id, " connected!")
	randomize()
	print("Attempting to instance player ", peer_id, " at ", location)
	await get_tree().create_timer(0.1).timeout
	rpc("instance_player", peer_id, location)
	#var player = Player.instantiate()
	#player.name = str(peer_id)
	#add_child(player)


@rpc("any_peer")
func instance_player(id, location):
	pass
	#var p = Player if get_tree().get_multiplayer().get_unique_id() == id else OtherPlayer
	#var player_instance = Global.instance_node(p, Nodes, location)
	#player_instance.name = str(id)
	#print("Instancing player ", id, " at ", location)
	#add_child(player_instance)
	#if get_tree().get_multiplayer().get_unique_id() == id:
		#for i in get_tree().get_multiplayer().get_peers():
			#if i != 1:
				#instance_player(i, location)
	
func remove_player(peer_id):
	print("Player: ", peer_id, " disconnected!")
	#var player = get_node_or_null(str(peer_id))
	#if player:
		#player.queue_free()
