[gd_scene load_steps=28 format=2]

[ext_resource path="res://assets/Materials/vehicles/car_blue_body.tres" type="Material" id=1]
[ext_resource path="res://assets/Materials/terrain/cement.tres" type="Material" id=2]
[ext_resource path="res://assets/sounds/587193__derplayer__explosion-big-02.ogg" type="AudioStream" id=3]

[sub_resource type="PhysicsMaterial" id=1]
bounce = 0.18

[sub_resource type="GDScript" id=17]
script/source = "extends RigidBody


var take_damage = false
# Declare member variables here. 
var timer = 1.0
var bomb_stage = 0  # 0=turned on, 1=inactive waiting for timer to count to 0, 2=active, 3=triggered (car proximity), 4=explode, 5=animation and sound
var print_timer = 0.0
var player_number
const EXPLOSION_STRENGTH = 10000.0  #200.0
var explosion_range = 10.0  # {TYPES.NOT_SET: 0.0, TYPES.MINE: 10.0, TYPES.BOMB: 10.0, TYPES.NUKE: 1000.0}
var explosion_exponent = 1.5
var explosion_decrease = 1.0
const BOMB_START_WAIT = 3.0  # wait time when first turned on to activation
const BOMB_ACTIVE_WAIT = 1.0
const BOMB_PROXIMITY_DISTANCE = 5.0
var rng = RandomNumberGenerator.new()
var explode = false
const FLASH_TIMER_WAIT = 0.25
var bomb_proximity_check_timer = 1.0
var bomb_proximity_timer_limit = 20
var bomb_inactive_timer = 1.0
var material_green
var material_red
var material_orange
var material_black
var bomb_flash_state = 0
var flash_timer = 0.25
var hit_on_contact = false
enum TYPES {NOT_SET, MINE, BOMB, NUKE}
var type = TYPES.NOT_SET


