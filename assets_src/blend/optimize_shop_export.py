"""Batch the editable shop into a runtime GLB without mutating source objects."""

import bpy
import bmesh
import math
import os
import re
from mathutils import Vector


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
SOURCE_BLEND = os.path.join(ROOT, "assets_src/blend/shop_scene.blend")
SOURCE_GLB = os.path.join(ROOT, "assets_src/glb/shop_scene.glb")
RUNTIME_GLB = os.path.join(ROOT, "game/assets/glb/shop_scene.glb")
SEMANTIC_NODES = {"PD_Fascia_Base", "PD_JarFill_0", "PD_LampShade_0", "PD_MenuCup"}
RUNTIME_EXCLUDE_PREFIXES = (
    "PrepTier", "Menu", "PD_Menu", "Lamp", "PD_Lamp",
    "PD_Fascia", "PD_Stud", "PD_Logo", "Shelf", "Jar_", "JarLid_",
    "BackBar", "PD_BackBar", "PD_Jar",
    "DecoKettle", "DecoShaker", "DecoCups", "Frame",
    "SignFrame", "SignBoard",
)


def add_box(collection, groups, name, location, dimensions, material_name, bevel=0.02):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(bpy.data.materials[material_name])
    if bevel:
        modifier = obj.modifiers.new("SoftBevel", "BEVEL")
        modifier.width = min(bevel, min(dimensions) * 0.24)
        modifier.segments = 2
        modifier.limit_method = "ANGLE"
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    for owner in list(obj.users_collection):
        owner.objects.unlink(obj)
    collection.objects.link(obj)
    groups.setdefault(("material", (material_name,)), []).append(obj)


def add_curved_strip(collection, groups, name, center, dimensions, material_name,
                     curve_depth, curve_center_x=0.0, curve_radius=2.5, bevel=0.02):
    width, depth, height = dimensions
    x_min = center[0] - width * 0.5
    vertices = []
    segments = 18
    for index in range(segments + 1):
        x = x_min + width * index / segments
        offset = max(0.0, 1.0 - ((x - curve_center_x) / curve_radius) ** 2)
        y = center[1] - curve_depth * offset
        vertices.extend([
            (x, y - depth * 0.5, center[2] - height * 0.5),
            (x, y + depth * 0.5, center[2] - height * 0.5),
            (x, y - depth * 0.5, center[2] + height * 0.5),
            (x, y + depth * 0.5, center[2] + height * 0.5),
        ])
    faces = []
    for index in range(segments):
        a = index * 4
        b = a + 4
        faces.extend([
            (a + 1, b + 1, b, a),
            (b + 2, b + 3, a + 3, a + 2),
            (b, b + 2, a + 2, a),
            (a + 3, b + 3, b + 1, a + 1),
        ])
    last = segments * 4
    faces.extend([(2, 3, 1, 0), (last + 1, last + 3, last + 2, last)])
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    # Check before batching: glTF splits vertices at UV/normal seams.
    check = bmesh.new()
    check.from_mesh(mesh)
    assert all(edge.is_manifold and edge.is_contiguous for edge in check.edges), name
    assert check.calc_volume(signed=True) > 0, name + " has inward faces"
    check.free()
    uv_layer = mesh.uv_layers.new(name="UVMap")
    for polygon in mesh.polygons:
        for loop_index in polygon.loop_indices:
            vertex = mesh.vertices[mesh.loops[loop_index].vertex_index].co
            if abs(polygon.normal.z) > 0.5:
                uv_layer.data[loop_index].uv = (vertex.x * 0.4, vertex.y * 0.4)
            elif abs(polygon.normal.y) > 0.5:
                uv_layer.data[loop_index].uv = (vertex.x * 0.4, vertex.z * 0.4)
            else:
                uv_layer.data[loop_index].uv = (vertex.y * 0.4, vertex.z * 0.4)
    mesh.materials.append(bpy.data.materials[material_name])
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    if bevel:
        modifier = obj.modifiers.new("SoftBevel", "BEVEL")
        modifier.width = min(bevel, min(depth, height) * 0.24)
        modifier.segments = 2
        modifier.limit_method = "ANGLE"
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    normals = obj.modifiers.new("SurfaceNormals", "WEIGHTED_NORMAL")
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=normals.name)
    groups.setdefault(("material", (material_name,)), []).append(obj)


