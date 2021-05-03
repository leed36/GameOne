extends Node

onready var mainInterface = get_parent()
onready var Player_Container = preload("res://playerContainer/scenes/PlayerContainer.tscn") # Relative path

var awaitingVerification = {}

func start(playerId):
	awaitingVerification[playerId] = {"Timestamp": OS.get_unix_time()}
	mainInterface.fetch_token(playerId)

func verify(playerId, token):
	var tokenVerification = false
	while OS.get_unix_time() - int(token.right(64)) <= 30:
		if mainInterface.expectedTokens.has(token):
			tokenVerification = true
			create_player_container(playerId)
			awaitingVerification.erase(playerId)
			mainInterface.expectedTokens.erase(token)
			break
		else:
			yield(get_tree().create_timer(2), "timeout")
	
	mainInterface.return_token_verification_results(playerId, tokenVerification)
	
	if tokenVerification == false:
		awaitingVerification.erase(playerId)
		mainInterface.network.disconnect_peer(playerId)

func _on_VerificationExpiration_timeout():
	var currentTime = OS.get_unix_time()
	var startTime
	if not awaitingVerification == {}:
		for key in awaitingVerification.keys():
			startTime = awaitingVerification[key].Timestamp
			if currentTime - startTime >= 30:
				awaitingVerification.erase(key)
				var connectedPeers = Array(get_tree().get_network_connected_peers())
				if connectedPeers.has(key):
					mainInterface.return_token_verification_results(key, false)
					mainInterface.network.disconnect_peer(key)
	print("Awaiting verification:")
	print(awaitingVerification)

func create_player_container(playerId):
	var newPlayerContainer = Player_Container.instance()
	newPlayerContainer.name = str(playerId)
	get_parent().add_child(newPlayerContainer, true)
	var playerContainer = get_node("../" + str(playerId))
	fill_player_container(playerContainer)
	
func fill_player_container(container):
	container.playerInventory = ServerData.testData
