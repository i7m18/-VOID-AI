extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const RadarScript = preload("res://scripts/radar.gd")
const CITY_BUILDING_NAMES := ["building-a","building-b","building-c","building-d","building-e","building-f"]
const MISSIONS := [
 {"title":"الفصل الأول: صدى الصحراء","brief":"العام 2034. أنت الرقيب آدم الراوي، قائد فريق الاستجابة المعروف باسم الصقر. قبل الفجر بثلاث عشرة دقيقة انقطع بث الحامية الحدودية «الساتر 7». وصل آخر تسجيل صوتي مشوش: ثلاث طلقات، ثم صوت ضابط يقول إنهم يعرفون اسم العملية. وصلت وحدك إلى المحيط لتكتشف أن الحراسة اختفت، والمولد ما زال يعمل، وآثار المركبات تتجه إلى قلب الصحراء لا إلى الحدود. أمّن الموقع واستعد جهاز الاتصال؛ فالذي هاجم الحامية كان يبحث عن شيء محدد، وليس عن معركة عابرة.","radio":"آدم، هنا الملازم ليلى حسن في غرفة العمليات. لا تثق بأي تردد غير مشفر. أرسلنا لك إحداثيات الساتر 7، لكن الإشارة انقطعت قبل أن نعرف من كان يراقبنا.","objective":"أمّن الحامية واستعد الاتصال","enemies":5},
 {"title":"الفصل الثاني: آخر قافلة","brief":"من جهاز الإرسال تستخرج نداء استغاثة يعود إلى قافلة طبية خرجت قبل يومين ولم تصل. تقودك الآثار إلى ممر ضيق بين التلال، حيث احترقت شاحنة الإمداد وبقيت حقيبة إسعافات مفتوحة على الأرض. الناجي الوحيد، سائق اسمه ناصر، يخبرك أن المهاجمين لم يأخذوا الوقود أو الطعام؛ أخذوا صناديق أجهزة اتصال تحمل أرقاماً عسكرية. عليك فتح طريق القافلة وإخراج السائق من الكمين. يصر ناصر على أن المهاجمين كانوا يعرفون وقت المرور بالدقيقة، ما يعني أن جدول التحرك سُرّب من الداخل.","radio":"ليلى: القافلة لم تكن مدرجة في أي بث عام. إذا كان كلام السائق صحيحاً، فهناك شخص يرسل تحركاتنا إلى مجموعة تسمي نفسها الغراب.","objective":"افتح ممر الوادي واحمِ الناجي","enemies":7},
 {"title":"الفصل الثالث: مدينة بلا فجر","brief":"يقودك السائق إلى أطراف مدينة قديمة أُخليت على عجل. خلف النوافذ المكسورة أضواء أجهزة لاسلكية، وعلى الأسطح حراس يبدلون مواقعهم كلما تحركت. فريق استطلاع صديق بقي محاصراً في مدرسة مهجورة بعد أن اكتشف شحنة أسلحة مخبأة تحت مستشفى مدني. قائد الفريق، الملازم سامر، يملك نصف سجل الشحنة فقط؛ النصف الآخر يحمل ختم قيادة لا يفترض أن يكون متورطاً. اختر السلاح المناسب: الرشاش للمواجهات القريبة، والقنص للأهداف البعيدة، وتجنب كشف موقع الفريق قبل الوصول إلى الساحة.","radio":"سامر عبر قناة ضعيفة: لسنا بحاجة إلى إنقاذ بطولي، نحتاج فقط إلى إخراج المدنيين أولاً. هناك أطفال في القبو، والعدو يعرف أننا لن نطلق النار عشوائياً.","objective":"أمّن المدرسة وأخرج فريق الاستطلاع","enemies":8},
 {"title":"الفصل الرابع: إشارة تحت الأرض","brief":"من السجل تحصل على إحداثيات محطة ترحيل قديمة خارج المدينة. تبدو المنشأة مهجورة، لكن مولدها يسحب طاقة تكفي لحي كامل، وكابلاتها تختفي في نفق تحت الأرض. أثناء تقدمك تجد أنظمة مراقبة حديثة موصولة بشبكة عسكرية قديمة. المهمة ليست تدمير المحطة؛ يجب استعادة وحدة التخزين سليمة لتحديد مصدر التسريب. كلما اقتربت من غرفة التحكم زادت مقاومة الحراسة، وكأنهم ينتظرون فريقك بالذات. إذا كان الفخ معداً سلفاً، فالوقت يعمل ضدك.","radio":"ليلى: قاعدة البيانات تقول إن المنشأة مغلقة منذ سبع سنوات. لا يوجد تصريح صيانة ولا فريق أمن مسجل. آدم، لا بد أن أحدهم صنع هوية وهمية للموقع.","objective":"اعثر على وحدة التخزين","enemies":9},
 {"title":"الفصل الخامس: المنشأة السوداء","brief":"تفتح وحدة التخزين خريطة لمنشأة تسمى «المرآة»، ومجموعة أوامر موقعة برمز قائد العمليات العقيد فارس. فارس هو الضابط الذي درّبك، وهو الرجل الذي أعلن وفاة أخيك في مهمة قبل عامين. لا تعرف إن كانت التوقيعات حقيقية أم مزيفة، لكن الخريطة تشير إلى مركز قيادة داخل مجمع صناعي محصن. عليك اختراق المحيط والوصول إلى غرفة الاتصالات قبل حذف النسخة الأصلية. هنا للمرة الأولى يدرك فريق الصقر أن ما يواجهه ليس عصابة تهريب؛ إنه تنظيم يستخدم معدات الدولة وبياناتها وسلطتها ليبقى بلا أثر.","radio":"سامر: إذا كان فارس متورطاً، فقد يكون كل تقرير أرسلناه قد وصل إليهم. لا ترسل موقعنا إلى القناة الرسمية. سأحمي الفريق وأنت خذ السجل.","objective":"اخترق محيط المرآة واستعد السجل","enemies":10},
 {"title":"الفصل السادس: الرجل الذي عاد","brief":"داخل غرفة الأرشيف تجد رسالة قصيرة موقعة باسم النقيب كريم الراوي، أخيك الذي قيل إنه مات. الرسالة مؤرخة قبل ثلاثة أيام وفيها تحذير واحد: «لا تثق بأوامر الإخلاء». يخرج من التسجيل صوت كريم متعباً لكنه حي، ويذكر أن المرآة تختبر شبكة توجيه تسمح بتغيير أوامر الوحدات الميدانية من مركز بعيد. المعلومة الأخطر أن هناك ناقلاً يخرج الليلة من المنشأة يحمل المفتاح الرئيسي. لا يمكنك إنقاذ أخيك الآن دون المخاطرة بالسجل كله. عليك اجتياز ممر الخدمة وتعطيل فريق الحراسة، بينما يصارع آدم قراراً لم يواجهه طوال خدمته: تنفيذ المهمة أم مطاردة الحقيقة الشخصية.","radio":"ليلى بصوت خافت: آدم، أعرف أنك سمعت الرسالة. إذا كان كريم حياً، فقد يكون هو من سرّب الإحداثيات أو ربما كان يحاول إيقافهم. لا تحكم قبل أن تراه.","objective":"اعبر ممر الخدمة وأوقف الناقل","enemies":11},
 {"title":"الفصل السابع: وادي الرماد","brief":"يصل الناقل إلى طريق جبلي تلتقي فيه القوافل العسكرية والمدنية. تهب عاصفة ترابية تخفض الرؤية إلى أمتار قليلة، وتظهر مركبات معادية على جانبي الطريق. تستطيع استخدام المركبة المدرعة الموجودة قرب نقطة الانطلاق للتقدم بسرعة وتخفيف أثر النار، لكن الطريق ضيق ولا يحميك من الكمائن. في منتصف الوادي تجد إشارات إلى أن الناقل ليس شخصاً بل خادم متنقل يحتوي على مفتاح الشبكة. يجب أن تصل إلى نقطة العبور قبل أن يتم تفعيل المفتاح في وحدات الحدود؛ وإلا ستتحول القوات الصديقة إلى أهداف لبعضها.","radio":"سامر: أخرجت المدنيين من المدينة. هذه فرصتنا الوحيدة، لكن لا تطارد المركبات إلى داخل العاصفة. خذ المفتاح واتجه إلى نقطة الإخلاء.","objective":"اعبر الوادي واستعد مفتاح الشبكة","enemies":12},
 {"title":"الفصل الثامن: فجر بلا أوامر","brief":"تعود إلى نقطة الإخلاء لتكتشف أن قناة القيادة أصدرت أمراً باعتقال فريق الصقر بتهمة الخيانة. قبل أن يكتمل الحصار، يظهر كريم على تردد احتياطي ويكشف الحقيقة: كان محتجزاً داخل المرآة وأُجبر على اختبار الشبكة، ثم سرّب الأدلة إلى الساتر 7. لم يمت؛ بل أُعلن موته حتى يتوقف أحد عن البحث عنه. يوضح أن المفتاح لن يتوقف إلا من غرفة القيادة الرئيسية. تجمع ليلى وسامر وناصر عبر تردد واحد، وتقررون دخول المنشأة مرة أخيرة وبث السجل كاملاً إلى المحطات المستقلة. هذه ليست مهمة عسكرية عادية بعد الآن؛ إنها محاولة لإنهاء حرب صُنعت بأوامر مزيفة، وإنقاذ وحدات لا تعرف أنها تُستخدم.","radio":"كريم: آدم، إن وصلت إليّ فلا تطلق النار قبل أن تسمعني. أعرف أنني خذلتك، لكن هذا الملف هو الدليل الوحيد. عندما يبدأ البث، لن يستطيعوا إعادته إلى الظلام.","objective":"احمِ غرفة الإرسال وأكمل البث","enemies":13},
 {"title":"الخاتمة: اسم الصقر","brief":"عند الفجر تنطلق الإشارة، وتظهر على الشاشات سجلات التحركات والأوامر المزورة وحسابات التمويل التي تربط المرآة بشبكة الغراب. تتوقف وحدات الحدود عن تبادل النار، وتبدأ فرق مستقلة بتأمين المدنيين والأسرى. يخرج آدم من المنشأة مع كريم؛ لا تنتهي الخسائر برسالة إذاعية، ولا يعود الذين فقدتموهم، لكن الكذبة لم تعد قادرة على ابتلاع الحقيقة. يطلب كريم العودة إلى المحاكمة كشاهد، بينما يعرف آدم أنه سيواجه تحقيقاً بسبب عصيان أوامر الإخلاء. يوافق على ذلك؛ لأن حماية البلد لا تعني حماية من اختطف قراره. وبينما تشرق الشمس على الوادي، يصل آخر نداء من ليلى: «الصقر، انتهت المهمة».","radio":"ليلى: كل المحطات استلمت السجل. هذه المرة لن يستطيع أحد إطفاء الإشارة. أخرجوا من هناك، والباقي سنواجهه معاً.","objective":"اصمد حتى اكتمال الإرسال","enemies":14}
]
var world_root: Node3D
var player: CharacterBody3D
var vehicle: Node3D
var objective_marker: Node3D
var objective_completed := false
var enemies_left := 0
var mission_index := 0
var game_active := false
var mission_won := false
var hud_layer: CanvasLayer
var arabic_font: Font
var radar_control: Control
var spawned_enemies: Array = []
var title_label: Label
var status_label: Label
var objective_label: Label
var story_label: Label
var message_label: Label
var reticle_label: Label
var menu_panel: PanelContainer
var move_state := Vector2.ZERO
var fire_held := false
var hitmarker_left := 0.0
var city_asset_index := 0

