extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")

var player: CharacterBody3D
var enemies_left := 5
var mission_label: Label
var status_label: Label
var crosshair: Label

func _ready() -> void:
    _build_world()
    _spawn_player()
    _spawn_enemies()
    _build_hud()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_world() -> void:
    var ground := StaticBody3D.new()
    ground.name = "Ground"
    var mesh := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(90, 90)
    mesh.mesh = plane
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.16, 0.20, 0.19)
    mat.roughness = 1.0
    mesh.material_override = mat
    ground.add_child(mesh)
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(90, 0.2, 90)
    shape.shape = box
    shape.position.y = -0.1
    ground.add_child(shape)
    add_child(ground)
    for i in range(22):
        var block := StaticBody3D.new()
        var bmesh := MeshInstance3D.new()
        var boxmesh := BoxMesh.new()
        boxmesh.size = Vector3(randf_range(2, 5), randf_range(1.5, 4), randf_range(2, 5))
        bmesh.mesh = boxmesh
        var bm := StandardMaterial3D.new()
        bm.albedo_color = [Color(0.22,0.25,0.27), Color(0.28,0.26,0.22), Color(0.12,0.18,0.18)][i % 3]
        bm.roughness = 0.95
        bmesh.material_override = bm
        block.add_child(bmesh)
        var cs := CollisionShape3D.new()
        var bs := BoxShape3D.new()
        bs.size = boxmesh.size
        cs.shape = bs
        block.add_child(cs)
        block.position = Vector3(randf_range(-32,32), boxmesh.size.y/2.0, randf_range(-32,32))
        add_child(block)

func _spawn_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0, 1.2, 12)
    player.set_script(PlayerScript)
    add_child(player)

func _spawn_enemies() -> void:
    for i in range(enemies_left):
        var enemy := CharacterBody3D.new()
        enemy.name = "Enemy_%d" % i
        enemy.position = Vector3(randf_range(-22,22), 1, randf_range(-22,-5))
        enemy.set_script(EnemyScript)
        enemy.set_meta("game_root", self)
        add_child(enemy)

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var panel := PanelContainer.new()
    panel.position = Vector2(18, 18)
    panel.add_theme_stylebox_override("panel", _panel_style())
    layer.add_child(panel)
    var column := VBoxContainer.new()
    panel.add_child(column)
    mission_label = Label.new()
    mission_label.text = "MISSION 01  /  SECURE THE OUTPOST"
    mission_label.add_theme_color_override("font_color", Color(0.35, 0.95, 0.84))
    column.add_child(mission_label)
    status_label = Label.new()
    column.add_child(status_label)
    crosshair = Label.new()
    crosshair.text = "+"
    crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    crosshair.add_theme_font_size_override("font_size", 28)
    crosshair.add_theme_color_override("font_color", Color.WHITE)
    layer.add_child(crosshair)
    var hint := Label.new()
    hint.text = "WASD MOVE  •  MOUSE AIM  •  LMB FIRE  •  R RELOAD"
    hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.position.y = -34
    hint.add_theme_color_override("font_color", Color(0.7,0.8,0.86))
    layer.add_child(hint)
    _update_hud()

func _panel_style() -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = Color(0.025,0.06,0.08,0.88)
    s.border_color = Color(0.18,0.75,0.68)
    s.set_border_width_all(1)
    s.set_content_margin_all(12)
    return s

func _update_hud() -> void:
    if is_instance_valid(status_label) and is_instance_valid(player):
        status_label.text = "HEALTH %d   |   AMMO %d / %d   |   HOSTILES %d" % [player.health, player.ammo, player.reserve_ammo, enemies_left]

func enemy_down() -> void:
    enemies_left = maxi(0, enemies_left - 1)
    _update_hud()
    if enemies_left == 0:
        mission_label.text = "MISSION COMPLETE  /  OUTPOST SECURED"
        mission_label.add_theme_color_override("font_color", Color(0.4,1,0.45))

func player_hit() -> void:
    _update_hud()
