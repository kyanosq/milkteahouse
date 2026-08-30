import bpy
import math
import os
from mathutils import Vector


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
BLEND_PATH = os.path.join(ROOT, "assets_src/blend/upgrade_kit.blend")
SOURCE_DIR = os.path.join(ROOT, "assets_src/glb/props/upgrades")
RUNTIME_DIR = os.path.join(ROOT, "game/assets/glb/props/upgrades")
PREVIEW_PATH = os.path.join(ROOT, "assets_src/renders/upgrade_kit_preview.png")


PALETTE = {
    "Cream": (1.00, 0.965, 0.89, 1.0),
    "CreamDark": (0.80, 0.70, 0.56, 1.0),
    "Coral": (1.00, 0.125, 0.10, 1.0),
    "CoralSoft": (1.00, 0.44, 0.39, 1.0),
    "CoralDark": (0.47, 0.08, 0.06, 1.0),
    "Mint": (0.055, 0.61, 0.49, 1.0),
    "MintSoft": (0.43, 0.86, 0.77, 1.0),
    "MintDark": (0.02, 0.24, 0.18, 1.0),
    "Cocoa": (0.28, 0.10, 0.035, 1.0),
    "Wood": (0.48, 0.20, 0.07, 1.0),
    "Gold": (0.95, 0.54, 0.08, 1.0),
    "Leaf": (0.08, 0.42, 0.25, 1.0),
    "Glass": (0.80, 0.94, 0.91, 0.42),
    "Screen": (0.025, 0.17, 0.14, 1.0),
}


def reset():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    # Re-running through MCP must replace old asset collections instead of creating
    # suffixed duplicates; otherwise preview placement targets empty collections.
    for col in list(bpy.data.collections):
        bpy.data.collections.remove(col)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials,
                       bpy.data.cameras, bpy.data.lights):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def mat(name, color, metallic=0.0, roughness=0.48, emission=None):
    material = bpy.data.materials.new(name)
    material.diffuse_color = color
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if color[3] < 1.0:
        bsdf.inputs["Alpha"].default_value = color[3]
        material.surface_render_method = "DITHERED"
    if emission:
        bsdf.inputs["Emission Color"].default_value = emission
        bsdf.inputs["Emission Strength"].default_value = 2.2
    return material


def make_materials():
    for name, color in PALETTE.items():
        metallic = 0.72 if name == "Gold" else 0.06 if name in ("MintDark", "CoralDark") else 0.0
        roughness = 0.22 if name == "Gold" else 0.30 if name in ("Glass", "Screen") else 0.52
        emission = (0.12, 0.75, 0.55, 1.0) if name == "Screen" else None
        mat(name, color, metallic, roughness, emission)


def collection(name):
    col = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(col)
    return col


def move_to(obj, col):
    for owner in list(obj.users_collection):
        owner.objects.unlink(obj)
    col.objects.link(obj)
    return obj


def finish(obj, name, material, col, bevel=0.0, smooth=True):
    obj.name = name
    if material:
        obj.data.materials.append(bpy.data.materials[material])
    if smooth and hasattr(obj.data, "polygons"):
        for poly in obj.data.polygons:
            poly.use_smooth = True
    if bevel > 0:
        modifier = obj.modifiers.new("SoftBevel", "BEVEL")
        modifier.width = bevel
        modifier.segments = 1
        modifier.limit_method = "ANGLE"
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    return move_to(obj, col)


def cube(name, loc, dims, material, col, bevel=0.01, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(location=loc, rotation=rot)
    obj = bpy.context.object
    obj.dimensions = dims
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, material, col, min(bevel, min(dims) * 0.22))


def cylinder(name, loc, radius, depth, material, col, vertices=32, bevel=0.005, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=min(vertices, 16), radius=radius, depth=depth,
                                       location=loc, rotation=rot)
    return finish(bpy.context.object, name, material, col, bevel)


def sphere(name, loc, scale, material, col, segments=32, rings=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=min(segments, 12), ring_count=min(rings, 6), location=loc)
    obj = bpy.context.object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, material, col)


def torus(name, loc, major, minor, material, col, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor,
                                    major_segments=16, minor_segments=6,
                                    location=loc, rotation=rot)
    return finish(bpy.context.object, name, material, col)


