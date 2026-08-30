import bpy
import math
import os
from mathutils import Vector


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
BLEND_PATH = os.path.join(ROOT, "assets_src/blend/route_signs.blend")
SOURCE_DIR = os.path.join(ROOT, "assets_src/glb/props/routes")
RUNTIME_DIR = os.path.join(ROOT, "game/assets/glb/props/routes")
PREVIEW_PATH = os.path.join(ROOT, "assets_src/renders/route_signs_preview.png")

PALETTE = {
    "Cream": (1.00, 0.965, 0.89, 1.0),
    "Cocoa": (0.24, 0.11, 0.075, 1.0),
    "Coral": (1.00, 0.27, 0.24, 1.0),
    "CoralDark": (0.58, 0.10, 0.08, 1.0),
    "Mint": (0.15, 0.72, 0.61, 1.0),
    "Purple": (0.48, 0.27, 0.68, 1.0),
    "PurpleSoft": (0.78, 0.65, 0.89, 1.0),
    "Gold": (0.95, 0.56, 0.14, 1.0),
}


def reset():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for col in list(bpy.data.collections):
        bpy.data.collections.remove(col)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials,
                       bpy.data.cameras, bpy.data.lights):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def make_materials():
    for name, color in PALETTE.items():
        material = bpy.data.materials.new(name)
        material.diffuse_color = color
        material.use_nodes = True
        bsdf = material.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = 0.34 if name == "Gold" else 0.52
        bsdf.inputs["Metallic"].default_value = 0.55 if name == "Gold" else 0.0


def collection(name):
    col = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(col)
    return col


def move_to(obj, col):
    for owner in list(obj.users_collection):
        owner.objects.unlink(obj)
    col.objects.link(obj)
    return obj


def finish(obj, name, material, col, bevel=0.0, smooth=False):
    obj.name = name
    if material:
        obj.data.materials.append(bpy.data.materials[material])
    if smooth and hasattr(obj.data, "polygons"):
        for polygon in obj.data.polygons:
            polygon.use_smooth = True
    if bevel > 0:
        modifier = obj.modifiers.new("SoftBevel", "BEVEL")
        modifier.width = bevel
        modifier.segments = 1
        modifier.limit_method = "ANGLE"
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    return move_to(obj, col)


def extruded_polygon(name, points, depth, y, material, col, bevel=0.008):
    # Points are authored clockwise/counter-clockwise in the X/Z plane. Blender -Y
    # exports as Godot +Z, so y-depth makes a wall-facing relief without runtime rotation.
    count = len(points)
    front_y = y - depth * 0.5
    back_y = y + depth * 0.5
    vertices = [(x, front_y, z) for x, z in points] + [(x, back_y, z) for x, z in points]
    faces = [tuple(range(count - 1, -1, -1)), tuple(range(count, count * 2))]
    for i in range(count):
        nxt = (i + 1) % count
        faces.append((i, nxt, count + nxt, count + i))
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    col.objects.link(obj)
    return finish(obj, name, material, col, bevel)


def cylinder_face(name, x, z, radius, depth, y, material, col, vertices=16):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices, radius=radius, depth=depth,
        location=(x, y, z), rotation=(math.radians(90), 0, 0))
    return finish(bpy.context.object, name, material, col, 0.004, True)


