extends Node

var peer = NetworkedMultiplayerENet.new()
var rng = RandomNumberGenerator.new()
var upnp = UPNP.new() 
var port = null
var my_ip = null
var queued_files = {}
var complete_downloads = []
var current_download = []

func _ready():
	get_tree().connect("files_dropped", self, "queue_file")
	get_tree().connect("network_peer_connected", self, "_network_peer_connected")
	upnp.discover(2000, 2, "InternetGatewayDevice")
	my_ip = upnp.query_external_address()
	rng.randomize()
	port = rng.randi_range(20000, 30000)

func _process(delta):
	# Queue can stack items before a connection. 
	# Poll til we have a connection and items to offload. 
	# Only send if we know they dont already have it.    # Check if something to send
	if get_tree().network_peer != null and get_tree().is_network_server() and \
	get_tree().multiplayer.get_network_connected_peers().size() > 0 and queued_files.size() > 0:
		var keys = queued_files.keys()
		for c in queued_files[keys[0]]:
			rpc("receive_data", c)
		rpc("receive_data", "EOF")
		queued_files.erase(keys[0])

	if get_tree().network_peer != null and !get_tree().is_network_server() and complete_downloads.size() > 0:
		var whole_data = PoolByteArray()
		for c in complete_downloads[0]:
			whole_data.append_array(c) 

		var write_out = File.new()
		write_out.open('C:/Users/flr/desktop/success.png', File.WRITE)
		write_out.store_buffer(whole_data)
		write_out.close()
		complete_downloads.remove(0)
		print("Filed Created")

remote func receive_data(data):
	print("Data Received: ", data)
	if data is PoolByteArray:
		current_download.append(data)
	elif data == "EOF":
		complete_downloads.append(current_download)
		print("Filed Received. # of Chunks: ", current_download.size())
		current_download = []


func queue_file(paths, screen):
	# Detect file drag&drop
	get_tree().current_scene.find_node("Drag&Drop").visible = false
	var new_entry = load("res://NewEntry.scn").instance()
	var file_name = paths[0].rsplit("\\", true, 1)
	#print("file_name", file_name)
	new_entry.get_node("FileName").text = file_name[1]
	get_tree().current_scene.find_node("EntryQueue").add_child(new_entry)
	# Load file 
	var file = File.new()
	file.open(paths[0], File.READ)
	var whole = []
	var buff_size = 12000
	var c = 0
	while c < file.get_len(): 
		var chunck = file.get_buffer(buff_size)
		whole.append(chunck)
		c += buff_size
	file.close()
	queued_files[queued_files.size()] = whole

func create_server():
#	peer.create_server(port, 1)
#	get_tree().network_peer = peer
	# TEST 
	peer.create_server(23233, 1)
	get_tree().network_peer = peer

func create_client(text):
	# seperate port and ip
	var split = text.rsplit(":", true, 1)
	var _ip = split[0]
	var _port = int(split[1])
	# Starts on attempting to connect to host, not on scene switch 
#	peer.create_client(_ip, _port)
#	get_tree().network_peer = peer
	peer.create_client("127.0.0.1", 23233)
	get_tree().network_peer = peer

func _network_peer_connected(id):
	if get_tree().is_network_server():
		get_tree().current_scene.find_node("Status").visible = true
		get_tree().current_scene.find_node("Button").visible = false
		get_tree().current_scene.find_node("label").visible = false
		
	elif get_tree().get_network_peer():
		get_tree().current_scene.find_node("Status").visible = true
		get_tree().current_scene.find_node("Label").visible = false
		get_tree().current_scene.find_node("WaitingLabel").visible = true
	
	
	
	
	
	
	
	
	
	
	
	
	