def refine_runtime_layout(obj, source_name):
    rail_points = {
        "RailPost0": (-1.34, -1.90), "RailPostCap0": (-1.34, -1.90),
        "RailPost1": (-1.86, -0.41), "RailPostCap1": (-1.86, -0.41),
        "RailPost2": (-2.44, 1.08), "RailPostCap2": (-2.44, 1.08),
    }
    if source_name in rail_points:
        obj.location.x, obj.location.y = rail_points[source_name]
    elif source_name in {"RailBar", "RailBarLow"}:
        front = Vector((-1.34, -1.90))
        back = Vector((-2.44, 1.08))
        delta = back - front
        obj.location.x = (front.x + back.x) * 0.5
        obj.location.y = (front.y + back.y) * 0.5
        obj.rotation_euler.z = math.atan2(front.x - back.x, back.y - front.y)
        obj.scale.z *= delta.length / 1.72


def safe_name(value):
    return re.sub(r"[^A-Za-z0-9_]+", "_", value)[:42]


def triangles(mesh):
    return sum(max(0, len(poly.vertices) - 2) for poly in mesh.polygons)


def build_export_collection():
    # The toon counter uses a matte color; Godot supplies the shared painted floor.
    # Strip the superseded color/roughness maps instead of keeping them resident in VRAM.
    for name, color in {"fine_grained_wood": (0.72, 0.62, 0.45, 1),
                        "grey_cartago_01": (0.70, 0.74, 0.72, 1)}.items():
        graph = bpy.data.materials[name].node_tree
        shader = next(node for node in graph.nodes if node.type == "BSDF_PRINCIPLED")
        for socket in ("Base Color", "Roughness", "Metallic", "Normal"):
            for link in list(shader.inputs[socket].links):
                graph.links.remove(link)
        shader.inputs["Base Color"].default_value = color
        shader.inputs["Roughness"].default_value = 0.9
        shader.inputs["Metallic"].default_value = 0.0
    temp = bpy.data.collections.new("EXPORT_ShopMobile")
    bpy.context.scene.collection.children.link(temp)
    groups = {}
    sources = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"
               and not obj.hide_render
               and obj.name != "CounterTop"
               and (obj.name in SEMANTIC_NODES
                    or not obj.name.startswith(RUNTIME_EXCLUDE_PREFIXES))]
    for source in sources:
        source_name = source.name
        semantic_name = source_name if source_name in SEMANTIC_NODES else ""
        obj = source.copy()
        obj.data = source.data.copy()
        obj.animation_data_clear()
        obj.parent = None
        obj.matrix_world = source.matrix_world.copy()
        refine_runtime_layout(obj, source_name)
        temp.objects.link(obj)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        # Apply bevel/geometry-node modifiers before objects are joined; otherwise
        # only the active object's modifier stack survives Blender's join operator.
        bpy.ops.object.convert(target="MESH")
        signature = tuple(material.name if material else "None" for material in obj.data.materials)
        if semantic_name:
            # The editable source currently occupies the exact object name. Rename
            # it only in this unsaved export session so the GLB node avoids `.001`;
            # reopening SOURCE_BLEND below restores the authored name immediately.
            source.name = "__EDITABLE_" + semantic_name
            key = ("semantic", semantic_name)
        else:
            key = ("material", signature)
        groups.setdefault(key, []).append(obj)

    add_box(temp, groups, "PD_CounterTop", (0.0, -0.475, 0.95),
            (3.80, 1.65, 0.06), "fine_grained_wood", 0.008)

    # 参考图的后场由奶油色柜体包住原料，而不是一条孤立的平板货架。
    # 复用店铺现有材质，补齐框架即可，不引入新的运行时系统或贴图。
    add_box(temp, groups, "PD_RearLintel", (0.0, 1.03, 1.55),
            (3.35, 0.18, 0.07), "PD_CreamHighlight", 0.018)
    add_box(temp, groups, "PD_RearBack", (0.0, 1.06, 1.29),
            (3.25, 0.08, 0.48), "CM_LightWood", 0.018)
    for index, x in enumerate((-1.62, -0.72, 0.76, 1.62)):
        add_box(temp, groups, "PD_RearDivider_%d" % index, (x, 1.03, 1.29),
                (0.07, 0.18, 0.58), "PD_CreamHighlight", 0.018)
    add_box(temp, groups, "PD_RearApron", (0.0, 0.52, 1.04),
            (3.30, 0.10, 0.20), "PD_CreamHighlight", 0.022)
    add_box(temp, groups, "PD_RearMintLip", (0.0, 0.46, 0.97),
            (3.18, 0.035, 0.035), "CM_Mint", 0.008)
    # 参考图前柜是横向贯通的三层轻柜体：奶油上沿、薄荷色带、浅木底座。
    # 保持同一前平面，避免偏右的大块深青嵌板改变整屏重心。
    front_mint = bpy.data.materials["PD_MintDark"].copy()
    front_mint.name = "PD_FrontMintBand"
    front_mint.node_tree.nodes.get("Principled BSDF").inputs["Base Color"].default_value = (0.09, 0.22, 0.25, 1.0)
    front_mint.node_tree.nodes.get("Principled BSDF").inputs["Roughness"].default_value = 0.68
    front_cream = bpy.data.materials["PD_CreamHighlight"].copy()
    front_cream.name = "PD_FrontCream"
    front_cream_bsdf = front_cream.node_tree.nodes.get("Principled BSDF")
    front_cream_bsdf.inputs["Base Color"].default_value = (1.0, 0.98, 0.92, 1.0)
    front_cream_bsdf.inputs["Roughness"].default_value = 0.72
    front_cream_bsdf.inputs["Emission Color"].default_value = (1.0, 0.94, 0.86, 1.0)
    front_cream_bsdf.inputs["Emission Strength"].default_value = 0.08
    add_curved_strip(temp, groups, "PD_FrontWoodTop", (0.75, -1.27, 0.955),
                     (4.75, 0.26, 0.025), "fine_grained_wood", 0.08, bevel=0.004)
    add_curved_strip(temp, groups, "PD_FrontCreamLip", (0.75, -1.25, 0.675),
                     (4.75, 0.055, 0.055), "PD_FrontCream", 0.08, bevel=0.004)
    add_curved_strip(temp, groups, "PD_FrontCreamApron", (0.75, -1.29, 0.575),
                     (4.73, 0.025, 0.15), "CM_LightWood", 0.08, bevel=0.0)
    add_curved_strip(temp, groups, "PD_FrontMintBand", (0.75, -1.32, 0.44),
                     (4.71, 0.035, 0.24), "PD_FrontMintBand", 0.08, bevel=0.018)
    add_curved_strip(temp, groups, "PD_FrontWoodSill", (0.75, -1.25, 0.245),
                     (4.79, 0.12, 0.24), "fine_grained_wood", 0.08, bevel=0.025)
    add_curved_strip(temp, groups, "PD_FrontWoodDeck", (0.75, -1.39, 0.165),
                     (4.79, 0.48, 0.08), "fine_grained_wood", 0.07, bevel=0.018)
    batch_index = 0
    for key, objects in groups.items():
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        if len(objects) > 1:
            bpy.ops.object.join()
        joined = objects[0]
        bpy.ops.object.material_slot_remove_unused()
        if key[0] == "semantic":
            joined.name = key[1]
        else:
            signature = key[1]
            label = "_".join(signature) if signature else "Unmaterialed"
            joined.name = "PD_Batch_%02d_%s" % (batch_index, safe_name(label))
            batch_index += 1
    return temp, len(sources)


def export_collection(collection):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in collection.objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = next(iter(collection.objects))
    for path in (SOURCE_GLB, RUNTIME_GLB):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True,
                                  export_apply=True, export_yup=True,
                                  export_materials="EXPORT", export_image_format="AUTO",
                                  use_active_scene=True)


if bpy.data.filepath != SOURCE_BLEND:
    bpy.ops.wm.open_mainfile(filepath=SOURCE_BLEND)
collection, source_meshes = build_export_collection()
export_meshes = len(collection.objects)
export_surfaces = sum(max(1, len(obj.data.materials)) for obj in collection.objects)
export_triangles = sum(triangles(obj.data) for obj in collection.objects)
export_collection(collection)
print({"source_meshes": source_meshes, "runtime_meshes": export_meshes,
       "runtime_surfaces": export_surfaces, "triangles": export_triangles,
       "runtime_glb": RUNTIME_GLB})
# Reopen the editable source so Blender returns to a clean, non-destructive state.
bpy.ops.wm.open_mainfile(filepath=SOURCE_BLEND)
