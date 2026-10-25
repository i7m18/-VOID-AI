extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const MISSIONS := [
 {"title":"الفصل الأول: صدى الصحراء","brief":"عام 2034. انقطع الاتصال بحامية الساتر 7 بعد نداء استغاثة قصير. أمّن المحيط واعثر على جهاز الإرسال قبل وصول التعزيزات المعادية.","objective":"أمّن الحامية","enemies":5},
 {"title":"الفصل الثاني: آخر قافلة","brief":"قافلة إمداد احتُجزت قرب الوادي. تحرّك بين الحواجز، أوقف القوة المهاجمة وافتح الطريق للقافلة.","objective":"افتح طريق القافلة","enemies":7},
 {"title":"الفصل الثالث: مدينة بلا فجر","brief":"قنّاصون يسيطرون على أسطح المدينة وفريق استطلاع محاصر ينتظر الإخلاء. بدّل سلاحك حسب المسافة ولا تتوقف في الشوارع المكشوفة.","objective":"أنقذ فريق الاستطلاع","enemies":9},
 {"title":"الفصل الرابع: المنشأة السوداء","brief":"كشف جهاز الإرسال عن منشأة اتصالات محصنة. عطّل الحراسة الخارجية واقتحم مركز القيادة قبل محو سجلات العملية.","objective":"اخترق محيط المنشأة","enemies":11},
 {"title":"الفصل الخامس: طريق العودة","brief":"الممر الوحيد للخروج تحت السيطرة. قُد المركبة المدرعة عبر الوادي وواجه آخر موجة حتى تصل إلى نقطة الإخلاء.","objective":"أمّن نقطة الإخلاء","enemies":13}
]
var world_root: Node3D
var player: CharacterBody3D
var vehicle: Node3D
var enemies_left := 0
var mission_index := 0
var game_active := false
var mission_won := false
var hud_layer: CanvasLayer
var title_label: Label
var status_label: Label
var objective_label: Label
var story_label: Label
var message_label: Label
var menu_panel: PanelContainer
var move_state := Vector2.ZERO
var fire_held := false

func _ready() -> void:
 randomize()
 world_root = Node3D.new()
 world_root.name = "GeneratedWorld"
 add_child(world_root)
 _build_hud()
 _show_main_menu()

func _process(_delta: float) -> void:
 for child in hud_layer.get_children():
  if child.name == "TouchControls": child.visible = game_active
 if game_active and fire_held and is_instance_valid(player):
  player.fire()

func _unhandled_input(event: InputEvent) -> void:
 if not game_active or not is_instance_valid(player): return
 if event is InputEventScreenDrag:
  if event.position.x > get_viewport().get_visible_rect().size.x * 0.30:
   player.look_by(event.relative)
 elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
  player.look_by(event.relative)

func _panel_style() -> StyleBoxFlat:
 var s := StyleBoxFlat.new()
 s.bg_color = Color(0.025,0.045,0.055,0.95)
 s.border_color = Color(0.25,0.62,0.52,0.95)
 s.set_border_width_all(2)
 s.set_corner_radius_all(8)
 s.set_content_margin_all(14)
 return s

func _label(value: String, size: int=20, color: Color=Color(0.92,0.95,0.93)) -> Label:
 var l := Label.new()
 l.text = value
 l.add_theme_font_size_override("font_size",size)
 l.add_theme_color_override("font_color",color)
 l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 l.layout_direction = Control.LAYOUT_DIRECTION_RTL
 return l

func _make_button(value: String, callback: Callable, height: int=54) -> Button:
 var b := Button.new()
 b.text = value
 b.custom_minimum_size = Vector2(190,height)
 b.add_theme_font_size_override("font_size",19)
 var normal := StyleBoxFlat.new()
 normal.bg_color = Color(0.08,0.18,0.17,0.98)
 normal.border_color = Color(0.25,0.62,0.52)
 normal.set_border_width_all(1)
 normal.set_corner_radius_all(6)
 normal.set_content_margin_all(8)
 b.add_theme_stylebox_override("normal",normal)
 var hover = normal.duplicate()
 hover.bg_color = Color(0.12,0.29,0.25,1)
 b.add_theme_stylebox_override("hover",hover)
 b.pressed.connect(callback)
 return b

func _build_hud() -> void:
 hud_layer = CanvasLayer.new()
 add_child(hud_layer)
 var top := PanelContainer.new()
 top.position = Vector2(14,14)
 top.custom_minimum_size = Vector2(430,120)
 top.add_theme_stylebox_override("panel",_panel_style())
 hud_layer.add_child(top)
 var col := VBoxContainer.new()
 top.add_child(col)
 title_label = _label("VOID FRONTLINE",22,Color(0.42,0.94,0.75))
 col.add_child(title_label)
 objective_label = _label("",17)
 col.add_child(objective_label)
 status_label = _label("",16)
 col.add_child(status_label)
 message_label = _label("",21,Color(1,0.78,0.38))
 message_label.position = Vector2(0,135)
 message_label.size = Vector2(900,58)
 message_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
 message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 hud_layer.add_child(message_label)
 story_label = _label("",16)
 story_label.position = Vector2(14,150)
 story_label.size = Vector2(430,142)
 hud_layer.add_child(story_label)