func _ready() -> void:
 randomize()
 if OS.has_feature("android"):
  DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
 arabic_font = load("res://fonts/NotoSansArabic.ttf") as Font
 Engine.max_fps = 60
 world_root = Node3D.new()
 world_root.name = "GeneratedWorld"
 add_child(world_root)
 _build_hud()
 _show_main_menu()

func _process(delta: float) -> void:
 for child in hud_layer.get_children():
  if child.name == "TouchControls": child.visible = game_active
 if is_instance_valid(reticle_label):
  reticle_label.visible = game_active
 if is_instance_valid(radar_control): radar_control.visible = game_active
  if hitmarker_left > 0.0:
   hitmarker_left = maxf(0.0,hitmarker_left-delta)
   if hitmarker_left == 0.0:
    reticle_label.text = "＋"
    reticle_label.add_theme_color_override("font_color",Color(0.58,1.0,0.78))
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
 if arabic_font != null: l.add_theme_font_override("font", arabic_font)
 return l

func _make_button(value: String, callback: Callable, height: int=54) -> Button:
 var b := Button.new()
 b.text = value
 b.custom_minimum_size = Vector2(190,height)
 b.add_theme_font_size_override("font_size",19)
 b.layout_direction = Control.LAYOUT_DIRECTION_RTL
 if arabic_font != null: b.add_theme_font_override("font", arabic_font)
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
 reticle_label = _label("＋",30,Color(0.58,1.0,0.78))
 reticle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 reticle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 reticle_label.anchor_left = 0.5
 reticle_label.anchor_right = 0.5
 reticle_label.anchor_top = 0.5
 reticle_label.anchor_bottom = 0.5
 reticle_label.offset_left = -22
 reticle_label.offset_right = 22
 reticle_label.offset_top = -22
 reticle_label.offset_bottom = 22
 reticle_label.visible = false
 hud_layer.add_child(reticle_label)
 radar_control = Control.new()
 radar_control.name = "TacticalRadar"
 radar_control.set_script(RadarScript)
 radar_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
 radar_control.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 radar_control.offset_left = -184
 radar_control.offset_top = 18
 radar_control.offset_right = -18
 radar_control.offset_bottom = 184
 radar_control.visible = false
 hud_layer.add_child(radar_control)

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
 game_active = false
 mission_won = false
 objective_completed = false
 move_state = Vector2.ZERO
 fire_held = false
 message_label.text = ""
 if is_instance_valid(menu_panel): menu_panel.queue_free()
 for child in world_root.get_children(): child.queue_free()
 for child in hud_layer.get_children():
  if child.name == "TouchControls": child.queue_free()
 player = null
 vehicle = null
 objective_marker = null
 _build_world()
 _spawn_player()
 _spawn_vehicle()
 _spawn_objective()
 _spawn_enemies()
 _build_touch_controls()
 _refresh_radar()
 story_label.text = ""
 _update_hud()
 _show_briefing_menu()

