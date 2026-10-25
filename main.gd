extends Node3D
var car: VehicleBody3D
var hud: Label
var tornado: Node3D
var installed := 0
var parts := ["ENGINE","GEARBOX","WHEELS","ARMOR","RADAR","STORM DISRUPTOR"]
var phase := 0
var damage := 0.0
var charge := 0.0
var anchors := false
var camera: Camera3D
func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, solid := false) -> MeshInstance3D:
 var m := MeshInstance3D.new()
 var mesh := BoxMesh.new()
 mesh.size = size
 m.mesh = mesh
 var mat := StandardMaterial3D.new()
 mat.albedo_color = color
 m.material_override = mat
 m.position = pos
 parent.add_child(m)
 if solid:
  var body := StaticBody3D.new()
  var shape := CollisionShape3D.new()
  var s := BoxShape3D.new()
  s.size = size
  shape.shape = s
  body.position = pos
  parent.add_child(body)
  body.add_child(shape)
 return m
func _ready() -> void:
 var env := WorldEnvironment.new()
 var e := Environment.new()
 e.background_mode = Environment.BG_COLOR
 e.background_color = Color(0.17,0.22,0.29)
 e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 e.ambient_light_color = Color(0.55,0.58,0.66)
 env.environment = e
 add_child(env)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-55,-35,0)
 sun.light_energy = 0.9
 add_child(sun)
 box(self,Vector3(0,-0.6,0),Vector3(460,1,460),Color(0.16,0.28,0.18),true)
 box(self,Vector3(0,-0.06,0),Vector3(13,0.12,460),Color(0.11,0.12,0.14))
 box(self,Vector3(0,-0.04,0),Vector3(460,0.1,11),Color(0.11,0.12,0.14))
 for i in range(28):
  var z := float(i*15-205)
  var h := float(5 + i%5*3)
  box(self,Vector3(18,h/2,z),Vector3(9,h,10),Color(0.35,0.34+float(i%3)*0.07,0.36))
  box(self,Vector3(-18,h/2,z),Vector3(9,h,10),Color(0.36,0.33,0.29))
 tornado = Node3D.new()
 tornado.position = Vector3(0,0,-155)
 add_child(tornado)
 for i in range(22):
  var layer := MeshInstance3D.new()
  var mesh := CylinderMesh.new()
  mesh.top_radius = 2.0+float(i)*0.78
  mesh.bottom_radius = 1.6+float(i)*0.68
  mesh.height = 2.7
  layer.mesh = mesh
  layer.position.y = 1.4+float(i)*2.5
  var mat := StandardMaterial3D.new()
  mat.albedo_color = Color(0.16,0.17,0.2,0.66)
  mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
  layer.material_override = mat
  tornado.add_child(layer)
 car = VehicleBody3D.new()
 car.mass = 1450
 car.position = Vector3(0,1.5,13)
 add_child(car)
 var collision := CollisionShape3D.new()
 var shape := BoxShape3D.new()
 shape.size = Vector3(2.3,1.0,4.3)
 collision.shape = shape
 car.add_child(collision)
 box(car,Vector3(0,0,0),Vector3(2.3,0.85,4.3),Color(0.17,0.26,0.31))
 box(car,Vector3(0,0.75,0.3),Vector3(2.0,0.75,2.1),Color(0.08,0.13,0.18))
 for x in [-1.15,1.15]:
  for z in [-1.35,1.35]:
   var w := VehicleWheel3D.new()
   w.position = Vector3(x,-0.38,z)
   w.use_as_steering = z < 0
   w.use_as_traction = z > 0
   w.wheel_radius = 0.5
   w.wheel_rest_length = 0.25
   w.suspension_stiffness = 32
   w.wheel_friction_slip = 2
   car.add_child(w)
 camera = Camera3D.new()
 camera.current = true
 add_child(camera)
 var ui := CanvasLayer.new()
 add_child(ui)
 hud = Label.new()
 hud.position = Vector2(18,14)
 hud.add_theme_font_size_override("font_size",22)
 ui.add_child(hud)
 update_hud()
func _physics_process(delta: float) -> void:
 if phase == 0:
  camera.global_position = Vector3(9,7,21)
  camera.look_at(car.global_position)
  if Input.is_action_just_pressed("ui_accept"):
   installed += 1
   if installed >= parts.size():
    phase = 1
  update_hud()
  return
 var forward := Input.get_action_strength("ui_up")-Input.get_action_strength("ui_down")
 var steer := Input.get_action_strength("ui_left")-Input.get_action_strength("ui_right")
 car.engine_force = 0.0 if damage >= 100 else forward*280.0
 car.steering = steer*0.45
 car.brake = 30.0 if Input.is_key_pressed(KEY_SPACE) else 0.0
 var speed := car.linear_velocity.length()*3.6
 var distance := car.global_position.distance_to(tornado.global_position)
 if distance < 90.0:
  var pull := tornado.global_position-car.global_position
  car.apply_central_force(pull.normalized()*(90.0-distance)*30.0)
  damage = min(100.0,damage+delta*(90-distance)*0.15)
 if Input.is_key_pressed(KEY_E) and speed < 12.0:
  anchors = true
 if anchors and distance < 85.0 and Input.is_key_pressed(KEY_F):
  charge = min(100.0,charge+delta*12)
 if charge >= 100:
  phase = 2
 var behind := car.global_transform.basis.z.normalized()
 camera.global_position = camera.global_position.lerp(car.global_position+behind*9+Vector3.UP*5, min(1.0,delta*5))
 camera.look_at(car.global_position+Vector3.UP*1.4)
 tornado.rotate_y(delta*1.4)
 if phase == 2:
  car.engine_force=0
 update_hud()
func update_hud() -> void:
 if phase == 0:
  hud.text = "AGARTALA - EYE OF THE STORM\nGARAGE: MANUAL BUILD\nPress ENTER to install: "+parts[min(installed,parts.size()-1)]+"\nInstalled "+str(installed)+"/"+str(parts.size())
 elif phase == 2:
  hud.text = "STORM DISRUPTED! MISSION COMPLETE"
 else:
  var dist := int(car.global_position.distance_to(tornado.global_position))
  hud.text = "SPEED: "+str(int(car.linear_velocity.length()*3.6))+" km/h   DAMAGE: "+str(int(damage))+"%\nTORNADO RADAR: "+str(dist)+" m | Direction: "+str(int(rad_to_deg(atan2(tornado.global_position.x-car.global_position.x,car.global_position.z-tornado.global_position.z))))+" deg\nWASD / ARROWS DRIVE | SPACE BRAKE | E ANCHORS | HOLD F DISRUPT\nSTORM DISRUPTOR: "+str(int(charge))+"%"
  if damage >= 65:
   hud.text += "\n⚠ CRITICAL HAZARD: GEARBOX DAMAGED"
  if damage >= 100:
   hud.text += "\n⚠ GEARBOX BROKEN - VEHICLE DISABLED"