func _show_main_menu() -> void:
 game_active = false
 if is_instance_valid(menu_panel): menu_panel.queue_free()
 menu_panel = PanelContainer.new()
 menu_panel.anchor_left = 0.5
 menu_panel.anchor_right = 0.5
 menu_panel.anchor_top = 0.5
 menu_panel.anchor_bottom = 0.5
 menu_panel.offset_left = -260
 menu_panel.offset_right = 260
 menu_panel.offset_top = -230
 menu_panel.offset_bottom = 230
 menu_panel.add_theme_stylebox_override("panel",_panel_style())
 hud_layer.add_child(menu_panel)
 var col := VBoxContainer.new()
 col.add_theme_constant_override("separation",10)
 menu_panel.add_child(col)
 var title := _label("VOID FRONTLINE",31,Color(0.42,0.94,0.75))
 title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 col.add_child(title)
 var subtitle := _label("جبهة الظل • حملة عسكرية فردية",19)
 subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 col.add_child(subtitle)
 col.add_child(_label("عام 2034 — اختفت دورية كاملة على حدود الصحراء. أنت قائد آخر فريق استجابة، وكل خطوة تقربك من الحقيقة أو الفخ.",17))
 col.add_child(_make_button("ابدأ الحملة",Callable(self,"_start_campaign"),58))
 col.add_child(_label("على الهاتف: أزرار الحركة • اسحب يمين الشاشة للتصويب • إطلاق • تلقيم • تبديل السلاح",14))

func _start_campaign() -> void:
 mission_index = 0
 _start_mission()

func _start_mission() -> void:
 game_active = true
 mission_won = false
 move_state = Vector2.ZERO
 fire_held = false
 message_label.text = ""
 if is_instance_valid(menu_panel): menu_panel.queue_free()
 for child in world_root.get_children(): child.queue_free()
 for child in hud_layer.get_children():
  if child.name == "TouchControls": child.queue_free()
 player = null
 vehicle = null
 _build_world()
 _spawn_player()
 _spawn_vehicle()
 _spawn_enemies()
 _build_touch_controls()
 story_label.text = MISSIONS[mission_index]["brief"]
 _update_hud()

func _build_world() -> void:
 var ground := StaticBody3D.new()
 var mesh := MeshInstance3D.new()
 var plane := PlaneMesh.new()
 plane.size = Vector2(130,130)
 mesh.mesh = plane
 var mat := StandardMaterial3D.new()
 mat.albedo_color = Color(0.22,0.24,0.20)
 mat.roughness = 1.0
 mesh.material_override = mat
 ground.add_child(mesh)
 var coll := CollisionShape3D.new()
 var shape := BoxShape3D.new()
 shape.size = Vector3(130,0.2,130)
 coll.shape = shape
 coll.position.y = -0.1
 ground.add_child(coll)
 world_root.add_child(ground)
 for i in range(42):
  var block := StaticBody3D.new()
  var size := Vector3(randf_range(2.5,6.5),randf_range(1.5,5.0),randf_range(2.5,6.5))
  var bm := MeshInstance3D.new()
  var box := BoxMesh.new()
  box.size = size
  bm.mesh = box
  var material := StandardMaterial3D.new()
  material.albedo_color = [Color(0.28,0.29,0.25),Color(0.35,0.31,0.24),Color(0.18,0.23,0.21),Color(0.31,0.32,0.30)][i%4]
  material.roughness = 0.95
  bm.material_override = material
  block.add_child(bm)
  var cs := CollisionShape3D.new()
  var bs := BoxShape3D.new()
  bs.size = size
  cs.shape = bs
  block.add_child(cs)
  var x := randf_range(-52,52)
  var z := randf_range(-52,52)
  if absf(x)<12 and z>0 and z<20: x += 18
  block.position = Vector3(x,size.y/2,z)
  world_root.add_child(block)
 _add_structure(Vector3(0,2,-48),Vector3(18,4,2),Color(0.16,0.20,0.19))
 _add_structure(Vector3(-10,2,-40),Vector3(2,4,18),Color(0.16,0.20,0.19))
 _add_structure(Vector3(10,2,-40),Vector3(2,4,18),Color(0.16,0.20,0.19))
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-55,-25,0)
 sun.light_energy = 1.15
 world_root.add_child(sun)

