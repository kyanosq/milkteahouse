import bpy
import math
import os
from mathutils import Vector


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
BLEND_PATH = os.path.join(ROOT, "assets_src/blend/customer.blend")
SOURCE_GLB = os.path.join(ROOT, "assets_src/glb/customer.glb")
RUNTIME_GLB = os.path.join(ROOT, "game/assets/glb/customer.glb")
PREVIEW_PATH = os.path.join(ROOT, "assets_src/renders/customer_classic_mobile_preview.png")


def reset():
    # Clear scene data without read_factory_settings: factory reset reloads add-ons
    # and would sever the Blender MCP connection executing this builder.
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for collection in list(bpy.data.collections):
        bpy.data.collections.remove(collection)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials,
                       bpy.data.cameras, bpy.data.lights):
        for datablock in list(datablocks):
            datablocks.remove(datablock)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = True
    if scene.world is None:
        scene.world = bpy.data.worlds.new("World")
    scene.world.color = (0.055, 0.070, 0.085)


def material(name, color, roughness=0.48, metallic=0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    return mat


def make_materials():
    material("Skin", (1.0, 0.73, 0.60), 0.52)
    material("HairMint", (0.17, 0.70, 0.66), 0.42)
    material("Lavender", (0.59, 0.43, 0.78), 0.52)
    material("Mint", (0.12, 0.58, 0.54), 0.44)
    material("Cream", (0.98, 0.92, 0.82), 0.52)
    material("Cheek", (1.0, 0.45, 0.43), 0.56)
    material("White", (0.98, 0.96, 0.90), 0.46)
    material("Black", (0.055, 0.045, 0.040), 0.42)


def finish(obj, name, mat_name, collection, bevel=0.0, smooth=True):
    obj.name = name
    obj.data.materials.append(bpy.data.materials[mat_name])
    if smooth:
        for poly in obj.data.polygons:
            poly.use_smooth = True
    if bevel > 0.0:
        modifier = obj.modifiers.new("SoftBevel", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
        modifier.limit_method = "ANGLE"
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    for old in list(obj.users_collection):
        old.objects.unlink(obj)
    collection.objects.link(obj)
    return obj


def sphere(name, location, scale, mat_name, collection, segments=12, rings=6):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=location)
    obj = bpy.context.object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, mat_name, collection)


def cylinder(name, location, radius, depth, mat_name, collection, rotation=(0, 0, 0), vertices=16, bevel=0.004):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth,
                                       location=location, rotation=rotation)
    return finish(bpy.context.object, name, mat_name, collection, bevel)


def cube(name, location, dimensions, mat_name, collection, bevel=0.012):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, mat_name, collection, min(bevel, min(dimensions) * 0.2), False)


def torus(name, location, major, minor, mat_name, collection, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor,
                                    major_segments=16, minor_segments=6,
                                    location=location, rotation=rotation)
    return finish(bpy.context.object, name, mat_name, collection)


