extends TextureRect

func _ready():
	var shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://background_shader.gdshader")
	shader_material.set_shader_parameter("brightness", 0.7)
	shader_material.set_shader_parameter("saturation", 0.6)
	material = shader_material
