import bpy
import math
import os
from mathutils import Vector


BLEND_PATH = "/Users/apple/Code/milkteahouse/assets_src/blend/props_hd.blend"
GLB_SOURCE_DIR = "/Users/apple/Code/milkteahouse/assets_src/glb/props_hd"
GLB_RUNTIME_DIR = "/Users/apple/Code/milkteahouse/game/assets/glb/props"


def material(name):
    return bpy.data.materials[name]


def collection(name):
    old = bpy.data.collections.get(name)
    if old:
        for obj in list(old.objects):
            bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.collections.remove(old)
    col = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(col)
    return col


def move_to(obj, col):
    for current in list(obj.users_collection):
        current.objects.unlink(obj)
    col.objects.link(obj)
    return obj


def finish(obj, name, mat, col, bevel=0.0):
    obj.name = name
    if mat:
        obj.data.materials.append(material(mat))
    if hasattr(obj.data, "polygons"):
        for poly in obj.data.polygons:
            poly.use_smooth = True
    if bevel > 0.0:
        mod = obj.modifiers.new("SoftBevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        mod.limit_method = "ANGLE"
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return move_to(obj, col)


def cube(name, loc, dims, mat, col, bevel=0.006, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(location=loc, rotation=rot)
    obj = bpy.context.object
    obj.dimensions = dims
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, mat, col, min(bevel, min(dims) * 0.24))


def cylinder(name, loc, radius, depth, mat, col, vertices=20, bevel=0.003, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc, rotation=rot)
    return finish(bpy.context.object, name, mat, col, bevel)


def sphere(name, loc, scale, mat, col):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=18, ring_count=9, location=loc)
    obj = bpy.context.object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, mat, col)


def torus(name, loc, major, minor, mat, col, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor,
                                    major_segments=20, minor_segments=6,
                                    location=loc, rotation=rot)
    return finish(bpy.context.object, name, mat, col)


def cone(name, loc, r1, r2, depth, mat, col, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=r1, radius2=r2,
                                   depth=depth, location=loc, rotation=rot)
    return finish(bpy.context.object, name, mat, col, 0.002)