func _show_briefing_menu() -> void:
 if is_instance_valid(menu_panel): menu_panel.queue_free()
 menu_panel = PanelContainer.new()
 menu_panel.anchor_left = 0.5
 menu_panel.anchor_right = 0.5
 menu_panel.anchor_top = 0.5
 menu_panel.anchor_bottom = 0.5
 menu_panel.offset_left = -285
 menu_panel.offset_right = 285
 menu_panel.offset_top = -280
 menu_panel.offset_bottom = 280
 menu_panel.add_theme_stylebox_override("panel",_panel_style())
 hud_layer.add_child(menu_panel)
 var col := VBoxContainer.new()
 col.add_theme_constant_override("separation",8)
 menu_panel.add_child(col)
 var heading := _label(str(MISSIONS[mission_index]["title"]),25,Color(0.42,0.94,0.75))
 heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 col.add_child(heading)
 col.add_child(_label("ملف المهمة • اقرأ إحاطة القيادة قبل النزول للميدان",15,Color(0.78,0.84,0.80)))
 var scroll := ScrollContainer.new()
 scroll.custom_minimum_size = Vector2(500,350)
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 col.add_child(scroll)
 var briefing := _label(str(MISSIONS[mission_index]["brief"]),17)
 briefing.custom_minimum_size = Vector2(480,0)
 briefing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.add_child(briefing)
 var start := _make_button("ابدأ المهمة",Callable(self,"_begin_mission"),56)
 col.add_child(start)
 var back := _make_button("القائمة الرئيسية",Callable(self,"_show_main_menu"),44)
 col.add_child(back)

func _begin_mission() -> void:
 if is_instance_valid(menu_panel): menu_panel.queue_free()
 game_active = true
 story_label.text = "اتصال لاسلكي: " + str(MISSIONS[mission_index]["radio"])

func _build_world() -> void:
 var world_environment := WorldEnvironment.new()
 var environment := Environment.new()
 var sky_material := ProceduralSkyMaterial.new()
 var sky_tops := [Color(0.035,0.075,0.12),Color(0.18,0.25,0.34),Color(0.10,0.14,0.19),Color(0.025,0.035,0.055),Color(0.05,0.07,0.12),Color(0.24,0.25,0.25),Color(0.025,0.035,0.06),Color(0.055,0.075,0.13),Color(0.12,0.17,0.24)]
 var sky_horizons := [Color(0.66,0.47,0.30),Color(0.72,0.58,0.40),Color(0.40,0.38,0.32),Color(0.14,0.18,0.22),Color(0.23,0.28,0.33),Color(0.58,0.48,0.34),Color(0.12,0.15,0.20),Color(0.32,0.35,0.37),Color(0.82,0.58,0.34)]
 sky_material.sky_top_color = sky_tops[mission_index%sky_tops.size()]
 sky_material.sky_horizon_color = sky_horizons[mission_index%sky_horizons.size()]
 sky_material.sky_curve = 0.18
 sky_material.ground_bottom_color = Color(0.045,0.052,0.045)
 sky_material.ground_horizon_color = Color(0.35,0.28,0.20)
 sky_material.ground_curve = 0.22
 sky_material.sun_angle_max = 18.0
 sky_material.sun_curve = 0.12
 var sky := Sky.new()
 sky.sky_material = sky_material
 environment.background_mode = Environment.BG_SKY
 environment.sky = sky
 environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
 environment.ambient_light_energy = [0.72,0.82,0.56,0.34,0.48,0.86,0.31,0.46,0.92][mission_index]
 environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 environment.fog_enabled = true
 environment.fog_light_color = sky_horizons[mission_index%sky_horizons.size()].darkened(0.12)
 environment.fog_density = 0.0020 if mission_index == 6 else (0.0016 if mission_index == 2 else 0.0010)
 world_environment.environment = environment
 world_root.add_child(world_environment)
 var ground := StaticBody3D.new()
 var mesh := MeshInstance3D.new()
 var plane := PlaneMesh.new()
 plane.size = Vector2(130,130)
 mesh.mesh = plane
 # خامة رمل وحصى مولّدة داخل اللعبة بدل الأرضية ذات اللون الواحد.
 var noise_image := Image.create(96,96,false,Image.FORMAT_RGBA8)
 for py in range(96):
  for px in range(96):
   var n := randf_range(0.12,0.88)
   noise_image.set_pixel(px,py,Color(n,n,n,1.0))
 var noise_texture := ImageTexture.create_from_image(noise_image)
 var terrain_shader := Shader.new()
 terrain_shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D noise_map : repeat_enable, filter_linear_mipmap;