def tube(name, points, radius, mat_name, collection):
    curve = bpy.data.curves.new(name + "Curve", "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 2
    curve.bevel_depth = radius
    curve.bevel_resolution = 1
    curve.resolution_u = 2
    spline = curve.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for point, coordinate in zip(spline.bezier_points, points):
        point.co = coordinate
        point.handle_left_type = "AUTO"
        point.handle_right_type = "AUTO"
    obj = bpy.data.objects.new(name, curve)
    collection.objects.link(obj)
    curve.materials.append(bpy.data.materials[mat_name])
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


def build_customer():
    collection = bpy.data.collections.new("CustomerClassicMobile")
    bpy.context.scene.collection.children.link(collection)
    sphere("Shoe_L", (-0.075, -0.015, 0.045), (0.065, 0.085, 0.040), "Mint", collection)
    sphere("Shoe_R", (0.075, -0.015, 0.045), (0.065, 0.085, 0.040), "Mint", collection)
    cylinder("Leg_L", (-0.070, 0, 0.115), 0.040, 0.105, "Skin", collection)
    cylinder("Leg_R", (0.070, 0, 0.115), 0.040, 0.105, "Skin", collection)
    cube("Shorts", (0, 0.010, 0.185), (0.235, 0.155, 0.135), "Cream", collection, 0.022)
    cube("Body", (0, 0.005, 0.310), (0.245, 0.160, 0.190), "Lavender", collection, 0.038)
    cylinder("Arm_L", (-0.143, 0, 0.300), 0.043, 0.190, "Lavender", collection,
             (0, math.radians(-5), 0))
    cylinder("Arm_R", (0.143, 0, 0.300), 0.043, 0.190, "Lavender", collection,
             (0, math.radians(5), 0))
    sphere("Hand_L", (-0.151, -0.005, 0.202), (0.045, 0.043, 0.047), "Skin", collection)
    sphere("Hand_R", (0.151, -0.005, 0.202), (0.045, 0.043, 0.047), "Skin", collection)
    sphere("Head", (0, -0.018, 0.540), (0.166, 0.145, 0.154), "Skin", collection, 18, 10)
    sphere("HairBack", (0, 0.065, 0.565), (0.174, 0.100, 0.160), "HairMint", collection, 18, 10)
    for index, x in enumerate((-0.105, -0.055, 0.0, 0.055, 0.105)):
        sphere("Bang_%d" % index, (x, -0.132, 0.624), (0.045, 0.027, 0.073),
               "HairMint", collection, 10, 5)
    sphere("Eye_L", (-0.058, -0.151, 0.550), (0.019, 0.010, 0.027), "Black", collection, 8, 4)
    sphere("Eye_R", (0.058, -0.151, 0.550), (0.019, 0.010, 0.027), "Black", collection, 8, 4)
    sphere("Cheek_L", (-0.100, -0.151, 0.510), (0.026, 0.007, 0.015), "Cheek", collection, 8, 4)
    sphere("Cheek_R", (0.100, -0.151, 0.510), (0.026, 0.007, 0.015), "Cheek", collection, 8, 4)
    tube("Mouth", [(-0.021, -0.155, 0.505), (0, -0.162, 0.495), (0.021, -0.155, 0.505)],
         0.004, "Black", collection)
    torus("Glasses_L", (-0.064, -0.132, 0.680), 0.036, 0.006, "White", collection,
          (math.radians(90), 0, 0))
    torus("Glasses_R", (0.064, -0.132, 0.680), 0.036, 0.006, "White", collection,
          (math.radians(90), 0, 0))
    cube("GlassesBridge", (0, -0.137, 0.680), (0.040, 0.010, 0.010), "White", collection, 0.002)
    return collection


def export_batched(source_collection):
    export_collection = bpy.data.collections.new("EXPORT_CustomerClassicMobile")
    bpy.context.scene.collection.children.link(export_collection)
    groups = {}
    for source in source_collection.objects:
        obj = source.copy()
        obj.data = source.data.copy()
        export_collection.objects.link(obj)
        if source.name.startswith("Body") or source.name.startswith("Arm"):
            key = "Body_Cloth"
        elif source.name.startswith("Hair") or source.name.startswith("Bang"):
            key = "Hair"
        else:
            key = source.data.materials[0].name
        groups.setdefault(key, []).append(obj)
    for name, objects in groups.items():
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        if len(objects) > 1:
            bpy.ops.object.join()
        objects[0].name = name
    bpy.ops.object.select_all(action="DESELECT")
    for obj in export_collection.objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = next(iter(export_collection.objects))
    for path in (SOURCE_GLB, RUNTIME_GLB):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True,
                                  export_apply=True, export_yup=True, export_materials="EXPORT")
    mesh_count = len(export_collection.objects)
    triangles = sum(len(obj.data.polygons) for obj in export_collection.objects if obj.type == "MESH")
    for obj in list(export_collection.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    bpy.data.collections.remove(export_collection)
    return mesh_count, triangles


def add_preview():
    floor_mat = material("PreviewCream", (0.92, 0.88, 0.78), 0.62)
    bpy.ops.mesh.primitive_plane_add(size=3.0, location=(0, 0, 0.0))
    bpy.context.object.data.materials.append(floor_mat)
    bpy.ops.object.camera_add(location=(1.15, -2.45, 1.05))
    camera = bpy.context.object
    camera.data.lens = 58
    camera.rotation_euler = ((0.42, 0.0, 0.44))
    direction = Vector((0, 0, 0.38)) - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = camera
    bpy.ops.object.light_add(type="AREA", location=(-1.4, -1.8, 2.3))
    bpy.context.object.data.energy = 720
    bpy.context.object.data.shape = "DISK"
    bpy.context.object.data.size = 2.0
    bpy.ops.object.light_add(type="AREA", location=(1.7, -0.2, 1.4))
    bpy.context.object.data.energy = 460
    bpy.context.object.data.color = (0.55, 0.95, 0.86)
    bpy.context.object.data.size = 1.5


reset()
make_materials()
customer = build_customer()
mesh_count, triangles = export_batched(customer)
add_preview()
bpy.context.scene.render.filepath = PREVIEW_PATH
bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH)
print({"source_objects": len(customer.objects), "runtime_meshes": mesh_count,
       "triangles": triangles, "blend": BLEND_PATH, "preview": PREVIEW_PATH})