def tube(name, points, radius, mat, col, cyclic=False):
    curve = bpy.data.curves.new(name + "Curve", "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 2
    curve.bevel_depth = radius
    curve.bevel_resolution = 1
    spline = curve.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for bp, co in zip(spline.bezier_points, points):
        bp.co = co
        bp.handle_left_type = "AUTO"
        bp.handle_right_type = "AUTO"
    spline.use_cyclic_u = cyclic
    obj = bpy.data.objects.new(name, curve)
    col.objects.link(obj)
    curve.materials.append(material(mat))
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


def label_plate(name, loc, dims, col):
    return cube(name, loc, dims, "Cream", col, 0.004)


def build_kettle():
    col = collection("KettleHD")
    cylinder("TrayBase", (0, 0, 0.012), 0.145, 0.024, "MintDark", col, bevel=0.004)
    cylinder("TrayTop", (0, 0, 0.029), 0.132, 0.018, "Mint", col, bevel=0.003)
    torus("TrayAccent", (0, 0, 0.040), 0.105, 0.006, "Coral", col)
    sphere("TintBody", (0, 0, 0.125), (0.105, 0.098, 0.095), "Coral", col)
    cylinder("BodyFoot", (0, 0, 0.055), 0.080, 0.025, "CoralDark", col, bevel=0.004)
    sphere("Lid", (0, 0, 0.205), (0.080, 0.075, 0.025), "Coral", col)
    cylinder("LidKnob", (0, 0, 0.242), 0.022, 0.030, "Coral", col, bevel=0.005)
    cone("Spout", (-0.115, 0, 0.145), 0.032, 0.018, 0.110, "Coral", col,
         rot=(0, math.radians(-72), 0))
    tube("Handle", [(0.080, 0, 0.185), (0.145, 0, 0.190),
                    (0.162, 0, 0.118), (0.105, 0, 0.083)],
         0.014, "CoralDark", col)
    return col


def build_milk_carton():
    col = collection("MilkCartonHD")
    cube("CartonBody", (0, 0, 0.095), (0.090, 0.074, 0.190), "Cream", col, 0.008)
    cube("TintPanel", (0, -0.0385, 0.100), (0.068, 0.005, 0.120), "Mint", col, 0.002)
    cube("SideMint", (0.046, 0, 0.105), (0.004, 0.062, 0.145), "Mint", col, 0.001)
    cube("RoofLeft", (-0.022, 0, 0.205), (0.046, 0.074, 0.050), "Cream", col, 0.004,
         rot=(0, math.radians(-24), 0))
    cube("RoofRight", (0.022, 0, 0.205), (0.046, 0.074, 0.050), "Mint", col, 0.004,
         rot=(0, math.radians(24), 0))
    cube("Fold", (0, 0, 0.238), (0.070, 0.076, 0.018), "Cream", col, 0.003)
    cylinder("DropMark", (0, -0.042, 0.115), 0.010, 0.004, "MintDark", col,
             vertices=20, bevel=0.001, rot=(math.radians(90), 0, 0))
    return col


def build_topping_bin():
    col = collection("ToppingBinHD")
    cube("BinFoot", (0, 0, 0.012), (0.126, 0.126, 0.024), "MintDark", col, 0.006)
    cube("TintBody", (0, 0, 0.065), (0.120, 0.120, 0.095), "Cream", col, 0.010)
    cube("InnerTray", (0, -0.002, 0.098), (0.098, 0.098, 0.035), "CreamDark", col, 0.008)
    cube("Lid", (0, 0.015, 0.133), (0.126, 0.110, 0.025), "Wood", col, 0.010)
    cylinder("LidKnob", (0, 0.015, 0.156), 0.014, 0.020, "Wood", col, bevel=0.004)
    sphere("ScoopBowl", (0.027, -0.018, 0.124), (0.020, 0.016, 0.009), "Cream", col)
    tube("ScoopHandle", [(0.038, -0.010, 0.128), (0.070, 0.020, 0.160),
                         (0.088, 0.035, 0.178)], 0.005, "Cream", col)
    return col


def build_sugar_pump():
    col = collection("SugarPumpHD")
    cube("Tray", (0, 0, 0.010), (0.090, 0.088, 0.020), "MintDark", col, 0.008)
    cube("Bottle", (0, 0, 0.090), (0.072, 0.068, 0.140), "Glass", col, 0.014)
    cube("TintLiquid", (0, 0, 0.072), (0.060, 0.056, 0.100), "TintLiquid", col, 0.012)
    cylinder("Collar", (0, 0, 0.170), 0.026, 0.025, "Cream", col, bevel=0.004)
    cylinder("PumpStem", (0, 0, 0.202), 0.009, 0.050, "Cream", col, bevel=0.003)
    tube("PumpHead", [(0, 0, 0.225), (0, -0.020, 0.236),
                      (0, -0.050, 0.236)], 0.009, "Cream", col)
    cube("BottleMark", (0, -0.036, 0.100), (0.034, 0.004, 0.012), "Cream", col, 0.002)
    return col


def build_shaker():
    col = collection("ShakerHD")
    cylinder("MachineFoot", (0, 0, 0.012), 0.100, 0.024, "Cocoa", col, bevel=0.004)
    cylinder("MachineBase", (0, 0, 0.040), 0.087, 0.045, "MintDark", col, bevel=0.006)
    sphere("MachineShell", (0, 0, 0.076), (0.082, 0.082, 0.055), "Mint", col)
    cylinder("FrontButton", (0, -0.079, 0.060), 0.012, 0.008, "Cream", col,
             vertices=20, bevel=0.002, rot=(math.radians(90), 0, 0))
    cylinder("CupGlass", (0, 0, 0.168), 0.055, 0.170, "Glass", col, bevel=0.002)
    cylinder("CupInset", (0, 0, 0.160), 0.047, 0.145, "CreamDark", col, bevel=0.001)
    cylinder("Spindle", (0, 0, 0.166), 0.006, 0.120, "Metal", col, vertices=16, bevel=0.001)
    cylinder("TintLid", (0, 0, 0.263), 0.064, 0.030, "Mint", col, bevel=0.006)
    cylinder("LidKnob", (0, 0, 0.290), 0.030, 0.025, "MintDark", col, bevel=0.005)
    return col


def build_prep_mat():
    col = collection("PrepMatHD")
    cube("MatBase", (0, 0, 0.010), (0.380, 0.280, 0.020), "Wood", col, 0.018)
    cube("MatInset", (0, 0, 0.022), (0.350, 0.250, 0.014), "Cream", col, 0.014)
    torus("CupGuide", (0, 0, 0.032), 0.066, 0.003, "Mint", col)
    return col


def build_pickup_tray():
    col = collection("PickupTrayHD")
    cube("TrayBase", (0, 0, 0.012), (0.320, 0.260, 0.024), "MintDark", col, 0.018)
    cube("TrayInset", (0, 0, 0.025), (0.280, 0.220, 0.018), "Cream", col, 0.014)
    tube("TrayFrame", [(-0.145, -0.115, 0.038), (0.145, -0.115, 0.038),
                       (0.145, 0.115, 0.038), (-0.145, 0.115, 0.038)],
         0.012, "Mint", col, cyclic=True)
    return col


def build_service_bell():
    col = collection("ServiceBellHD")
    cylinder("BellFoot", (0, 0, 0.010), 0.056, 0.020, "Cocoa", col, bevel=0.005)
    cylinder("BellBase", (0, 0, 0.026), 0.050, 0.016, "Metal", col, bevel=0.003)
    sphere("TintDome", (0, 0, 0.055), (0.046, 0.046, 0.034), "Mint", col)
    torus("DomeRing", (0, 0, 0.042), 0.042, 0.003, "MintDark", col)
    cylinder("BellButton", (0, 0, 0.094), 0.010, 0.018, "Mint", col, bevel=0.003)
    return col


def export_collection(col, filename):
    # Keep source pieces independently editable, but export duplicates batched by
    # material. Tint-prefixed parts stay in their own group so Godot can recolor
    # tea, milk and toppings without affecting fixed coral/mint accents.
    temp = bpy.data.collections.new("EXPORT_" + col.name)
    bpy.context.scene.collection.children.link(temp)
    groups = {}
    for source in col.objects:
        if source.type != "MESH":
            continue
        obj = source.copy()
        obj.data = source.data.copy()
        temp.objects.link(obj)
        material_name = obj.data.materials[0].name if obj.data.materials else "Unmaterialed"
        contract = "Tint" if source.name.startswith("Tint") else "Fixed"
        groups.setdefault((contract, material_name), []).append(obj)
    for (contract, material_name), objects in groups.items():
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        if len(objects) > 1:
            bpy.ops.object.join()
        objects[0].name = ("Tint_" if contract == "Tint" else "") + material_name
    bpy.ops.object.select_all(action="DESELECT")
    for obj in temp.objects:
        obj.select_set(True)
    if temp.objects:
        bpy.context.view_layer.objects.active = next(iter(temp.objects))
    for folder in (GLB_SOURCE_DIR, GLB_RUNTIME_DIR):
        os.makedirs(folder, exist_ok=True)
        bpy.ops.export_scene.gltf(filepath=os.path.join(folder, filename),
                                  export_format="GLB", use_selection=True,
                                  export_apply=True, export_yup=True,
                                  export_materials="EXPORT")
    stats = {
        "meshes": len(temp.objects),
        "triangles": sum(len(obj.data.polygons) for obj in temp.objects if obj.type == "MESH"),
    }
    for obj in list(temp.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    bpy.data.collections.remove(temp)
    return stats


assets = [
    (build_kettle(), "kettle.glb"),
    (build_milk_carton(), "milk_carton.glb"),
    (build_topping_bin(), "topping_bin.glb"),
    (build_sugar_pump(), "sugar_pump.glb"),
    (build_shaker(), "shaker.glb"),
    (build_prep_mat(), "prep_mat.glb"),
    (build_pickup_tray(), "pickup_tray.glb"),
    (build_service_bell(), "service_bell.glb"),
]

export_stats = {}
for col, filename in assets:
    export_stats[filename] = export_collection(col, filename)

bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH)
print({"source_objects": {col.name: len(col.objects) for col, _ in assets},
       "runtime": export_stats})
