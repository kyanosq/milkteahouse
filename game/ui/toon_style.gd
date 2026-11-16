class_name ShopToon
extends RefCounted

## Native toon diffuse keeps soft color bands and removes the plastic specular lobe.
static func material(source: BaseMaterial3D) -> BaseMaterial3D:
	var result: BaseMaterial3D = source.duplicate()
	result.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	result.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	result.metallic = 0.0
	result.roughness = 0.70
	result.clearcoat_enabled = false
	result.rim_enabled = false
	result.normal_enabled = false
	result.ao_enabled = false
	result.detail_enabled = false
	return result


static func apply(root: Node) -> void:
	for mesh in root.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			mesh.set_surface_override_material(surface, material(mesh.get_active_material(surface)))