def tube(name, points, radius, y, material, col):
    curve = bpy.data.curves.new(name + "Curve", "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 1
    curve.bevel_depth = radius
    curve.bevel_resolution = 1
    spline = curve.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for point, (x, z) in zip(spline.points, points):
        point.co = (x, y, z, 1.0)
    obj = bpy.data.objects.new(name, curve)
    col.objects.link(obj)
    curve.materials.append(bpy.data.materials[material])
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    return obj


def star_points(cx, cz, outer, inner, count=5, phase=math.pi / 2):
    points = []
    for i in range(count * 2):
        radius = outer if i % 2 == 0 else inner
        angle = phase + i * math.pi / count
        points.append((cx + math.cos(angle) * radius, cz + math.sin(angle) * radius))
    return points


def scaled(points, factor):
    return [(x * factor, z * factor) for x, z in points]


def build_rush():
    col = collection("RouteRush")
    outline = [(-0.36, -0.18), (0.25, -0.18), (0.36, 0.0), (0.25, 0.18), (-0.36, 0.18)]
    extruded_polygon("Route_Rush_Frame", outline, 0.065, 0.0, "CoralDark", col, 0.012)
    extruded_polygon("Route_Rush_Face", scaled(outline, 0.90), 0.026, -0.048, "Cream", col, 0.010)
    # Three forward chevrons read as throughput even when the model is small.
    for index, x in enumerate((-0.18, 0.0, 0.18)):
        tube("Route_Rush_Arrow_%d" % index,
             [(x - 0.075, -0.09), (x + 0.025, 0.0), (x - 0.075, 0.09)],
             0.022, -0.072, "Coral", col)
    cylinder_face("Route_Rush_Bolt", -0.29, 0.0, 0.025, 0.024, -0.075, "Gold", col, 12)
    return col


def build_precision():
    col = collection("RoutePrecision")
    seal = []
    for i in range(24):
        angle = math.pi / 2 + i * math.tau / 24.0
        radius = 0.285 if i % 2 == 0 else 0.255
        seal.append((math.cos(angle) * radius, math.sin(angle) * radius))
    extruded_polygon("Route_Precision_Frame", seal, 0.070, 0.0, "Purple", col, 0.008)
    cylinder_face("Route_Precision_Face", 0.0, 0.0, 0.218, 0.026, -0.050,
                  "Cream", col, 24)
    extruded_polygon("Route_Precision_Star", star_points(0.0, 0.0, 0.135, 0.062),
                     0.026, -0.078, "Mint", col, 0.006)
    # Twin tails make the silhouette read as a quality/reputation seal.
    extruded_polygon("Route_Precision_RibbonLeft",
                     [(-0.18, -0.18), (-0.04, -0.20), (-0.09, -0.37), (-0.20, -0.28)],
                     0.045, 0.015, "PurpleSoft", col, 0.006)
    extruded_polygon("Route_Precision_RibbonRight",
                     [(0.04, -0.20), (0.18, -0.18), (0.20, -0.28), (0.09, -0.37)],
                     0.045, 0.015, "PurpleSoft", col, 0.006)
    return col


def build_trend():
    col = collection("RouteTrend")
    outline = [(-0.34, -0.19), (0.34, -0.19), (0.34, 0.02)]
    for i in range(7):
        angle = i * math.pi / 6.0
        outline.append((math.cos(angle) * 0.34, 0.02 + math.sin(angle) * 0.25))
    outline.append((-0.34, 0.02))
    extruded_polygon("Route_Trend_Frame", outline, 0.070, 0.0, "Gold", col, 0.012)
    inset = [(x * 0.89, (z + 0.02) * 0.86 - 0.02) for x, z in outline]
    extruded_polygon("Route_Trend_Face", inset, 0.026, -0.050, "Cream", col, 0.010)
    tube("Route_Trend_Rise", [(-0.23, -0.09), (-0.08, -0.01), (0.03, 0.04), (0.17, 0.13)],
         0.020, -0.078, "Mint", col)
    extruded_polygon("Route_Trend_Star", star_points(0.20, 0.14, 0.105, 0.042, 4),
                     0.025, -0.080, "Coral", col, 0.005)
    for index, (x, z) in enumerate([(-0.22, 0.12), (-0.08, 0.16)]):
        extruded_polygon("Route_Trend_Spark_%d" % index,
                         star_points(x, z, 0.045, 0.017, 4),
                         0.020, -0.078, "Gold", col, 0.003)
    return col


def export_collection(col, filename):
    # Editable pieces remain separate in the .blend; runtime copies are joined by
    # material to cap each route at a handful of surfaces/draw submissions.
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
        groups.setdefault(material_name, []).append(obj)
    for material_name, objects in groups.items():
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        if len(objects) > 1:
            bpy.ops.object.join()
        objects[0].name = "Route_%s" % material_name
    bpy.ops.object.select_all(action="DESELECT")
    for obj in temp.objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = next(iter(temp.objects))
    for directory in (SOURCE_DIR, RUNTIME_DIR):
        os.makedirs(directory, exist_ok=True)
        bpy.ops.export_scene.gltf(
            filepath=os.path.join(directory, filename), export_format="GLB",
            use_selection=True, export_apply=True, export_yup=True)
    for obj in list(temp.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    bpy.data.collections.remove(temp)


def set_preview(collections):
    offsets = {"RouteRush": -0.95, "RoutePrecision": 0.0, "RouteTrend": 0.95}
    for col in collections.values():
        for obj in col.objects:
            obj.location.x += offsets[col.name]
            obj.location.z += 0.42
    bpy.ops.mesh.primitive_cube_add(location=(0, 0.14, 0.43))
    backdrop = bpy.context.object
    backdrop.name = "PreviewWall"
    backdrop.dimensions = (3.25, 0.10, 1.18)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    finish(backdrop, "PreviewWall", "Mint", bpy.context.scene.collection, 0.035)
    bpy.ops.object.camera_add(location=(0, -4.5, 1.10))
    camera = bpy.context.object
    bpy.context.scene.camera = camera
    direction = Vector((0, 0, 0.43)) - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    camera.data.lens = 58
    bpy.ops.object.light_add(type="AREA", location=(-1.8, -2.2, 3.2))
    key = bpy.context.object
    key.data.energy = 700
    key.data.size = 4.0
    bpy.ops.object.light_add(type="AREA", location=(2.2, -0.8, 1.8))
    fill = bpy.context.object
    fill.data.energy = 350
    fill.data.color = (0.65, 0.86, 1.0)
    fill.data.size = 3.0
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 1280
    scene.render.resolution_y = 720
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = PREVIEW_PATH
    scene.world.color = (0.035, 0.030, 0.028)
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.view_settings.exposure = -0.30
    bpy.ops.render.render(write_still=True)


def main():
    reset()
    make_materials()
    collections = {
        "route_rush.glb": build_rush(),
        "route_precision.glb": build_precision(),
        "route_trend.glb": build_trend(),
    }
    bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH)
    for filename, col in collections.items():
        export_collection(col, filename)
    set_preview(collections)
    print({
        "blend": BLEND_PATH,
        "preview": PREVIEW_PATH,
        "exports": sorted(collections.keys()),
        "objects": sum(len(col.objects) for col in collections.values()),
    })


main()