func _add_structure(pos: Vector3,size: Vector3,color: Color) -> void:
 var body := StaticBody3D.new()
 var mesh := MeshInstance3D.new()
 var box := BoxMesh.new()
 box.size = size
 mesh.mesh = box
 var mat := StandardMaterial3D.new()
 mat.albedo_color = color
 mat.roughness = 1.0
 mesh.material_override = mat
 body.add_child(mesh)
 var col := CollisionShape3D.new()
 var shape := BoxShape3D.new()
 shape.size = size
 col.shape = shape
 body.add_child(col)
 body.position = pos
 world_root.add_child(body)

func _spawn_player() -> void:
 player = CharacterBody3D.new()
 player.name = "Player"
 player.position = Vector3(0,1.1,18)
 player.set_script(PlayerScript)
 world_root.add_child(player)

func _spawn_vehicle() -> void:
 vehicle = Node3D.new()
 vehicle.name = "ArmoredVehicle"
 vehicle.position = Vector3(4,0.8,13)
 var body := MeshInstance3D.new()
 var box := BoxMesh.new()
 box.size = Vector3(2.4,1.0,4.0)
 body.mesh = box
 var mat := StandardMaterial3D.new()
 mat.albedo_color = Color(0.16,0.24,0.19)
 mat.metallic = 0.35
 body.material_override = mat
 vehicle.add_child(body)
 var cabin := MeshInstance3D.new()
 var cab := BoxMesh.new()
 cab.size = Vector3(1.7,0.75,1.6)
 cabin.mesh = cab
 cabin.position = Vector3(0,0.75,-0.3)
 cabin.material_override = mat
 vehicle.add_child(cabin)
 world_root.add_child(vehicle)

func _spawn_enemies() -> void:
 enemies_left = int(MISSIONS[mission_index]["enemies"])
 for i in range(enemies_left):
  var enemy := CharacterBody3D.new()
  enemy.name = "Enemy_%02d" % i
  var angle := TAU*float(i)/float(enemies_left)
  enemy.position = Vector3(cos(angle)*randf_range(17,31),1.0,-18+sin(angle)*randf_range(13,25))
  enemy.set_script(EnemyScript)
  world_root.add_child(enemy)

func _build_touch_controls() -> void:
 var controls := Control.new()
 controls.name = "TouchControls"
 controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
 controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 hud_layer.add_child(controls)
 var h := get_viewport().get_visible_rect().size.y
 var w := get_viewport().get_visible_rect().size.x
 var left := _make_button("◀",Callable(self,"_dummy"),60)
 left.position = Vector2(18,h-145)
 left.custom_minimum_size = Vector2(70,60)
 controls.add_child(left)
 left.button_down.connect(func(): move_state.x=-1)
 left.button_up.connect(func(): if move_state.x<0: move_state.x=0)
 var right := _make_button("▶",Callable(self,"_dummy"),60)
 right.position = Vector2(170,h-145)
 right.custom_minimum_size = Vector2(70,60)
 controls.add_child(right)
 right.button_down.connect(func(): move_state.x=1)
 right.button_up.connect(func(): if move_state.x>0: move_state.x=0)
 var forward := _make_button("▲",Callable(self,"_dummy"),60)
 forward.position = Vector2(94,h-210)
 forward.custom_minimum_size = Vector2(70,60)
 controls.add_child(forward)
 forward.button_down.connect(func(): move_state.y=1)
 forward.button_up.connect(func(): if move_state.y>0: move_state.y=0)
 var back := _make_button("▼",Callable(self,"_dummy"),60)
 back.position = Vector2(94,h-80)
 back.custom_minimum_size = Vector2(70,60)
 controls.add_child(back)
 back.button_down.connect(func(): move_state.y=-1)
 back.button_up.connect(func(): if move_state.y<0: move_state.y=0)
 var fire := _make_button("إطلاق",Callable(self,"_dummy"),62)
 fire.position = Vector2(w-160,h-105)
 fire.custom_minimum_size = Vector2(140,62)
 controls.add_child(fire)
 fire.button_down.connect(func(): fire_held=true)
 fire.button_up.connect(func(): fire_held=false)
 var reload := _make_button("تلقيم",Callable(player,"reload_weapon"),45)
 reload.position = Vector2(w-160,h-165)
 controls.add_child(reload)
 var switch := _make_button("تبديل السلاح",Callable(player,"switch_weapon"),45)
 switch.position = Vector2(w-335,h-105)
 switch.custom_minimum_size = Vector2(160,45)
 controls.add_child(switch)
 var car := _make_button("ركوب / نزول",Callable(player,"toggle_vehicle"),45)
 car.position = Vector2(w-335,h-55)
 car.custom_minimum_size = Vector2(160,45)
 controls.add_child(car)
 var pause := _make_button("إيقاف",Callable(self,"_pause_game"),42)
 pause.position = Vector2(w-130,14)
 pause.custom_minimum_size = Vector2(112,42)
 controls.add_child(pause)

