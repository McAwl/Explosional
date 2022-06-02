extends Node


# Array of dict, in format:
# {1: {"name": "1", "vehicle": "racer", "lives_left" 2}, 
# {2: "name": "2", "vehicle": "rally"}, 
# {3: "name": "3", "vehicle": "tank"}, 
# {4: "name": "4", "vehicle": "racer"}]
var players  #  

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func configure_players():
	print("players="+str(players))
	for p in players.keys():
		print("p="+str(p))
		players[p]["lives_left"] = 3


func num_players():
	return len(players)

