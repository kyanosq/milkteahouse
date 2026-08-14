"""Batch the editable shop into a runtime GLB without mutating source objects."""

import bpy
import os
import re


SOURCE_BLEND = "/Users/apple/Code/milkteahouse/assets_src/blend/shop_scene.blend"
SOURCE_GLB = "/Users/apple/Code/milkteahouse/assets_src/glb/shop_scene.glb"
RUNTIME_GLB = "/Users/apple/Code/milkteahouse/game/assets/glb/shop_scene.glb"
SEMANTIC_NODES = {"PD_Fascia_Base", "PD_JarFill_0", "PD_LampShade_0", "PD_MenuCup"}


def safe_name(value):
    return re.sub(r"[^A-Za-z0-9_]+", "_", value)[:42]


def triangles(mesh):
    return sum(max(0, len(poly.vertices) - 2) for poly in mesh.polygons)


def build_export_collection():
    temp = bpy.data.collections.new("EXPORT_ShopMobile")
    bpy.context.scene.collection.children.link(temp)
    groups = {}
    sources = [obj for obj in bpy.context.scene.objects if obj.type == "MESH" and not obj.hide_render]
    for source in sources:
        source_name = source.name
        semantic_name = source_name if source_name in SEMANTIC_NODES else ""
        obj = source.copy()
        obj.data = source.data.copy()
        obj.animation_data_clear()
        obj.parent = None
        obj.matrix_world = source.matrix_world.copy()
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
