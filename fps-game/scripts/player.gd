extends CharacterBody3D

const WALK_SPEED := 6.2
const CAR_SPEED := 13.5
const JUMP_VELOCITY := 4.3
const MOUSE_SENSITIVITY := 0.0022
const WEAPON_NAMES := ["بندقية هجومية","رشاش خفيف","بندقية قنص"]
const MAGAZINES := [30,45,5]
const DAMAGE := [34,19,100]
const RATES := [0.17,0.095,0.85]
var health := 100
var weapon_index := 0
var ammo := [30,45,5]
var reserve_ammo := [150,225,25]
var reloading := false
var in_vehicle := false
var camera: Camera3D
var ray: RayCast3D
var weapon_model: Node3D
var fire_timer := 0.0
var reload_token := 0

func _ready() -> void:
 add_to_group("player")
 var collider := CollisionShape3D.new()
 var capsule := CapsuleShape3D.new()
 capsule.radius=0.42
 capsule.height=1.8
 collider.shape=capsule
 add_child(collider)
 camera=Camera3D.new()
 camera.position=Vector3(0,0.55,0)
 camera.current=true
 add_child(camera)
 ray=RayCast3D.new()
 ray.target_position=Vector3(0,0,-100)
 ray.enabled=true
 ray.add_exception(self)
 camera.add_child(ray)
 _build_weapon_model()

func _build_weapon_model() -> void:
 weapon_model = Node3D.new()
 weapon_model.name = "WeaponModel"
 weapon_model.position = Vector3(0.30,-0.27,-0.58)
 camera.add_child(weapon_model)
 _update_weapon_model()

func _add_weapon_part(mesh: Mesh, position_value: Vector3, material: Material, rotation_value: Vector3=Vector3.ZERO) -> void:
 var part := MeshInstance3D.new()
 part.mesh = mesh
 part.position = position_value
 part.rotation = rotation_value
 part.material_override = material
 weapon_model.add_child(part)

func _update_weapon_model() -> void:
 if not is_instance_valid(weapon_model): return
 for child in weapon_model.get_children():
  child.free()
 var dark := StandardMaterial3D.new()
 dark.albedo_color = Color(0.075,0.09,0.085)
 dark.metallic = 0.48
 dark.roughness = 0.42
 var metal := StandardMaterial3D.new()
 metal.albedo_color = Color(0.19,0.22,0.20)
 metal.metallic = 0.68
 metal.roughness = 0.32
 var grip_mat := StandardMaterial3D.new()
 grip_mat.albedo_color = Color(0.12,0.14,0.12)
 grip_mat.roughness = 0.92
 var body_mesh := BoxMesh.new()
 body_mesh.size = Vector3(0.15,0.12,0.40 if weapon_index != 2 else 0.48)
 _add_weapon_part(body_mesh,Vector3(0,0,0),dark)
 var barrel_mesh := BoxMesh.new()
 barrel_mesh.size = Vector3(0.045,0.045,0.38 if weapon_index != 2 else 0.62)
 _add_weapon_part(barrel_mesh,Vector3(0,-0.005,-0.37 if weapon_index != 2 else -0.51),metal)
 var stock_mesh := BoxMesh.new()
 stock_mesh.size = Vector3(0.12,0.09,0.21)
 _add_weapon_part(stock_mesh,Vector3(0,0,0.27),grip_mat)
 var grip_mesh := BoxMesh.new()
 grip_mesh.size = Vector3(0.065,0.16,0.09)
 _add_weapon_part(grip_mesh,Vector3(0,0.11,0.08),grip_mat,Vector3(deg_to_rad(-12),0,0))
 var magazine_mesh := BoxMesh.new()
 magazine_mesh.size = Vector3(0.075,0.18,0.12 if weapon_index != 2 else 0.16)
 _add_weapon_part(magazine_mesh,Vector3(0,0.14,-0.055),dark,Vector3(deg_to_rad(-8),0,0))
 var handguard_mesh := BoxMesh.new()
 handguard_mesh.size = Vector3(0.105,0.09,0.22)
 _add_weapon_part(handguard_mesh,Vector3(0,0.015,-0.22),grip_mat)
 var sight_mesh := BoxMesh.new()
 sight_mesh.size = Vector3(0.055,0.045,0.07)
 _add_weapon_part(sight_mesh,Vector3(0,0.082,-0.11),metal)
 if weapon_index == 2:
  var scope := CylinderMesh.new()
  scope.top_radius = 0.055
  scope.bottom_radius = 0.055
  scope.height = 0.31
  _add_weapon_part(scope,Vector3(0,0.105,-0.10),dark,Vector3(deg_to_rad(90),0,0))
 var muzzle := BoxMesh.new()
 muzzle.size = Vector3(0.064,0.064,0.07)
 _add_weapon_part(muzzle,Vector3(0,-0.005,-0.69 if weapon_index != 2 else -0.85),dark)

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed:
  if event.keycode==KEY_ESCAPE:
   Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
  elif event.keycode==KEY_R:
   reload_weapon()
  elif event.keycode==KEY_Q:
   switch_weapon()
  elif event.keycode==KEY_E:
   toggle_vehicle()
  elif event.keycode==KEY_1:
   _set_weapon(0)
  elif event.keycode==KEY_2:
   _set_weapon(1)
  elif event.keycode==KEY_3:
   _set_weapon(2)
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
  Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
  fire()