func _dummy() -> void:
 pass

func get_move_input() -> Vector2:
 return move_state

func _pause_game() -> void:
 game_active = false
 if is_instance_valid(menu_panel): menu_panel.queue_free()
 menu_panel = PanelContainer.new()
 menu_panel.anchor_left = 0.5
 menu_panel.anchor_right = 0.5
 menu_panel.anchor_top = 0.5
 menu_panel.anchor_bottom = 0.5
 menu_panel.offset_left = -210
 menu_panel.offset_right = 210
 menu_panel.offset_top = -140
 menu_panel.offset_bottom = 140
 menu_panel.add_theme_stylebox_override("panel",_panel_style())
 hud_layer.add_child(menu_panel)
 var col := VBoxContainer.new()
 menu_panel.add_child(col)
 col.add_child(_label("القائمة",26,Color(0.42,0.94,0.75)))
 col.add_child(_make_button("متابعة المهمة",Callable(self,"_resume_game")))
 col.add_child(_make_button("إعادة المهمة",Callable(self,"_restart_mission")))
 col.add_child(_make_button("القائمة الرئيسية",Callable(self,"_show_main_menu")))

func _resume_game() -> void:
 if is_instance_valid(menu_panel): menu_panel.queue_free()
 game_active = true

func _restart_mission() -> void:
 if is_instance_valid(menu_panel): menu_panel.queue_free()
 _start_mission()

func enemy_down() -> void:
 enemies_left = maxi(0,enemies_left-1)
 _update_hud()
 if enemies_left==0 and not mission_won:
  mission_won = true
  game_active = false
  message_label.text = "تم إنجاز المهمة"
  _show_completion_menu()

func _show_completion_menu() -> void:
 if is_instance_valid(menu_panel): menu_panel.queue_free()
 menu_panel = PanelContainer.new()
 menu_panel.anchor_left=0.5
 menu_panel.anchor_right=0.5
 menu_panel.anchor_top=0.5
 menu_panel.anchor_bottom=0.5
 menu_panel.offset_left=-230
 menu_panel.offset_right=230
 menu_panel.offset_top=-150
 menu_panel.offset_bottom=150
 menu_panel.add_theme_stylebox_override("panel",_panel_style())
 hud_layer.add_child(menu_panel)
 var col := VBoxContainer.new()
 menu_panel.add_child(col)
 col.add_child(_label("اكتملت المهمة",27,Color(0.42,0.94,0.75)))
 if mission_index<MISSIONS.size()-1:
  col.add_child(_label("وصلت إلى نهاية هذا الفصل، لكن الإشارة تقود إلى موقع أخطر.",17))
  col.add_child(_make_button("الفصل التالي",Callable(self,"_next_mission"),58))
 else:
  col.add_child(_label("انتهت الحملة. أخرجت فريقك وكشفت مصدر الإشارة.",18))
  col.add_child(_make_button("إعادة الحملة",Callable(self,"_start_campaign"),58))
 col.add_child(_make_button("القائمة الرئيسية",Callable(self,"_show_main_menu")))

func _next_mission() -> void:
 mission_index += 1
 _start_mission()

func player_hit() -> void:
 _update_hud()
 if is_instance_valid(player) and player.health<=0:
  game_active=false
  message_label.text="سقطت في الميدان"
  if is_instance_valid(menu_panel): menu_panel.queue_free()
  menu_panel=PanelContainer.new()
  menu_panel.anchor_left=0.5
  menu_panel.anchor_right=0.5
  menu_panel.anchor_top=0.5
  menu_panel.anchor_bottom=0.5
  menu_panel.offset_left=-210
  menu_panel.offset_right=210
  menu_panel.offset_top=-110
  menu_panel.offset_bottom=110
  menu_panel.add_theme_stylebox_override("panel",_panel_style())
  hud_layer.add_child(menu_panel)
  var col := VBoxContainer.new()
  menu_panel.add_child(col)
  col.add_child(_label("انتهت المهمة",27,Color(1,0.55,0.38)))
  col.add_child(_make_button("إعادة المحاولة",Callable(self,"_restart_mission")))
  col.add_child(_make_button("القائمة الرئيسية",Callable(self,"_show_main_menu")))

func _update_hud() -> void:
 if not is_instance_valid(player): return
 var mission: Dictionary = MISSIONS[mission_index]
 title_label.text = mission["title"]
 objective_label.text = "الهدف: "+str(mission["objective"])
 status_label.text = "الصحة %d | الذخيرة %d | الأعداء %d | %s" % [player.health,player.get_current_ammo(),enemies_left,player.get_weapon_name()]
