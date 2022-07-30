extends Node
class_name PowerUps

var total_num_health_powerups = 10
var total_num_shield_powerups = 10
var total_num_nuke_powerups = 1


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _process(_delta):
	var _num_health_powerups = 0
	var _num_shield_powerups = 0
	var _num_nuke_powerups = 0
	for ch in get_children():
		if ch is PowerUp:
			if ch.type == ConfigWeapons.PowerupType.HEALTH:
				_num_health_powerups += 1
			elif ch.type == ConfigWeapons.PowerupType.SHIELD:
				_num_shield_powerups += 1
			elif ch.type == ConfigWeapons.PowerupType.NUKE:
				_num_nuke_powerups += 1

	for npu in [
		[_num_health_powerups, ConfigWeapons.PowerupType.HEALTH, total_num_health_powerups], 
		[_num_shield_powerups, ConfigWeapons.PowerupType.SHIELD, total_num_shield_powerups]]:
		if npu[0] < npu[2]:
			#Global.debug_print(3, "PowerupType.keys() = "+str(ConfigWeapons.PowerupType.keys()), "powerups")
			var type_str = ConfigWeapons.PowerupType.keys()[npu[1]]
			Global.debug_print(3, "Respawning new powerup of type "+type_str, "powerups")
			var new_powerup = load(Global.power_up_folder).instance()  # it will set to 0=MOVE automatically
			new_powerup.rng.randomize()
			new_powerup.get_node("TimerPeriodicMove").wait_time = 5.0 + (new_powerup.rng.randf()*10.0)
			new_powerup.name = "PowerUp"+type_str
			new_powerup.type = npu[1]
			add_child(new_powerup)  
			new_powerup.get_node("ActivationSound").play()  


func _on_TimerCheckPowerups_timeout():
	
	if not $NukeSpawnPoint.has_node("PowerUpNuke") and $TimerNukePowerUp.is_stopped():
		$TimerNukePowerUp.set_paused(false)
		$TimerNukePowerUp.start(10.0)
		
	#if not $Powerups/ShieldPowerupSpawnPoint.has_node("PowerUpShield1") and $Powerups/TimerShieldPowerup.is_stopped():
	#	$Powerups/TimerShieldPowerup.set_paused(false)
	#	$Powerups/TimerShieldPowerup.start(10.0)
	
	#if not $Powerups/HealthPowerupSpawnPoint.has_node("PowerUpHealth1") and $Powerups/TimerHealthPowerup.is_stopped():
	#	$Powerups/TimerHealthPowerup.set_paused(false)
	#	$Powerups/TimerHealthPowerup.start(10.0)


func _on_TimerNukePowerUp_timeout():
	Global.debug_print(3, "_on_TimerNukePowerUp_timeout")
	if $TimerNukePowerUp.is_stopped():
		Global.debug_print(3, "Respawning new_nuke_powerup")
		var new_nuke_powerup = load(Global.power_up_folder).instance()
		new_nuke_powerup.name = "PowerUpNuke"
		new_nuke_powerup.type = ConfigWeapons.PowerupType.NUKE
		$NukeSpawnPoint.add_child(new_nuke_powerup)
		new_nuke_powerup.get_node("ActivationSound").play()