func look_by(relative: Vector2) -> void:
 rotate_y(-relative.x*MOUSE_SENSITIVITY)
 camera.rotate_x(-relative.y*MOUSE_SENSITIVITY)
 camera.rotation.x=clamp(camera.rotation.x,-1.48,1.48)

func _physics_process(delta: float) -> void:
 var root := get_tree().current_scene
 if root and not bool(root.get("game_active")): return
 fire_timer=maxf(0.0,fire_timer-delta)
 if in_vehicle:
  velocity.y=0
 elif not is_on_floor():
  velocity.y-=18.0*delta
 var move_input:=Vector2.ZERO
 if is_instance_valid(root) and root.has_method("get_move_input"):
  move_input=root.get_move_input()
 var keys:=Vector2(float(Input.is_key_pressed(KEY_D))-float(Input.is_key_pressed(KEY_A)),float(Input.is_key_pressed(KEY_W))-float(Input.is_key_pressed(KEY_S)))
 if keys.length()>0: move_input=keys.normalized()
 var direction: Vector3=(transform.basis*Vector3(move_input.x,0,-move_input.y)).normalized()
 var speed:=CAR_SPEED if in_vehicle else WALK_SPEED
 velocity.x=direction.x*speed
 velocity.z=direction.z*speed
 if Input.is_key_pressed(KEY_SPACE) and is_on_floor() and not in_vehicle:
  velocity.y=JUMP_VELOCITY
 move_and_slide()
 if in_vehicle:
  var car=root.get("vehicle")
  if is_instance_valid(car):
   car.global_position=global_position+global_basis*Vector3(0,-0.15,0.65)
   car.global_rotation.y=rotation.y

func fire() -> void:
 if in_vehicle or reloading or fire_timer>0.0: return
 if int(ammo[weapon_index])<=0:
  reload_weapon()
  return
 fire_timer=RATES[weapon_index]
 ammo[weapon_index]=int(ammo[weapon_index])-1
 ray.force_raycast_update()
 if ray.is_colliding():
  var target=ray.get_collider()
  if is_instance_valid(target) and target.has_method("take_damage"):
   target.take_damage(DAMAGE[weapon_index])
 _update_hud()

func switch_weapon() -> void:
 _set_weapon((weapon_index+1)%WEAPON_NAMES.size())

func _set_weapon(index: int) -> void:
 weapon_index=clampi(index,0,WEAPON_NAMES.size()-1)
 _update_weapon_model()
 reloading=false
 reload_token+=1
 _update_hud()

func get_weapon_name() -> String:
 return WEAPON_NAMES[weapon_index]

func get_current_ammo() -> int:
 return int(ammo[weapon_index])

func reload_weapon() -> void:
 if reloading or int(ammo[weapon_index])>=MAGAZINES[weapon_index] or int(reserve_ammo[weapon_index])<=0: return
 reloading=true
 reload_token+=1
 var token:=reload_token
 _update_hud()
 await get_tree().create_timer(1.35 if weapon_index!=2 else 1.7).timeout
 if not is_inside_tree() or token!=reload_token: return
 var needed: int=MAGAZINES[weapon_index]-int(ammo[weapon_index])
 var loaded: int=mini(needed,int(reserve_ammo[weapon_index]))
 ammo[weapon_index]=int(ammo[weapon_index])+loaded
 reserve_ammo[weapon_index]=int(reserve_ammo[weapon_index])-loaded
 reloading=false
 _update_hud()

func toggle_vehicle() -> void:
 var root:=get_tree().current_scene
 if not is_instance_valid(root) or not bool(root.get("game_active")): return
 var car=root.get("vehicle")
 if not is_instance_valid(car): return
 if in_vehicle:
  in_vehicle=false
  global_position+=-global_basis.z*2.0+Vector3.UP*0.1
  camera.position.y=0.55
 elif global_position.distance_to(car.global_position)<5.0:
  in_vehicle=true
  global_position=car.global_position
  camera.position.y=1.35
 _update_hud()

func take_damage(amount: int) -> void:
 if in_vehicle: amount=int(ceil(float(amount)*0.45))
 health=maxi(0,health-amount)
 _update_hud()
 var root:=get_tree().current_scene
 if is_instance_valid(root) and root.has_method("player_hit"):
  root.player_hit()

func _update_hud() -> void:
 var root:=get_tree().current_scene
 if is_instance_valid(root) and root.has_method("_update_hud"):
  root._update_hud()