def tube(name, points, radius, material, col, cyclic=False):
    curve = bpy.data.curves.new(name + "Curve", "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 1
    curve.bevel_depth = radius
    curve.bevel_resolution = 1
    spline = curve.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for point, co in zip(spline.bezier_points, points):
        point.co = co
        point.handle_left_type = "AUTO"
        point.handle_right_type = "AUTO"
    spline.use_cyclic_u = cyclic
    obj = bpy.data.objects.new(name, curve)
    col.objects.link(obj)
    curve.materials.append(bpy.data.materials[material])
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    return obj


def build_auto_shaker():
    col = collection("UpgradeAutoShaker")
    cube("Base_Platform", (0, 0, 0.025), (0.34, 0.27, 0.05), "MintDark", col, 0.018)
    cube("Base_Column", (0, 0.085, 0.19), (0.10, 0.075, 0.33), "Cream", col, 0.016)
    cube("Base_TopHousing", (0, 0.025, 0.37), (0.27, 0.17, 0.11), "Mint", col, 0.018)
    cylinder("Base_Cup", (0, -0.035, 0.205), 0.070, 0.245, "Glass", col, 32, 0.004)
    cylinder("Base_Liquid", (0, -0.035, 0.185), 0.058, 0.170, "CoralSoft", col, 32, 0.002)
    torus("Base_ClampUpper", (0, -0.035, 0.315), 0.073, 0.010, "Coral", col)
    torus("Base_ClampLower", (0, -0.035, 0.095), 0.073, 0.010, "Coral", col)
    cube("Base_Display", (0, -0.067, 0.385), (0.11, 0.012, 0.048), "Screen", col, 0.005)
    for x in (-0.042, 0.0, 0.042):
        cylinder("Base_Button", (x, -0.078, 0.345), 0.010, 0.012, "Gold", col, 20, 0.002,
                 rot=(math.radians(90), 0, 0))
    tube("Base_Cable", [(0.14, 0.09, 0.07), (0.19, 0.10, 0.04), (0.18, 0.16, 0.02)],
         0.010, "CoralDark", col)
    cube("L2_SealModule", (0.10, 0.02, 0.445), (0.10, 0.14, 0.065), "Coral", col, 0.012)
    cylinder("L2_SealPress", (0.10, -0.025, 0.365), 0.026, 0.10, "Gold", col, 24, 0.003)
    cylinder("L2_StatusHalo", (0, 0.025, 0.455), 0.035, 0.030, "Gold", col, 24, 0.004)
    cylinder("L3_MotorLeft", (-0.125, 0.055, 0.405), 0.045, 0.115, "MintSoft", col, 24, 0.006,
             rot=(math.radians(90), 0, 0))
    cylinder("L3_MotorRight", (0.125, 0.055, 0.405), 0.045, 0.115, "MintSoft", col, 24, 0.006,
             rot=(math.radians(90), 0, 0))
    tube("L3_LightArch", [(-0.15, 0.02, 0.38), (-0.15, 0.02, 0.52),
                           (0.15, 0.02, 0.52), (0.15, 0.02, 0.38)], 0.012, "Gold", col)
    return col


def build_comfort():
    col = collection("UpgradeComfort")
    cube("Base_Rug", (0, 0, 0.018), (0.95, 0.50, 0.036), "MintSoft", col, 0.04)
    cube("Base_Bench", (-0.10, 0.02, 0.20), (0.68, 0.34, 0.20), "Wood", col, 0.035)
    cube("Base_Seat", (-0.10, -0.02, 0.33), (0.62, 0.30, 0.11), "Cream", col, 0.035)
    cube("Base_Back", (-0.10, 0.14, 0.52), (0.62, 0.11, 0.36), "CoralSoft", col, 0.045,
         rot=(math.radians(-8), 0, 0))
    cube("Base_CushionLeft", (-0.29, 0.02, 0.43), (0.19, 0.09, 0.20), "Mint", col, 0.045,
         rot=(math.radians(-10), math.radians(-8), 0))
    cube("Base_CushionRight", (0.09, 0.02, 0.43), (0.19, 0.09, 0.20), "Cream", col, 0.045,
         rot=(math.radians(-10), math.radians(8), 0))
    for x in (-0.34, 0.14):
        cylinder("Base_Foot", (x, 0.07, 0.10), 0.025, 0.18, "Gold", col, 20, 0.003)
    cylinder("L2_PlantPot", (0.38, 0.08, 0.20), 0.13, 0.28, "Coral", col, 32, 0.012)
    sphere("L2_Soil", (0.38, 0.08, 0.35), (0.105, 0.105, 0.035), "Cocoa", col, 24, 12)
    for i, (dx, dz, tilt) in enumerate([(-0.08, 0.16, -22), (0.0, 0.22, 0), (0.08, 0.15, 22)]):
        sphere("L2_Leaf_%d" % i, (0.38 + dx, 0.08, 0.41 + dz), (0.075, 0.025, 0.18),
               "Leaf", col, 24, 12).rotation_euler[1] = math.radians(tilt)
    cylinder("L3_LampPost", (-0.48, 0.15, 0.56), 0.022, 1.05, "Gold", col, 24, 0.003)
    cylinder("L3_LampBase", (-0.48, 0.15, 0.04), 0.14, 0.05, "MintDark", col, 32, 0.006)
    bpy.ops.mesh.primitive_cone_add(vertices=32, radius1=0.18, radius2=0.08, depth=0.22,
                                    location=(-0.48, 0.15, 1.05))
    finish(bpy.context.object, "L3_LampShade", "Cream", col, 0.005)
    sphere("L3_LampGlow", (-0.48, 0.15, 0.98), (0.055, 0.055, 0.065), "Gold", col, 24, 12)
    return col


def build_smart_sugar():
    col = collection("UpgradeSmartSugar")
    cube("Base_Platform", (0, 0, 0.025), (0.58, 0.25, 0.05), "MintDark", col, 0.016)
    cube("Base_Back", (0, 0.085, 0.23), (0.55, 0.07, 0.38), "Cream", col, 0.018,
         rot=(math.radians(-5), 0, 0))
    cube("Base_Screen", (0, 0.036, 0.29), (0.24, 0.025, 0.13), "Screen", col, 0.012,
         rot=(math.radians(-5), 0, 0))
    for i, material in enumerate(["Cream", "CreamDark", "Gold", "CoralSoft", "Coral"]):
        x = -0.22 + i * 0.11
        cylinder("Base_Reservoir_%d" % i, (x, -0.02, 0.17), 0.042, 0.25, material, col, 24, 0.005)
        cylinder("Base_Nozzle_%d" % i, (x, -0.10, 0.11), 0.012, 0.13, "Gold", col, 18, 0.002,
                 rot=(math.radians(90), 0, 0))
    tube("Base_ScreenArc", [(-0.09, 0.02, 0.31), (0, 0.02, 0.35), (0.09, 0.02, 0.31)],
         0.009, "MintSoft", col)
    cylinder("Base_ScanPad", (0, -0.10, 0.06), 0.09, 0.025, "Coral", col, 32, 0.004)
    torus("Base_ScanRing", (0, -0.10, 0.074), 0.055, 0.008, "Gold", col)
    return col


def build_tip_jar():
    col = collection("UpgradeTipJar")
    cylinder("Base_Plinth", (0, 0, 0.028), 0.15, 0.056, "MintDark", col, 32, 0.008)
    cylinder("Base_Jar", (0, 0, 0.20), 0.12, 0.32, "Glass", col, 32, 0.006)
    cylinder("Base_Rim", (0, 0, 0.37), 0.13, 0.045, "Coral", col, 32, 0.006)
    for i, (x, y, z, tilt) in enumerate([
        (-0.045, -0.018, 0.075, 8), (0.035, 0.018, 0.085, -12),
        (-0.015, 0.03, 0.12, 18), (0.055, -0.025, 0.14, -6),
    ]):
        cylinder("Base_Coin_%d" % i, (x, y, z), 0.035, 0.008, "Gold", col, 20, 0.001,
                 rot=(math.radians(tilt), 0, math.radians(tilt * 2)))
    cube("Base_Label", (0, -0.123, 0.22), (0.16, 0.012, 0.10), "Cream", col, 0.012)
    torus("Base_LabelHeart", (0, -0.132, 0.225), 0.025, 0.008, "Coral", col,
          rot=(math.radians(90), 0, 0))
    tube("L2_Ribbon", [(-0.12, 0, 0.30), (-0.04, -0.13, 0.31),
                        (0.04, -0.13, 0.31), (0.12, 0, 0.30)], 0.016, "Mint", col)
    sphere("L2_BowLeft", (-0.055, -0.145, 0.31), (0.055, 0.018, 0.035), "Mint", col, 24, 12)
    sphere("L2_BowRight", (0.055, -0.145, 0.31), (0.055, 0.018, 0.035), "Mint", col, 24, 12)
    cylinder("L3_TopperPost", (0, 0, 0.48), 0.015, 0.18, "Gold", col, 20, 0.002)
    sphere("L3_TopperGlow", (0, 0, 0.59), (0.075, 0.035, 0.075), "Gold", col, 24, 12)
    torus("L3_TopperHalo", (0, 0, 0.59), 0.085, 0.008, "Coral", col,
          rot=(math.radians(90), 0, 0))
    return col


def export_collection(col, filename):
	# Keep the authored collection fully editable, but batch export duplicates by
	# level tier + material. This preserves L2_/L3_ visibility contracts while
	# reducing mobile draw calls substantially.
	temp = bpy.data.collections.new("EXPORT_" + col.name)
	bpy.context.scene.collection.children.link(temp)
	groups = {}
	for source in col.objects:
		if source.type != "MESH":
			continue
		obj = source.copy()
		obj.data = source.data.copy()
		temp.objects.link(obj)
		tier = "L3" if source.name.startswith("L3_") else ("L2" if source.name.startswith("L2_") else "Base")
		material_name = obj.data.materials[0].name if obj.data.materials else "Unmaterialed"
		groups.setdefault((tier, material_name), []).append(obj)
	for (tier, material_name), objects in groups.items():
		bpy.ops.object.select_all(action="DESELECT")
		for obj in objects:
			obj.select_set(True)
		bpy.context.view_layer.objects.active = objects[0]
		if len(objects) > 1:
			bpy.ops.object.join()
		objects[0].name = "%s_%s" % (tier, material_name)
	bpy.ops.object.select_all(action="DESELECT")
	for obj in temp.objects:
		obj.select_set(True)
	bpy.context.view_layer.objects.active = next(iter(temp.objects))
	for directory in (SOURCE_DIR, RUNTIME_DIR):
		os.makedirs(directory, exist_ok=True)
		bpy.ops.export_scene.gltf(filepath=os.path.join(directory, filename), export_format="GLB",
								  use_selection=True, export_apply=True, export_yup=True)
	for obj in list(temp.objects):
		bpy.data.objects.remove(obj, do_unlink=True)
	bpy.data.collections.remove(temp)


def set_preview():
    placements = {
        "UpgradeComfort": (-1.45, 0.10, 0.0),
        "UpgradeAutoShaker": (-0.48, 0.0, 0.0),
        "UpgradeSmartSugar": (0.32, 0.0, 0.0),
        "UpgradeTipJar": (1.02, 0.0, 0.0),
    }
    for name, offset in placements.items():
        for obj in bpy.data.collections[name].objects:
            obj.location.x += offset[0]
            obj.location.y += offset[1]
            obj.location.z += offset[2]
    cube("PreviewFloor", (-0.15, 0.22, -0.045), (3.35, 1.30, 0.09), "Cream", bpy.context.scene.collection, 0.035)
    bpy.ops.object.camera_add(location=(-0.25, -5.60, 2.18))
    camera = bpy.context.object
    camera.name = "PreviewCamera"
    bpy.context.scene.camera = camera
    direction = Vector((-0.30, 0.12, 0.38)) - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    camera.data.lens = 55
    bpy.ops.object.light_add(type="AREA", location=(-1.8, -2.2, 3.2))
    key = bpy.context.object
    key.name = "PreviewKey"
    key.data.energy = 650
    key.data.shape = "DISK"
    key.data.size = 4.0
    bpy.ops.object.light_add(type="AREA", location=(2.3, 0.5, 2.1))
    fill = bpy.context.object
    fill.name = "PreviewFill"
    fill.data.energy = 300
    fill.data.color = (0.56, 1.0, 0.87)
    fill.data.size = 3.0
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 1280
    scene.render.resolution_y = 720
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = PREVIEW_PATH
    scene.render.film_transparent = False
    scene.world.color = (0.035, 0.045, 0.04)
    scene.view_settings.look = "Medium High Contrast"
    scene.view_settings.exposure = -0.45
    bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH)
    bpy.ops.render.render(write_still=True)


def main():
    reset()
    make_materials()
    collections = {
        "auto_shaker.glb": build_auto_shaker(),
        "comfort.glb": build_comfort(),
        "smart_sugar.glb": build_smart_sugar(),
        "tip_jar.glb": build_tip_jar(),
    }
    bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH)
    for filename, col in collections.items():
        export_collection(col, filename)
    set_preview()
    print({
        "blend": BLEND_PATH,
        "preview": PREVIEW_PATH,
        "exports": sorted(collections.keys()),
        "objects": sum(len(col.objects) for col in collections.values()),
    })


main()