# Called when the node enters the scene tree for the first time.
func _ready():
	material_green = SpatialMaterial.new() #Make a new Spatial Material
	material_green.albedo_color = Color(0.0, 1.0, 0.0, 1.0) #Set color of new material
	material_red = SpatialMaterial.new() #Make a new Spatial Material
	material_red.albedo_color = Color(1.0, 0.0, 0.0, 1.0) #Set color of new material
	material_orange = SpatialMaterial.new()
	material_orange.albedo_color = Color(1.0, 0.5, 0.0, 1.0) #Set color of new material
	material_black = SpatialMaterial.new() #Make a new Spatial Material
	material_black.albedo_color = Color(0.0, 0.0, 0.0, 0.0) #Set color of new material


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	print_timer += delta
	flash_timer -= delta
	bomb_proximity_check_timer -= delta
	bomb_proximity_timer_limit -= delta
	
	#if material_green == null:
	#	material_green = $Body.get_node(\"MeshInstance\").material[0]
	#	#material_green = $Body.get_node(\"MeshInstance2\").material[0]
	
	#if print_timer > 1.0:
	#		if player_number != null:
	#		if player_number == 1:
	#			print(\"player_number = \"+str(player_number))
	#			print(\"  real bomb timer = \"+str(timer))
	#			print(\"  real bomb bomb_proximity_timer_limit = \"+str(bomb_proximity_timer_limit))
	#			print(\"  real bomb_stage = \"+str(bomb_stage))
	#			print(\"  real bomb visible = \"+str(visible))
	#			print(\"  $Particles.emitting = \"+str($Particles.emitting))  
	#			print(\"  $explosion.playing = \"+str($explosion.playing))
	#	print_timer = 0.0
	
	if bomb_stage == 1:
		bomb_inactive_timer -= delta
		if bomb_inactive_timer <= 0.0:
			bomb_inactive_timer = BOMB_START_WAIT  # rest for next time
			bomb_stage = 2
			bomb_proximity_timer_limit = 20  # to ensure we don't wait forever, e.g. if the bomb is stuck somewhere it can't be activated
			material_override(material_orange)
		
	if bomb_stage == 2:  # active waiting for proximity to car 
		if bomb_proximity_check_timer <= 0:  # check proximity regularly, not too often
			for player in get_node(\"/root/TownScene\").get_players():  # i in range(1, 5):
				# explosion toward all players
				var carbody = player.get_carbody()  # get_node(\"../InstancePos\"+str(i)+\"/VC/V/CarBase/Body\")
				var distance = global_transform.origin.distance_to(carbody.global_transform.origin)
				if distance < BOMB_PROXIMITY_DISTANCE or bomb_proximity_timer_limit <= 0:
					bomb_stage = 3  # trigged by proximity to car
					material_override(material_red)
					timer = BOMB_ACTIVE_WAIT
			bomb_proximity_check_timer = BOMB_ACTIVE_WAIT/4.0

	if bomb_stage == 3:  # triggered by car proximity
		timer -= delta
		if timer <= 0.0:
			timer = BOMB_ACTIVE_WAIT
			visible = false
			#	print(\"  real bomb Body.visible = \"+str($Body.visible))'''
			bomb_stage = 4
			material_override(material_green)
					
		if timer < BOMB_ACTIVE_WAIT/2.0:
			if flash_timer <= 0.0:
				flash_timer = BOMB_ACTIVE_WAIT/4.0
				if bomb_flash_state == 0:
					material_override(material_red)
					bomb_flash_state = 1
				else:
					material_override(material_black)
					bomb_flash_state = 0
	
	if bomb_stage == 5:
		if  bomb_proximity_timer_limit < 0.0 or ($Particles.emitting == false and $explosion.playing == false):
			# explosion particles have finished, explosion sound has finished, so disable the bomb
			bomb_stage = 0
			visible = false


func get_players():
	return get_node(\"/root/TownScene\").get_players()


func get_bombs():
	return get_node(\"/root/TownScene\").get_players()


func _physics_process(_delta):
	if bomb_stage == 4:
		hide_meshinstances()
		$explosion.playing = true
		# $explosion.seek(1.0)
		$Particles.global_transform.origin = global_transform.origin
		$Particles.emitting = true
		var targets = []
		for player in get_players():  # i in range(1,5): # explosion toward all players
			var target = player.get_carbody()  # get_node(\"../InstancePos\"+str(i)+\"/VC/V/CarBase/Body\")
			targets.append(target)
		for bomb in get_bombs():  # i in range(1,5):  # explosion toward all bombs
			# if i != player_number:
			var target = bomb  # get_node(\"../Bomb\"+str(i)+\"/Body\")
			targets.append(target)
		for target in targets:
			var distance = global_transform.origin.distance_to(target.global_transform.origin)
			#print(\"target.name=\"+str(target.name))
			if distance < explosion_range and \"CarBody\" in target.name:
				var direction = target.transform.origin - transform.origin  
				# direction[2]+=5.0  # slight upward force as well
				var explosion_force = EXPLOSION_STRENGTH/pow((explosion_decrease*distance)+1.0, explosion_exponent)  # inverse square of distance
				if type == TYPES.NUKE and target.player_number == player_number:
					explosion_force = 0.0
				target.apply_impulse( Vector3(0,0,0), explosion_force*direction.normalized() )   # offset, impulse(=direction*force)
				target.angular_velocity  = Vector3(5.0*randf(),5.0*randf(),5.0*randf())
				if target.take_damage == true:
					if type == TYPES.NUKE:
						if target.player_number != player_number:
							target.damage(10)
						# else don't take damage from player that launched it
					else:
						target.damage(2)
				
					
		bomb_stage = 5
		bomb_proximity_check_timer = BOMB_ACTIVE_WAIT *4  # to ensure we don't wait forever


func material_override(material):
	get_node(\"MeshInstance\").material_override = material
	get_node(\"MeshInstance2\").material_override = material


func activate(pos, linear_velocity, angular_velocity):
	visible = true
	global_transform.origin = pos  # $Body/MinePosition.global_transform.origin
	bomb_stage = 1
	timer = BOMB_START_WAIT
	material_override(material_green)
	linear_velocity = linear_velocity
	angular_velocity = angular_velocity
	rotation_degrees = Vector3(0.0, 0.0, 0.0)


func _on_Bomb_body_entered(_body):
	if hit_on_contact:
		timer = BOMB_ACTIVE_WAIT
		bomb_stage = 4


func set_as_mine():
	hit_on_contact = false
	$MeshInstance.visible = true
	$MeshInstance2.visible = true
	$MeshInstance3.visible = false
	$MeshInstance4.visible = false
	$MeshInstance5.visible = false
	$NukeBody.visible = false
	$NukeFin1.visible = false
	$NukeFin2.visible = false
	type = TYPES.NUKE  # MINE
	explosion_range = 10.0
	explosion_exponent = 1.5
	explosion_decrease = 1.0 


func set_as_bomb():
	hit_on_contact = true
	$MeshInstance.visible = false
	$MeshInstance2.visible = false
	$MeshInstance3.visible = true
	$MeshInstance4.visible = true
	$MeshInstance5.visible = true
	$NukeBody.visible = false
	$NukeFin1.visible = false
	$NukeFin2.visible = false
	type = TYPES.BOMB
	explosion_range = 10.0
	explosion_exponent = 1.5
	explosion_decrease = 1.0


func set_as_nuke():
	hit_on_contact = true
	$MeshInstance.visible = false
	$MeshInstance2.visible = false
	$MeshInstance3.visible = false
	$MeshInstance4.visible = false
	$MeshInstance5.visible = false
	$NukeBody.visible = true
	$NukeFin1.visible = true
	$NukeFin2.visible = true
	type = TYPES.NUKE
	explosion_range = 1000.0
	explosion_exponent = 1.05
	explosion_decrease = 0.05


func hide_meshinstances():
	$MeshInstance.visible = false
	$MeshInstance2.visible = false
	$MeshInstance3.visible = false
	$MeshInstance4.visible = false
	$MeshInstance5.visible = false
"

[sub_resource type="CylinderMesh" id=11]
height = 1.091

[sub_resource type="CylinderShape" id=12]
height = 1.08911

[sub_resource type="CubeMesh" id=13]

[sub_resource type="Gradient" id=9]
offsets = PoolRealArray( 0, 0.477273, 1 )
colors = PoolColorArray( 1, 0, 0, 1, 0.832031, 0.50773, 0.162506, 1, 0.605469, 0.54708, 0.231781, 1 )

[sub_resource type="GradientTexture" id=18]
gradient = SubResource( 9 )

[sub_resource type="Curve" id=4]
_data = [ Vector2( 0, 1 ), 0.0, -1.36733, 0, 0, Vector2( 1, 0 ), -0.118322, 0.0, 0, 0 ]

[sub_resource type="CurveTexture" id=19]
curve = SubResource( 4 )

[sub_resource type="ParticlesMaterial" id=6]
direction = Vector3( 1, 1, 1 )
spread = 180.0
initial_velocity = 11.63
damping = 13.73
scale_curve = SubResource( 19 )
color_ramp = SubResource( 18 )

[sub_resource type="SpatialMaterial" id=20]
vertex_color_use_as_albedo = true

[sub_resource type="SphereMesh" id=8]
material = SubResource( 20 )

[sub_resource type="CapsuleMesh" id=21]

[sub_resource type="CubeMesh" id=22]

[sub_resource type="SpatialMaterial" id=28]
albedo_color = Color( 0.0431373, 0.368627, 0.109804, 1 )
metallic = 0.21

[sub_resource type="SpatialMaterial" id=29]
albedo_color = Color( 0.972549, 0.913725, 0.0196078, 1 )
metallic = 0.4

[sub_resource type="SpatialMaterial" id=30]
albedo_color = Color( 0.972549, 0.913725, 0.0196078, 1 )
metallic = 0.4

[sub_resource type="Gradient" id=23]
offsets = PoolRealArray( 0, 0.142857, 0.273292, 0.447205 )
colors = PoolColorArray( 0.986816, 0.0077095, 0.0077095, 1, 0.983398, 1, 0, 1, 1, 0, 0, 1, 0.0258789, 0.0253735, 0.0253735, 1 )

[sub_resource type="GradientTexture" id=15]
gradient = SubResource( 23 )

[sub_resource type="Curve" id=24]
_data = [ Vector2( 0, 1 ), 0.0, -1.36733, 0, 0, Vector2( 1, 0 ), -0.118322, 0.0, 0, 0 ]

[sub_resource type="CurveTexture" id=16]
curve = SubResource( 24 )

[sub_resource type="ParticlesMaterial" id=25]
direction = Vector3( 1, 1, 1 )
spread = 180.0
gravity = Vector3( 0, 0, 0 )
initial_velocity = 1.0
scale = 0.25
scale_curve = SubResource( 16 )
color_ramp = SubResource( 15 )

[sub_resource type="SpatialMaterial" id=26]
flags_transparent = true
flags_unshaded = true
vertex_color_use_as_albedo = true

[sub_resource type="SphereMesh" id=27]
material = SubResource( 26 )

[node name="Bomb" type="RigidBody" groups=["bomb"]]
mass = 20.0
physics_material_override = SubResource( 1 )
contacts_reported = 1
contact_monitor = true
script = SubResource( 17 )

[node name="MeshInstance" type="MeshInstance" parent="."]
transform = Transform( 0.3, 0, 0, 0, 0.2, 0, 0, 0, 0.3, 0, 0, 0 )
mesh = SubResource( 11 )
material/0 = ExtResource( 2 )

[node name="CollisionShape" type="CollisionShape" parent="."]
transform = Transform( 0.5, 0, 0, 0, 0.5, 0, 0, 0, 0.5, 0, 0, 0 )
shape = SubResource( 12 )

[node name="MeshInstance2" type="MeshInstance" parent="."]
transform = Transform( 0.1, 0, 0, 0, 0.05, 0, 0, 0, 0.1, 0, 0.15282, 0 )
mesh = SubResource( 13 )
material/0 = ExtResource( 2 )

[node name="Particles" type="Particles" parent="."]
emitting = false
amount = 30
lifetime = 0.26
one_shot = true
explosiveness = 0.54
local_coords = false
process_material = SubResource( 6 )
draw_pass_1 = SubResource( 8 )

[node name="explosion" type="AudioStreamPlayer" parent="."]
stream = ExtResource( 3 )
volume_db = -6.992

[node name="SpotLight" type="SpotLight" parent="."]
transform = Transform( 1, 0, 0, 0, -4.37114e-08, 1, 0, -1, -4.37114e-08, 0, 0, 0 )
light_color = Color( 1, 0, 0, 1 )
spot_range = 154.993
spot_angle = 11.97

[node name="MeshInstance3" type="MeshInstance" parent="."]
transform = Transform( 0.291023, 0, 0, 0, -0.00910172, -0.3325, 0, 0.295343, -0.00808462, 0, 0.341193, 0 )
mesh = SubResource( 21 )
material/0 = ExtResource( 1 )

[node name="MeshInstance4" type="MeshInstance" parent="."]
transform = Transform( 0.249905, 0, 0, 0, 0.257885, 0, 0, 0, 0.0271301, 0, 0.880656, 0 )
mesh = SubResource( 22 )
material/0 = ExtResource( 1 )

[node name="MeshInstance5" type="MeshInstance" parent="."]
transform = Transform( -1.09237e-08, 0, -0.0271301, 0, 0.257885, 0, 0.249905, 0, -1.18589e-09, 0, 0.866959, 0 )
mesh = SubResource( 22 )
material/0 = ExtResource( 1 )

[node name="NukeBody" type="MeshInstance" parent="."]
transform = Transform( 1, 0, 0, 0, -0.0308028, -0.999525, 0, 0.999525, -0.0308028, 0, 1.34651, 0 )
mesh = SubResource( 21 )
material/0 = SubResource( 28 )

[node name="NukeFin1" type="MeshInstance" parent="."]
transform = Transform( 0.881522, 0, 0, 0, 0.950328, 0, 0, 0, 0.0227092, 0, 2.55986, 0 )
mesh = SubResource( 22 )
material/0 = SubResource( 29 )

[node name="NukeFin2" type="MeshInstance" parent="."]
transform = Transform( -3.85325e-08, 0, -0.0238011, 0, 0.950328, 0, 0.841083, 0, -9.92653e-10, 0, 2.54532, 0 )
mesh = SubResource( 22 )
material/0 = SubResource( 30 )

[node name="Particles2" type="Particles" parent="."]
transform = Transform( 0.999999, 0, 0, 0, 1, 0, 0, 0, 0.999999, 0, 1.18394, -0.0071068 )
visible = false
emitting = false
amount = 20
lifetime = 1.21
local_coords = false
process_material = SubResource( 25 )
draw_pass_1 = SubResource( 27 )

[connection signal="body_entered" from="." to="." method="_on_Bomb_body_entered"]