void fragment() {
    float broad = texture(noise_map, UV * 9.0).r;
    float grain = texture(noise_map, UV * 125.0).r;
    vec3 sand_dark = vec3(0.19, 0.17, 0.13);
    vec3 sand_light = vec3(0.43, 0.36, 0.25);
    vec3 sand = mix(sand_dark, sand_light, broad);
    sand += (grain - 0.5) * 0.055;
    ALBEDO = sand;
    ROUGHNESS = 0.98;
    METALLIC = 0.0;
}
"""
 var terrain_material := ShaderMaterial.new()
 terrain_material.shader = terrain_shader
 terrain_material.set_shader_parameter("noise_map",noise_texture)
 mesh.material_override = terrain_material
 ground.add_child(mesh)
 var coll := CollisionShape3D.new()
 var shape := BoxShape3D.new()
 shape.size = Vector3(130,0.2,130)
 coll.shape = shape
 coll.position.y = -0.1
 ground.add_child(coll)
 world_root.add_child(ground)
 # طريق عسكري متضرر يقود اللاعب إلى منطقة الاشتباك.
 _add_structure(Vector3(0,0.015,0),Vector3(6.4,0.05,116),Color(0.15,0.16,0.15))
 for z_mark in range(-52,54,9):
  _add_structure(Vector3(0,0.055,float(z_mark)),Vector3(0.12,0.018,3.0),Color(0.72,0.58,0.31))
 # مبانٍ متعددة بواجهات ونوافذ، مع إبقاء الممرات مفتوحة للقتال.
 var building_sites := [
  [Vector3(-19,0,-34),Vector3(9,7,10),Color(0.29,0.27,0.22)],
  [Vector3(20,0,-41),Vector3(11,9,9),Color(0.25,0.27,0.26)],
  [Vector3(-25,0,-8),Vector3(8,5,12),Color(0.34,0.29,0.23)],
  [Vector3(26,0,-12),Vector3(10,7,8),Color(0.28,0.29,0.27)],
  [Vector3(-27,0,23),Vector3(12,8,10),Color(0.24,0.27,0.25)],
  [Vector3(23,0,24),Vector3(10,6,12),Color(0.34,0.30,0.24)],
  [Vector3(-43,0,-27),Vector3(10,11,11),Color(0.26,0.27,0.26)],
  [Vector3(43,0,-33),Vector3(12,9,10),Color(0.27,0.29,0.28)]
 ]
 # تدوير مواقع المباني بين الفصول يجعل كل اشتباك بتوزيع ميداني مختلف.
 var rotation_amount := float(mission_index)*0.115
 var objective_xz := Vector2(_objective_position().x,_objective_position().z)
 var spawn_xz := Vector2(3,16)
 for site in building_sites:
  var base_pos: Vector3 = site[0]
  var building_size: Vector3 = site[1]
  var coordinates := Vector2(base_pos.x,base_pos.z).rotated(rotation_amount)
  if coordinates.distance_to(objective_xz) < 13.5:
   var away := coordinates-objective_xz
   if away.length() < 0.01: away = Vector2(1,0)
   coordinates = objective_xz+away.normalized()*15.0
  if coordinates.distance_to(spawn_xz) < 11.0:
   var away_spawn := coordinates-spawn_xz
   if away_spawn.length() < 0.01: away_spawn = Vector2(-1,0)
   coordinates = spawn_xz+away_spawn.normalized()*12.5
  coordinates.x = clampf(coordinates.x,-47.0,47.0)
  coordinates.y = clampf(coordinates.y,-47.0,47.0)
  _add_building(Vector3(coordinates.x,0,coordinates.y),building_size,site[2])
 # حواجز خرسانية وأكياس رمل وصناديق ذخيرة لتوفير غطاء تكتيكي.
 for i in range(10):
  var bx := -8.5 + float(i)*1.8
  _add_structure(Vector3(bx,0.48,7.5),Vector3(1.45,0.95,0.72),Color(0.32,0.30,0.24))
  if i % 2 == 0:
   _add_crate(Vector3(bx,1.1,7.2),Color(0.19,0.24,0.18))
 for i in range(28):
  var rock := MeshInstance3D.new()
  var rock_mesh := SphereMesh.new()
  rock_mesh.radial_segments = 6
  rock_mesh.rings = 3
  rock_mesh.radius = randf_range(0.18,0.75)
  rock_mesh.height = randf_range(0.18,0.52)
  rock.mesh = rock_mesh
  var rock_mat := StandardMaterial3D.new()
  rock_mat.albedo_color = [Color(0.25,0.22,0.18),Color(0.34,0.29,0.22),Color(0.19,0.21,0.19)][i%3]
  rock_mat.roughness = 1.0
  rock.material_override = rock_mat
  rock.position = Vector3(randf_range(-56,56),rock_mesh.height*0.32,randf_range(-56,56))
  rock.scale = Vector3(randf_range(0.7,1.6),1.0,randf_range(0.7,1.4))
  world_root.add_child(rock)
 _add_structure(Vector3(0,2,-48),Vector3(18,4,2),Color(0.16,0.20,0.19))
 _add_structure(Vector3(-10,2,-40),Vector3(2,4,18),Color(0.16,0.20,0.19))
 _add_structure(Vector3(10,2,-40),Vector3(2,4,18),Color(0.16,0.20,0.19))
 var sun := DirectionalLight3D.new()
 var sun_angles := [Vector3(-55,-25,0),Vector3(-39,-12,0),Vector3(-24,28,0),Vector3(-8,-18,0),Vector3(-14,45,0),Vector3(-45,-42,0),Vector3(-5,20,0),Vector3(-22,5,0),Vector3(-61,-35,0)]
 var sun_energies := [1.25,1.05,0.8,0.55,0.72,1.05,0.48,0.68,1.35]
 sun.rotation_degrees = sun_angles[mission_index]
 sun.light_energy = sun_energies[mission_index]
 sun.light_color = sky_horizons[mission_index%sky_horizons.size()].lerp(Color(1.0,0.88,0.70),0.38)
 sun.shadow_enabled = true
 sun.directional_shadow_max_distance = 85.0
 world_root.add_child(sun)
 _add_smoke_plume(Vector3(-15.0,1.5,-22.0))
 _add_smoke_plume(Vector3(18.0,1.2,-31.0))

func _add_smoke_plume(pos: Vector3) -> void:
 var particles := GPUParticles3D.new()
 particles.name = "BattlefieldSmoke"
 particles.position = pos
 particles.amount = 22
 particles.lifetime = 4.5
 particles.preprocess = 2.0
 particles.emitting = true
 particles.fixed_fps = 30
 particles.visibility_aabb = AABB(Vector3(-4,-1,-4),Vector3(8,12,8))
 var process := ParticleProcessMaterial.new()
 process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
 process.emission_sphere_radius = 0.85
 process.direction = Vector3(0,1,0)
 process.spread = 18.0
 process.initial_velocity_min = 0.6
 process.initial_velocity_max = 1.8
 process.gravity = Vector3(0,0.35,0)
 process.scale_min = 0.6
 process.scale_max = 1.45
 process.color = Color(0.23,0.24,0.23,0.42)
 particles.process_material = process
 var smoke_material := StandardMaterial3D.new()
 smoke_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 smoke_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 smoke_material.albedo_color = Color(0.22,0.23,0.22,0.34)
 smoke_material.roughness = 1.0
 smoke_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
 var smoke_mesh := SphereMesh.new()
 smoke_mesh.radius = 0.65
 smoke_mesh.height = 1.3
 smoke_mesh.radial_segments = 8
 smoke_mesh.rings = 5
 smoke_mesh.material = smoke_material
 particles.draw_pass_1 = smoke_mesh
 world_root.add_child(particles)

func _add_building(pos: Vector3, size: Vector3, color: Color) -> void:
 # Collision physique indépendante des ressources graphiques importées.
 var body := StaticBody3D.new()
 body.position = pos + Vector3(0,size.y * 0.5,0)
 var collision := CollisionShape3D.new()
 var collision_mesh := BoxShape3D.new()
 collision_mesh.size = size
 collision.shape = collision_mesh
 body.add_child(collision)
 world_root.add_child(body)

 # Les bâtiments Kenney (licence CC0) apportent des silhouettes urbaines détaillées.
 var model_name: String = CITY_BUILDING_NAMES[city_asset_index % CITY_BUILDING_NAMES.size()]
 city_asset_index += 1
 var model_path := "res://assets/buildings/%s.glb" % model_name
 var packed := load(model_path) as PackedScene
 if packed != null:
  var model := packed.instantiate() as Node3D
  if model != null:
   world_root.add_child(model)
   var bounds: Array = []
   _collect_model_bounds(model,model,bounds)
   if not bounds.is_empty():
    var model_bounds: AABB = bounds[0]
    if model_bounds.size.x > 0.01 and model_bounds.size.y > 0.01 and model_bounds.size.z > 0.01:
     model.scale = Vector3(size.x/model_bounds.size.x,size.y/model_bounds.size.y,size.z/model_bounds.size.z)
     model.position = pos - Vector3(model_bounds.position.x*model.scale.x,model_bounds.position.y*model.scale.y,model_bounds.position.z*model.scale.z)
     return
   model.queue_free()

 # إذا شُغّل المشروع دون اتصال الأصول، استخدم المبنى الإجرائي كخيار احتياطي.
 var shell := MeshInstance3D.new()
 var shell_mesh := BoxMesh.new()
 shell_mesh.size = size
 shell.mesh = shell_mesh
 var shell_mat := StandardMaterial3D.new()
 shell_mat.albedo_color = color
 shell_mat.roughness = 0.98
 shell.material_override = shell_mat
 shell.position = pos + Vector3(0,size.y*0.5,0)
 world_root.add_child(shell)
 for floor_index in range(maxi(2,int(size.y/2.2))):
  for column_index in range(maxi(2,int(size.x/2.7))):
   var window_node := MeshInstance3D.new()
   var window_mesh := BoxMesh.new()
   window_mesh.size = Vector3(0.72,0.62,0.07)
   window_node.mesh = window_mesh
   var window_mat := StandardMaterial3D.new()
   window_mat.albedo_color = Color(0.055,0.075,0.08)
   window_mat.metallic = 0.1
   window_mat.roughness = 0.42
   window_node.material_override = window_mat
   window_node.position = Vector3(pos.x-size.x*0.5+(float(column_index)+0.7)*size.x/float(maxi(2,int(size.x/2.7))),
    pos.y+1.15+float(floor_index)*size.y/float(maxi(2,int(size.y/2.2))),
    pos.z-size.z*0.5-0.04)
   world_root.add_child(window_node)

func _collect_model_bounds(root_node: Node3D, current: Node, bounds: Array) -> void:
 if current is MeshInstance3D:
  var mesh_instance := current as MeshInstance3D
  if mesh_instance.mesh != null:
   var local_bounds := mesh_instance.get_aabb()
   var relative_transform: Transform3D = root_node.global_transform.affine_inverse() * mesh_instance.global_transform
   for x in [local_bounds.position.x,local_bounds.end.x]:
    for y in [local_bounds.position.y,local_bounds.end.y]:
     for z in [local_bounds.position.z,local_bounds.end.z]:
      var point: Vector3 = relative_transform * Vector3(x,y,z)
      if bounds.is_empty():
       bounds.append(AABB(point,Vector3.ZERO))
      else:
       var old_bounds: AABB = bounds[0]
       bounds[0] = old_bounds.expand(point)
 for child in current.get_children():
  _collect_model_bounds(root_node,child,bounds)

func _add_crate(pos: Vector3, color: Color) -> void:
 var crate := MeshInstance3D.new()
 var crate_mesh := BoxMesh.new()
 crate_mesh.size = Vector3(0.72,0.68,0.72)
 crate.mesh = crate_mesh
 var mat := StandardMaterial3D.new()
 mat.albedo_color = color
 mat.roughness = 0.9
 crate.material_override = mat
 crate.position = pos
 world_root.add_child(crate)
 for x_side in [-0.27,0.27]:
  var brace := MeshInstance3D.new()
  var brace_mesh := BoxMesh.new()
  brace_mesh.size = Vector3(0.05,0.7,0.76)
  brace.mesh = brace_mesh
  brace.material_override = mat
  brace.position = pos + Vector3(x_side,0,0)
  world_root.add_child(brace)

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
 player.position = Vector3(3,1.1,16)
 player.set_script(PlayerScript)
 world_root.add_child(player)

func _spawn_vehicle() -> void:
 vehicle = Node3D.new()
 vehicle.name = "ArmoredVehicle"
 vehicle.position = Vector3(4,0.72,13)
 # هيكل مدرعة تكتيكية مع واقيات جانبية وزجاج أمامي وعجلات ظاهرة.
 var body := MeshInstance3D.new()
 var box := BoxMesh.new()
 box.size = Vector3(2.25,0.92,3.65)
 body.mesh = box
 var mat := StandardMaterial3D.new()
 mat.albedo_color = Color(0.14,0.20,0.15)
 mat.metallic = 0.28
 mat.roughness = 0.82
 body.material_override = mat
 body.position.y = 0.15
 vehicle.add_child(body)
 var cabin := MeshInstance3D.new()
 var cab := BoxMesh.new()
 cab.size = Vector3(1.72,0.78,1.56)
 cabin.mesh = cab
 cabin.position = Vector3(0,0.91,-0.18)
 var glass_mat := StandardMaterial3D.new()
 glass_mat.albedo_color = Color(0.07,0.12,0.14)
 glass_mat.metallic = 0.42
 glass_mat.roughness = 0.24
 cabin.material_override = glass_mat
 vehicle.add_child(cabin)
 var bumper := MeshInstance3D.new()
 var bumper_mesh := BoxMesh.new()
 bumper_mesh.size = Vector3(2.48,0.22,0.23)
 bumper.mesh = bumper_mesh
 bumper.position = Vector3(0,-0.10,-1.92)
 var steel := StandardMaterial3D.new()
 steel.albedo_color = Color(0.10,0.12,0.11)
 steel.metallic = 0.72
 steel.roughness = 0.48
 bumper.material_override = steel
 vehicle.add_child(bumper)
 var grille := MeshInstance3D.new()
 var grille_mesh := BoxMesh.new()
 grille_mesh.size = Vector3(0.56,0.38,0.035)
 grille.mesh = grille_mesh
 grille.position = Vector3(0,0.15,-1.86)
 grille.material_override = steel
 vehicle.add_child(grille)
 for side in [-1.0,1.0]:
  var wheel := MeshInstance3D.new()
  var wheel_mesh := CylinderMesh.new()
  wheel_mesh.top_radius = 0.42
  wheel_mesh.bottom_radius = 0.42
  wheel_mesh.height = 0.34
  wheel_mesh.radial_segments = 12
  wheel.mesh = wheel_mesh
  wheel.position = Vector3(side*1.12,-0.20,-1.15)
  wheel.rotation.z = deg_to_rad(90)
  var tire_mat := StandardMaterial3D.new()
  tire_mat.albedo_color = Color(0.035,0.04,0.035)
  tire_mat.roughness = 0.99
  wheel.material_override = tire_mat
  vehicle.add_child(wheel)
  var rear_wheel := wheel.duplicate() as MeshInstance3D
  rear_wheel.position.z = 1.15
  vehicle.add_child(rear_wheel)
  var headlight := MeshInstance3D.new()
  var headlight_mesh := BoxMesh.new()
  headlight_mesh.size = Vector3(0.30,0.16,0.055)
  headlight.mesh = headlight_mesh
  headlight.position = Vector3(side*0.78,0.26,-1.86)
  var headlight_mat := StandardMaterial3D.new()
  headlight_mat.albedo_color = Color(0.83,0.72,0.46)
  headlight_mat.emission_enabled = true
  headlight_mat.emission = Color(0.54,0.36,0.12)
  headlight_mat.emission_energy_multiplier = 0.7
  headlight.material_override = headlight_mat
  vehicle.add_child(headlight)
 var roof_mount := MeshInstance3D.new()
 var mount_mesh := BoxMesh.new()
 mount_mesh.size = Vector3(0.65,0.13,0.72)
 roof_mount.mesh = mount_mesh
 roof_mount.position = Vector3(0,1.34,-0.1)
 roof_mount.material_override = steel
 vehicle.add_child(roof_mount)
 var antenna := MeshInstance3D.new()
 var antenna_mesh := CylinderMesh.new()
 antenna_mesh.top_radius = 0.018
 antenna_mesh.bottom_radius = 0.018
 antenna_mesh.height = 1.1
 antenna.mesh = antenna_mesh
 antenna.position = Vector3(0.64,1.65,0.35)
 antenna.material_override = steel
 vehicle.add_child(antenna)
 world_root.add_child(vehicle)

func _objective_position() -> Vector3:
 match mission_index:
  0: return Vector3(0,0,-24)
  1: return Vector3(20,0,-24)
  2: return Vector3(-23,0,-18)
  3: return Vector3(0,0,-13)
  4: return Vector3(18,0,-35)
  5: return Vector3(-19,0,-12)
  6: return Vector3(22,0,-28)
  7: return Vector3(0,0,-35)
  _: return Vector3(-20,0,-32)

func _spawn_objective() -> void:
 objective_marker = Node3D.new()
 objective_marker.name = "MissionObjective"
 objective_marker.position = _objective_position()
 var base := MeshInstance3D.new()
 var base_mesh := CylinderMesh.new()
 base_mesh.top_radius = 0.72
 base_mesh.bottom_radius = 0.82
 base_mesh.height = 0.10
 base.mesh = base_mesh
 var base_mat := StandardMaterial3D.new()
 base_mat.albedo_color = Color(0.12,0.14,0.12)
 base_mat.metallic = 0.48
 base_mat.roughness = 0.78
 base.material_override = base_mat
 base.position.y = 0.05
 objective_marker.add_child(base)

 # لكل فصل عنصر ميداني مختلف بدلاً من العمود الأخضر نفسه في كل مرة.
 match mission_index:
  0:
   _add_objective_box(objective_marker,Vector3(0.86,0.94,0.56),Vector3(0,0.54,0),Color(0.17,0.21,0.17),0.36)
   _add_objective_box(objective_marker,Vector3(0.48,0.27,0.035),Vector3(0,0.66,-0.30),Color(0.07,0.24,0.22),0.20,Color(0.08,0.70,0.42))
   _add_objective_cylinder(objective_marker,0.025,0.9,Vector3(0.29,1.42,0.10),Color(0.10,0.12,0.10))
  1:
   _add_objective_box(objective_marker,Vector3(1.25,0.72,0.88),Vector3(0,0.40,0),Color(0.22,0.27,0.18),0.12)
   _add_objective_box(objective_marker,Vector3(1.31,0.08,0.10),Vector3(0,0.41,-0.02),Color(0.08,0.10,0.09),0.52)
   _add_objective_box(objective_marker,Vector3(0.10,0.76,0.92),Vector3(-0.43,0.40,0),Color(0.08,0.10,0.09),0.55)
   _add_objective_box(objective_marker,Vector3(0.10,0.76,0.92),Vector3(0.43,0.40,0),Color(0.08,0.10,0.09),0.55)
  2:
   _add_objective_box(objective_marker,Vector3(0.96,0.66,0.52),Vector3(0,0.39,0),Color(0.18,0.23,0.20),0.32)
   _add_objective_box(objective_marker,Vector3(0.60,0.26,0.045),Vector3(0,0.50,-0.29),Color(0.08,0.28,0.24),0.15,Color(0.08,0.65,0.38))
   _add_objective_cylinder(objective_marker,0.035,0.55,Vector3(0.34,1.0,0.10),Color(0.12,0.14,0.12))
  3:
   for side in [-1.0,1.0]:
    _add_objective_box(objective_marker,Vector3(0.52,1.35,0.54),Vector3(side*0.36,0.72,0),Color(0.11,0.14,0.15),0.58)
    _add_objective_box(objective_marker,Vector3(0.36,0.40,0.035),Vector3(side*0.36,0.85,-0.29),Color(0.06,0.19,0.24),0.24,Color(0.05,0.38,0.72))
  4:
   _add_objective_box(objective_marker,Vector3(1.0,0.36,0.72),Vector3(0,0.25,0),Color(0.13,0.16,0.14),0.62)
   _add_objective_box(objective_marker,Vector3(0.48,0.07,0.28),Vector3(0,0.47,0),Color(0.62,0.43,0.16),0.42)
   _add_objective_box(objective_marker,Vector3(0.34,0.11,0.08),Vector3(0,0.57,-0.06),Color(0.10,0.26,0.20),0.15,Color(0.03,0.46,0.22))
  5:
   _add_objective_box(objective_marker,Vector3(0.84,0.78,0.60),Vector3(0,0.44,0),Color(0.15,0.18,0.15),0.46)
   _add_objective_cylinder(objective_marker,0.045,1.55,Vector3(0.28,1.30,0.12),Color(0.11,0.13,0.12))
   _add_objective_box(objective_marker,Vector3(0.28,0.08,0.24),Vector3(0.28,1.70,0.12),Color(0.23,0.27,0.21),0.55)
  6:
   _add_objective_box(objective_marker,Vector3(1.20,0.64,0.70),Vector3(0,0.37,0),Color(0.18,0.20,0.17),0.5)
   _add_objective_box(objective_marker,Vector3(0.62,0.28,0.04),Vector3(0,0.51,-0.37),Color(0.23,0.08,0.06),0.22,Color(0.75,0.08,0.025))
   _add_objective_cylinder(objective_marker,0.026,0.72,Vector3(-0.43,1.03,0.20),Color(0.08,0.10,0.09))
  7:
   _add_objective_box(objective_marker,Vector3(0.90,0.88,0.65),Vector3(0,0.50,0),Color(0.12,0.16,0.14),0.5)
   for side in [-1.0,1.0]:
    _add_objective_cylinder(objective_marker,0.025,1.35,Vector3(side*0.29,1.25,0.17),Color(0.07,0.10,0.09))
   _add_objective_box(objective_marker,Vector3(0.48,0.23,0.04),Vector3(0,0.65,-0.34),Color(0.06,0.21,0.19),0.18,Color(0.05,0.55,0.35))
  _:
   _add_objective_box(objective_marker,Vector3(1.22,0.86,0.62),Vector3(0,0.50,0),Color(0.13,0.17,0.15),0.52)
   _add_objective_box(objective_marker,Vector3(0.42,0.30,0.04),Vector3(-0.20,0.68,-0.33),Color(0.06,0.23,0.23),0.2,Color(0.03,0.72,0.44))
   _add_objective_box(objective_marker,Vector3(0.42,0.30,0.04),Vector3(0.27,0.68,-0.33),Color(0.06,0.16,0.22),0.2,Color(0.03,0.32,0.75))
   _add_objective_cylinder(objective_marker,0.025,1.20,Vector3(0.40,1.55,0.15),Color(0.08,0.10,0.09))

 var lamp := MeshInstance3D.new()
 var lamp_mesh := SphereMesh.new()
 lamp_mesh.radius = 0.075
 lamp_mesh.height = 0.15
 lamp.mesh = lamp_mesh
 lamp.position = Vector3(0,1.36,-0.35)
 var lamp_mat := StandardMaterial3D.new()
 lamp_mat.albedo_color = Color(1.0,0.67,0.18)
 lamp_mat.emission_enabled = true
 lamp_mat.emission = Color(0.95,0.40,0.05)
 lamp_mat.emission_energy_multiplier = 1.4
 lamp.material_override = lamp_mat
 objective_marker.add_child(lamp)
 var light := OmniLight3D.new()
 light.position = Vector3(0,1.42,-0.35)
 light.light_color = Color(1.0,0.56,0.15)
 light.light_energy = 0.65
 light.omni_range = 3.5
 objective_marker.add_child(light)

 var text_mesh := TextMesh.new()
 text_mesh.text = "الهدف"
 if arabic_font != null: text_mesh.font = arabic_font
 text_mesh.font_size = 40
 text_mesh.depth = 0.005
 var text_node := MeshInstance3D.new()
 text_node.mesh = text_mesh
 var text_material := StandardMaterial3D.new()
 text_material.albedo_color = Color(1.0,0.78,0.30)
 text_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 text_node.material_override = text_material
 text_node.position = Vector3(-0.36,1.95,0)
 objective_marker.add_child(text_node)
 world_root.add_child(objective_marker)

func _add_objective_box(parent: Node3D, dimensions: Vector3, local_position: Vector3, color: Color, metallic: float=0.1, glow: Color=Color(0,0,0)) -> void:
 var node := MeshInstance3D.new()
 var cube := BoxMesh.new()
 cube.size = dimensions
 node.mesh = cube
 node.position = local_position
 var mat := StandardMaterial3D.new()
 mat.albedo_color = color
 mat.metallic = metallic
 mat.roughness = 0.68
 if glow != Color(0,0,0):
  mat.emission_enabled = true
  mat.emission = glow
  mat.emission_energy_multiplier = 1.2
 node.material_override = mat
 parent.add_child(node)

func _add_objective_cylinder(parent: Node3D, radius: float, height: float, local_position: Vector3, color: Color) -> void:
 var node := MeshInstance3D.new()
 var shape := CylinderMesh.new()
 shape.top_radius = radius
 shape.bottom_radius = radius
 shape.height = height
 shape.radial_segments = 8
 node.mesh = shape
 node.position = local_position
 var mat := StandardMaterial3D.new()
 mat.albedo_color = color
 mat.metallic = 0.48
 mat.roughness = 0.6
 node.material_override = mat
 parent.add_child(node)

func _spawn_enemies() -> void:
 enemies_left = int(MISSIONS[mission_index]["enemies"])
 spawned_enemies.clear()
 for i in range(enemies_left):
  var enemy := CharacterBody3D.new()
  enemy.name = "Enemy_%02d" % i
  var angle := TAU*float(i)/float(enemies_left)
  enemy.position = Vector3(cos(angle)*randf_range(17,31),1.0,-18+sin(angle)*randf_range(13,25))
  enemy.set_script(EnemyScript)
  world_root.add_child(enemy)
  spawned_enemies.append(enemy)

func _refresh_radar() -> void:
 if not is_instance_valid(radar_control): return
 radar_control.set("tracked_player",player)
 radar_control.set("objective",objective_marker)
 radar_control.set("enemies",spawned_enemies)
 radar_control.queue_redraw()

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
 var interact := _make_button("تفاعل",Callable(self,"interact_objective"),45)
 interact.position = Vector2(w-335,h-105)
 interact.custom_minimum_size = Vector2(150,45)
 controls.add_child(interact)
 var aim := _make_button("تصويب",Callable(self,"_dummy"),44)
 aim.position = Vector2(w-160,h-218)
 aim.custom_minimum_size = Vector2(140,44)
 controls.add_child(aim)
 aim.button_down.connect(func(): if is_instance_valid(player): player.set_aiming(true))
 aim.button_up.connect(func(): if is_instance_valid(player): player.set_aiming(false))
 var grenade := _make_button("قنبلة",Callable(self,"_dummy"),44)
 grenade.position = Vector2(w-500,h-105)
 grenade.custom_minimum_size = Vector2(140,44)
 controls.add_child(grenade)
 grenade.pressed.connect(func(): if is_instance_valid(player): player.throw_grenade())
 var sprint := _make_button("ركض",Callable(self,"_dummy"),44)
 sprint.position = Vector2(w-500,h-155)
 sprint.custom_minimum_size = Vector2(140,44)
 controls.add_child(sprint)
 sprint.button_down.connect(func(): if is_instance_valid(player): player.set_sprinting(true))
 sprint.button_up.connect(func(): if is_instance_valid(player): player.set_sprinting(false))
 var crouch := _make_button("انحناء",Callable(self,"_dummy"),44)
 crouch.position = Vector2(w-500,h-205)
 crouch.custom_minimum_size = Vector2(140,44)
 controls.add_child(crouch)
 crouch.pressed.connect(func(): if is_instance_valid(player): player.toggle_crouch())
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
 if enemies_left == 0 and not objective_completed:
  message_label.text = "المنطقة آمنة — توجّه إلى العلامة المضيئة واضغط «تفاعل»"
  objective_label.text = "الهدف: اقترب من العلامة المضيئة وفعّلها"

func interact_objective() -> void:
 if not game_active or objective_completed or not is_instance_valid(player) or not is_instance_valid(objective_marker):
  return
 if enemies_left > 0:
  message_label.text = "أمّن المنطقة أولاً — الأعداء المتبقون: %d" % enemies_left
  return
 if player.global_position.distance_to(objective_marker.global_position) > 4.5:
  message_label.text = "اقترب من العلامة الخضراء لتفعيل الهدف"
  return
 objective_completed = true
 mission_won = true
 game_active = false
 objective_marker.visible = false
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

func show_message(value: String) -> void:
 if is_instance_valid(message_label):
  message_label.text = value

func throw_grenade(origin: Vector3, direction: Vector3, owner_player: Node3D) -> void:
 if not game_active: return
 var grenade := RigidBody3D.new()
 grenade.name = "Grenade"
 grenade.mass = 0.72
 grenade.gravity_scale = 1.0
 grenade.linear_damp = 0.22
 grenade.angular_damp = 0.8
 var shell := MeshInstance3D.new()
 var shell_mesh := SphereMesh.new()
 shell_mesh.radius = 0.13
 shell_mesh.height = 0.26
 shell_mesh.radial_segments = 10
 shell_mesh.rings = 6
 shell.mesh = shell_mesh
 var shell_material := StandardMaterial3D.new()
 shell_material.albedo_color = Color(0.12,0.19,0.12)
 shell_material.metallic = 0.35
 shell_material.roughness = 0.72
 shell.material_override = shell_material
 grenade.add_child(shell)
 var collision := CollisionShape3D.new()
 var sphere := SphereShape3D.new()
 sphere.radius = 0.13
 collision.shape = sphere
 grenade.add_child(collision)
 world_root.add_child(grenade)
 grenade.global_position = origin + direction.normalized()*0.55
 grenade.linear_velocity = direction.normalized()*12.5 + Vector3.UP*4.1
 grenade.angular_velocity = Vector3(5.0,2.0,3.0)
 var fuse := Timer.new()
 fuse.one_shot = true
 fuse.wait_time = 2.1
 grenade.add_child(fuse)
 fuse.timeout.connect(_detonate_grenade.bind(grenade,owner_player))
 fuse.start()
 show_message("قنبلة يدوية! ابتعد عن منطقة الانفجار")

func _detonate_grenade(grenade: RigidBody3D, owner_player: Node3D) -> void:
 if not is_instance_valid(grenade): return
 var center := grenade.global_position
 var blast := MeshInstance3D.new()
 var blast_mesh := SphereMesh.new()
 blast_mesh.radius = 0.5
 blast_mesh.height = 1.0
 blast_mesh.radial_segments = 12
 blast_mesh.rings = 8
 blast.mesh = blast_mesh
 var blast_material := StandardMaterial3D.new()
 blast_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 blast_material.albedo_color = Color(1.0,0.38,0.09,0.9)
 blast_material.emission_enabled = true
 blast_material.emission = Color(1.0,0.18,0.025)
 blast_material.emission_energy_multiplier = 3.2
 blast_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 blast.material_override = blast_material
 blast.position = center
 world_root.add_child(blast)
 var light := OmniLight3D.new()
 light.position = center
 light.light_color = Color(1.0,0.36,0.10)
 light.light_energy = 4.5
 light.omni_range = 10.0
 world_root.add_child(light)
 var tween := create_tween()
 tween.tween_property(blast,"scale",Vector3.ONE*8.0,0.22)
 tween.parallel().tween_property(blast_material,"albedo_color",Color(1.0,0.10,0.02,0.0),0.22)
 tween.parallel().tween_property(light,"light_energy",0.0,0.25)
 tween.tween_callback(Callable(blast,"queue_free"))
 tween.tween_callback(Callable(light,"queue_free"))
 grenade.queue_free()

 var explosion_shape := SphereShape3D.new()
 explosion_shape.radius = 5.2
 var query := PhysicsShapeQueryParameters3D.new()
 query.shape = explosion_shape
 query.transform = Transform3D(Basis.IDENTITY,center)
 query.collide_with_bodies = true
 query.collide_with_areas = true
 if is_instance_valid(owner_player):
  query.exclude = [owner_player.get_rid()]
 var hits := get_world_3d().direct_space_state.intersect_shape(query,64)
 var damaged: Dictionary = {}
 for hit in hits:
  var target: Object = hit.get("collider")
  if not is_instance_valid(target) or not target.has_method("take_damage"): continue
  var object_id := target.get_instance_id()
  if damaged.has(object_id): continue
  damaged[object_id] = true
  if target is Node3D:
   var distance: float = (target as Node3D).global_position.distance_to(center)
   var damage := 115 if distance < 1.7 else (78 if distance < 3.2 else 38)
   target.take_damage(damage)
 message_label.text = "انفجار! أُطلقت القنبلة على المنطقة"

func show_hitmarker() -> void:
 if not is_instance_valid(reticle_label): return
 reticle_label.text = "×"
 reticle_label.add_theme_color_override("font_color",Color(1.0,0.36,0.20))
 hitmarker_left = 0.13

func _update_hud() -> void:
 if not is_instance_valid(player): return
 var mission: Dictionary = MISSIONS[mission_index]
 title_label.text = mission["title"]
 if objective_completed:
  objective_label.text = "الهدف مكتمل"
 elif enemies_left > 0:
  objective_label.text = "الهدف: "+str(mission["objective"])+" • أمّن المنطقة"
 else:
  objective_label.text = "الهدف: اقترب من العلامة واضغط «تفاعل»"
 status_label.text = "الصحة %d  |  الذخيرة %d/%d  |  القنابل %d  |  الأعداء %d  |  %s" % [player.health,player.get_current_ammo(),player.get_current_reserve_ammo(),player.grenades,enemies_left,player.get_weapon_name()]
