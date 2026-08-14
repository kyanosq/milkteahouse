import bpy
import math
import os


BLEND_PATH = "/Users/apple/Code/milkteahouse/assets_src/blend/props_hd.blend"
SRC_DIR = "/Users/apple/Code/milkteahouse/assets_src/glb"
RUNTIME_DIR = "/Users/apple/Code/milkteahouse/game/assets/glb"


def ensure_material(name, rgb, rough=0.45, metallic=0.0, alpha=1.0, transmission=0.0):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*rgb, alpha)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Alpha"].default_value = alpha
    if "Transmission Weight" in bsdf.inputs:
        bsdf.inputs["Transmission Weight"].default_value = transmission
    elif "Transmission" in bsdf.inputs:
        bsdf.inputs["Transmission"].default_value = transmission
    if alpha < 1.0:
        try:
            mat.surface_render_method = "DITHERED"
        except Exception:
            pass
        mat.diffuse_color = (*rgb, alpha)
    return mat


def ensure_vertex_material(name, rough=0.40):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = rough
    vertex = nodes.get("DecorVertexColor")
    if vertex is None:
        vertex = nodes.new("ShaderNodeVertexColor")
        vertex.name = "DecorVertexColor"
    vertex.layer_name = "DecorColor"
    for link in list(bsdf.inputs["Base Color"].links):
        links.remove(link)
    links.new(vertex.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


def paint_vertex_color(obj, rgb):
    colors = obj.data.color_attributes.get("DecorColor")
    if colors is None:
        colors = obj.data.color_attributes.new(
            name="DecorColor", type="BYTE_COLOR", domain="CORNER")
    rgba = (*rgb, 1.0)
    for item in colors.data:
        if hasattr(item, "color_srgb"):
            item.color_srgb = rgba
        else:
            item.color = rgba
    return obj


def reset_collection(name):
    old = bpy.data.collections.get(name)
    if old:
        for obj in list(old.objects):
            bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.collections.remove(old)
    col = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(col)
    return col


def move_to(obj, col):
    for old in list(obj.users_collection):
        old.objects.unlink(obj)
    col.objects.link(obj)
    return obj


def finish(obj, name, mat, col, bevel=0.0):
    obj.name = name
    obj.data.materials.append(bpy.data.materials[mat])
    for poly in obj.data.polygons:
        poly.use_smooth = True
    if bevel:
        mod = obj.modifiers.new("SoftBevel", "BEVEL")
        mod.width = bevel
        mod.segments = 3
        mod.limit_method = "ANGLE"
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return move_to(obj, col)


def sphere(name, loc, scale, mat, col):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, location=loc)
    obj = bpy.context.object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, mat, col)


def sphere_low(name, loc, scale, mat, col, segments=16, rings=8):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=loc)
    obj = bpy.context.object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, mat, col)


def cylinder(name, loc, radius, depth, mat, col, rot=(0, 0, 0), bevel=0.002, vertices=48):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth,
                                       location=loc, rotation=rot)
    return finish(bpy.context.object, name, mat, col, bevel)


def cone(name, loc, r1, r2, depth, mat, col, rot=(0, 0, 0), vertices=64):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=r1, radius2=r2, depth=depth,
                                   location=loc, rotation=rot)
    return finish(bpy.context.object, name, mat, col, 0.0015)


def cube(name, loc, dims, mat, col, bevel=0.01):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    obj = bpy.context.object
    obj.dimensions = dims
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, mat, col, min(bevel, min(dims) * 0.2))


def torus(name, loc, major, minor, mat, col, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor,
                                    major_segments=64, minor_segments=16,
                                    location=loc, rotation=rot)
    return finish(bpy.context.object, name, mat, col)


def torus_low(name, loc, major, minor, mat, col, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor,
                                    major_segments=20, minor_segments=6,
                                    location=loc, rotation=rot)
    return finish(bpy.context.object, name, mat, col)


