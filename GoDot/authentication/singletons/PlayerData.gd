extends Node

var PlayerIDs

func _ready():
	var playerID_file = File.new()
	playerID_file.open("res://data/player_id_test.json", File.READ)
	var json = JSON.parse(playerID_file.get_as_text())
	playerID_file.close()
	PlayerIDs = json.result