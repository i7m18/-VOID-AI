extends Control

var tracked_player: Node3D
var objective: Node3D
var enemies: Array = []
var map_range := 58.0
var update_timer := 0.0

func _process(delta: float) -> void:
 update_timer += delta
 if update_timer >= 0.10:
  update_timer = 0.0
  queue_redraw()

func _draw() -> void:
 var size2 := size
 var center := size2 * 0.5
 var radius := minf(size2.x,size2.y) * 0.46
 draw_circle(center,radius,Color(0.015,0.035,0.037,0.86))
 draw_arc(center,radius,0.0,TAU,64,Color(0.36,0.65,0.53,0.92),2.0,true)
 draw_arc(center,radius*0.66,0.0,TAU,48,Color(0.25,0.48,0.40,0.48),1.0,true)
 draw_arc(center,radius*0.33,0.0,TAU,32,Color(0.25,0.48,0.40,0.42),1.0,true)
 draw_line(Vector2(center.x-radius,center.y),Vector2(center.x+radius,center.y),Color(0.25,0.48,0.40,0.38),1.0)
 draw_line(Vector2(center.x,center.y-radius),Vector2(center.x,center.y+radius),Color(0.25,0.48,0.40,0.38),1.0)
 if not is_instance_valid(tracked_player):
  return
 var player_pos := tracked_player.global_position
 if is_instance_valid(objective):
  var objective_delta := objective.global_position-player_pos
  var obj_point := center+Vector2(objective_delta.x,-objective_delta.z)/map_range*radius*1.75
  if obj_point.distance_to(center)>radius*0.86:
   obj_point=center+(obj_point-center).normalized()*radius*0.84
  var diamond := PackedVector2Array([
   obj_point+Vector2(0,-5),obj_point+Vector2(5,0),obj_point+Vector2(0,5),obj_point+Vector2(-5,0)
  ])
  draw_colored_polygon(diamond,Color(1.0,0.74,0.18,1.0))
 for enemy in enemies:
  if not is_instance_valid(enemy): continue
  var delta_pos: Vector3 = enemy.global_position-player_pos
  var point := center+Vector2(delta_pos.x,-delta_pos.z)/map_range*radius*1.75
  if point.distance_to(center) <= radius*0.92:
   draw_circle(point,3.0,Color(1.0,0.22,0.16,0.96))
 var heading := -tracked_player.global_rotation.y
 var forward := Vector2(sin(heading),-cos(heading))
 var side := Vector2(-forward.y,forward.x)
 var triangle := PackedVector2Array([
  center+forward*9.0,center-forward*5.5+side*5.0,center-forward*5.5-side*5.0
 ])
 draw_colored_polygon(triangle,Color(0.28,0.84,1.0,1.0))
 draw_arc(center,5.2,0.0,TAU,20,Color(0.55,0.95,1.0,0.92),1.4,true)