def tube(name, points, radius, mat, col):
    curve = bpy.data.curves.new(name + "Curve", "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 3
    curve.bevel_depth = radius
    curve.bevel_resolution = 4
    spline = curve.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for point, co in zip(spline.bezier_points, points):
        point.co = co
        point.handle_left_type = "AUTO"
        point.handle_right_type = "AUTO"
    obj = bpy.data.objects.new(name, curve)
    col.objects.link(obj)
    curve.materials.append(bpy.data.materials[mat])
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


def join_named(objects, name):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    objects[0].name = name
    return objects[0]


def build_customer():
    col = reset_collection("CustomerHD")
    skin = "Skin"
    hair = "HairMint"
    lavender = "Lavender"
    for args in [
        (skin, (1.0, 0.73, 0.60), 0.52),
        (hair, (0.17, 0.70, 0.66), 0.40),
        (lavender, (0.59, 0.43, 0.78), 0.52),
        ("Cheek", (1.0, 0.45, 0.43), 0.55),
        ("White", (0.98, 0.96, 0.90), 0.48),
    ]:
        ensure_material(*args)

    # Feet and legs keep a grounded 0.72 m silhouette.
    sphere("Shoe_L", (-0.075, -0.015, 0.045), (0.065, 0.085, 0.040), "Mint", col)
    sphere("Shoe_R", (0.075, -0.015, 0.045), (0.065, 0.085, 0.040), "Mint", col)
    cylinder("Leg_L", (-0.070, 0, 0.115), 0.040, 0.105, skin, col, bevel=0.006)
    cylinder("Leg_R", (0.070, 0, 0.115), 0.040, 0.105, skin, col, bevel=0.006)
    cube("Shorts", (0, 0.010, 0.185), (0.235, 0.155, 0.135), "Cream", col, 0.025)
    cube("Body", (0, 0.005, 0.310), (0.245, 0.160, 0.190), lavender, col, 0.045)

    # A-pose limbs are separate and directly tintable by shop_stage.gd.
    cylinder("Arm_L", (-0.143, 0, 0.300), 0.043, 0.190, lavender, col,
             rot=(0, math.radians(-5), 0), bevel=0.006)
    cylinder("Arm_R", (0.143, 0, 0.300), 0.043, 0.190, lavender, col,
             rot=(0, math.radians(5), 0), bevel=0.006)
    sphere("Hand_L", (-0.151, -0.005, 0.202), (0.045, 0.043, 0.047), skin, col)
    sphere("Hand_R", (0.151, -0.005, 0.202), (0.045, 0.043, 0.047), skin, col)

    # Face projects slightly forward so the hair cap never masks it.
    sphere("Head", (0, -0.018, 0.540), (0.166, 0.145, 0.154), skin, col)
    hair_parts = [sphere("HairBack", (0, 0.065, 0.565), (0.174, 0.100, 0.160), hair, col)]
    for idx, x in enumerate((-0.105, -0.055, 0.0, 0.055, 0.105)):
        hair_parts.append(sphere("Bang_%d" % idx, (x, -0.132, 0.624),
                                 (0.045, 0.027, 0.073), hair, col))
    join_named(hair_parts, "Hair")

    sphere("Eye_L", (-0.058, -0.151, 0.550), (0.019, 0.010, 0.027), "Black", col)
    sphere("Eye_R", (0.058, -0.151, 0.550), (0.019, 0.010, 0.027), "Black", col)
    sphere("Cheek_L", (-0.100, -0.151, 0.510), (0.026, 0.007, 0.015), "Cheek", col)
    sphere("Cheek_R", (0.100, -0.151, 0.510), (0.026, 0.007, 0.015), "Cheek", col)
    tube("Mouth", [(-0.021, -0.155, 0.505), (0, -0.162, 0.495),
                   (0.021, -0.155, 0.505)], 0.004, "Black", col)

    # Sunglasses are a signature silhouette; frames sit above the bangs.
    torus("Glasses_L", (-0.064, -0.132, 0.680), 0.036, 0.006, "White", col,
          rot=(math.radians(90), 0, 0))
    torus("Glasses_R", (0.064, -0.132, 0.680), 0.036, 0.006, "White", col,
          rot=(math.radians(90), 0, 0))
    cube("GlassesBridge", (0, -0.137, 0.680), (0.040, 0.010, 0.010), "White", col, 0.003)
    return col


def build_cup():
    col = reset_collection("MilkTeaCupHD")
    ensure_material("CupGlass", (0.90, 0.97, 0.98), 0.10, alpha=0.22, transmission=0.72)
    ensure_material("Tea", (0.48, 0.24, 0.10), 0.30)
    ensure_material("Milk", (0.96, 0.85, 0.67), 0.34)
    ensure_material("StrawMint", (0.15, 0.75, 0.69), 0.30)
    ensure_material("CupCream", (1.00, 0.95, 0.85), 0.42)
    ensure_material("CupCoral", (1.00, 0.31, 0.27), 0.36)
    ensure_material("CupMint", (0.09, 0.64, 0.57), 0.34)
    ensure_vertex_material("CupDecorVertex", 0.38)
    ensure_material("Seal", (0.94, 0.98, 0.98), 0.16, metallic=0.10, alpha=0.58)
    ensure_material("SealCoral", (1.00, 0.31, 0.27), 0.20,
                    metallic=0.05, alpha=0.62)

    cup_shell = [
        cone("Cup", (0, 0, 0.082), 0.032, 0.043, 0.164,
             "CupGlass", col, vertices=32),
        torus_low("CupRim", (0, 0, 0.166), 0.043, 0.0028,
                  "CupGlass", col),
        cylinder("CupFoot", (0, 0, 0.003), 0.033, 0.006,
                 "CupGlass", col, bevel=0.001, vertices=24),
    ]
    join_named(cup_shell, "Cup")
    cone("LiquidTea", (0, 0, 0.066), 0.029, 0.037, 0.120, "Tea", col, vertices=32)
    cone("LiquidMilk", (0, 0, 0.135), 0.037, 0.040, 0.030, "Milk", col, vertices=32)
    # CupRig only needs one source pearl mesh; it creates the visible physics
    # instances itself.  Keeping eight identical seeds wasted import geometry.
    sphere_low("Pearl_00", (0, 0, 0.018), (0.007, 0.007, 0.007),
               "Cocoa", col, segments=12, rings=6)

    # Printed sleeve gives the tiny gameplay cup a strong shop identity without
    # covering the recipe-driven liquid above and below it.
    brand_parts = [
        paint_vertex_color(
            cone("BrandBand", (0, 0, 0.095), 0.0376, 0.0401, 0.034,
                 "CupDecorVertex", col, vertices=32),
            (1.00, 0.95, 0.85)),
        paint_vertex_color(
            torus_low("BrandBandLow", (0, 0, 0.078), 0.0376, 0.00135,
                      "CupDecorVertex", col),
            (1.00, 0.31, 0.27)),
        paint_vertex_color(
            torus_low("BrandBandHigh", (0, 0, 0.112), 0.0401, 0.00135,
                      "CupDecorVertex", col),
            (1.00, 0.31, 0.27)),
        paint_vertex_color(
            cylinder("BrandBadge", (0, -0.0410, 0.095), 0.0135, 0.0022,
                     "CupDecorVertex", col, rot=(math.radians(90), 0, 0),
                     bevel=0.0007, vertices=24),
            (1.00, 0.31, 0.27)),
    ]
    leaf_a = sphere_low("BrandLeaf_A", (-0.0038, -0.0425, 0.0965),
                        (0.0040, 0.0014, 0.0074), "CupDecorVertex", col,
                        segments=12, rings=6)
    paint_vertex_color(leaf_a, (1.00, 0.95, 0.85))
    leaf_a.rotation_euler[1] = math.radians(-28)
    brand_parts.append(leaf_a)
    leaf_b = sphere_low("BrandLeaf_B", (0.0038, -0.0425, 0.0935),
                        (0.0040, 0.0014, 0.0074), "CupDecorVertex", col,
                        segments=12, rings=6)
    paint_vertex_color(leaf_b, (0.09, 0.64, 0.57))
    leaf_b.rotation_euler[1] = math.radians(-28)
    brand_parts.append(leaf_b)
    # Vertex color keeps the three-color badge in one material surface.
    join_named(brand_parts, "BrandWrap")

    straw_rot = (0, math.radians(-8), 0)
    straw_center = (0.014, 0, 0.205)
    straw_parts = [paint_vertex_color(
        cylinder("Straw", straw_center, 0.005, 0.155, "CupDecorVertex", col,
                 rot=straw_rot, bevel=0.0, vertices=16),
        (0.15, 0.75, 0.69))]
    # Short coral collars read as a striped straw at gameplay scale.  Their
    # centres follow the tilted straw axis so no segment floats beside it.
    for idx, offset in enumerate((-0.052, -0.018, 0.018, 0.052)):
        x = straw_center[0] + math.sin(straw_rot[1]) * offset
        z = straw_center[2] + math.cos(straw_rot[1]) * offset
        straw_parts.append(paint_vertex_color(
            cylinder("StrawAccent_%d" % idx, (x, 0, z), 0.00535, 0.011,
                     "CupDecorVertex", col, rot=straw_rot,
                     bevel=0.0, vertices=16),
            (1.00, 0.31, 0.27)))
    join_named(straw_parts, "Straw")
    film_parts = [
        cylinder("SealFilm", (0, 0, 0.169), 0.0435, 0.0022, "SealCoral", col,
                 bevel=0.0005, vertices=32),
        torus_low("SealFilmRing", (0, 0, 0.1702), 0.0416, 0.0015,
                  "SealCoral", col),
    ]
    join_named(film_parts, "SealFilm")
    return col


def export(col, filename):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in col.objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = col.objects[0]
    for folder in (SRC_DIR, RUNTIME_DIR):
        os.makedirs(folder, exist_ok=True)
        bpy.ops.export_scene.gltf(filepath=os.path.join(folder, filename),
                                  export_format="GLB", use_selection=True,
                                  export_apply=True, export_yup=True,
                                  export_materials="EXPORT")


cup = build_cup()
export(cup, "milk_tea_cup.glb")
bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH)
print({"cup_objects": len(cup.objects)})
