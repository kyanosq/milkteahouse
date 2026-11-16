"""Build detailed matte chibi skins with baked skeletal clips.

blender --background --python assets_src/blend/build_customer_walk.py
Walk travels 0.36 m per cycle; the game samples it by distance travelled.
Set CHARACTER_ROLE=barista|xiaoman|taozi|acheng to build a staff Work/Idle skin.
"""
import bpy
import math
import os
import runpy
from mathutils import Vector, Quaternion, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "../.."))
ROLE = os.environ.get("CHARACTER_ROLE", "customer")
STAFF = ROLE != "customer"
ASSET = "staff_" + ROLE if STAFF else "customer_walk"
helpers = runpy.run_path(os.path.join(HERE, "build_customer_classic_mobile.py"))
helpers["reset"]()
helpers["make_materials"]()
col = bpy.data.collections.new("WalkingCustomer")
bpy.context.scene.collection.children.link(col)
bindings = {}

# Cloth, hair and skin use matte base colors; Godot supplies the shared toon light rig.
palette = {"Skin": "F6D7BD", "HairMint": "8ABAB4", "Lavender": "A296C6",
           "Mint": "608F88", "Cream": "F5F0DF", "Cheek": "EBAFA8",
           "White": "FAFAEC", "Black": "35444A"}
if STAFF:
    palette.update({"HairMint": {"taozi": "9B5E56", "acheng": "434F60"}.get(ROLE, "655746"),
                    "Lavender": "F1EFE3", "Mint": {"taozi": "C98276", "acheng": "667A9B"}.get(ROLE, "61998C")})
for name, hex_color in palette.items():
    srgb = [int(hex_color[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    rgba = tuple(v / 12.92 if v < 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in srgb) + (1,)
    mat = bpy.data.materials[name]
    mat.diffuse_color = rgba
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = rgba
    bsdf.inputs["Roughness"].default_value = 0.9
    bsdf.inputs["Specular IOR Level"].default_value = 0.0


def part(name, position, size, material, bone, segments=20, rings=10):
    obj = helpers["sphere"](name, position, size, material, col, segments, rings)
    bindings[obj.name] = bone
    return obj


def surface(name, vertices, faces, material, bone):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    col.objects.link(obj)
    obj.data.materials.append(bpy.data.materials[material])
    for polygon in mesh.polygons:
        polygon.use_smooth = True
    bindings[obj.name] = bone
    return obj


def line(name, points, radius, material, bone):
    obj = helpers["tube"](name, points, radius, material, col)
    bindings[obj.name] = bone
    return obj


def box(name, position, size, material, bone, bevel=0.005):
    obj = helpers["cube"](name, position, size, material, col, bevel)
    bindings[obj.name] = bone
    return obj


def lock(name, sections, material="HairMint"):
    # Elliptical sections give individual tapered hair locks a continuous surface.
    vertices = [(x + w * math.cos(i * math.tau / 12), y + d * math.sin(i * math.tau / 12), z)
                for x, y, z, w, d in sections for i in range(12)]
    faces = [tuple(reversed(range(12))), tuple(range(len(vertices) - 12, len(vertices)))]
    for ring in range(len(sections) - 1):
        a = ring * 12
        faces += [(a + i, a + (i + 1) % 12, a + (i + 1) % 12 + 12, a + i + 12) for i in range(12)]
    # Sections run from crown to tip; outward winding follows that order.
    return surface(name, vertices, [tuple(reversed(face)) for face in faces], material, "Head")


profile = [(0.285, 0.105, 0.078), (0.305, 0.122, 0.089), (0.350, 0.133, 0.099),
           (0.400, 0.129, 0.094), (0.477, 0.141, 0.094), (0.517, 0.108, 0.076),
           (0.548, 0.054, 0.047)]
vertices = [(w * math.cos(i * math.tau / 32), 0.005 + d * math.sin(i * math.tau / 32), z)
            for z, w, d in profile for i in range(32)]
faces = [tuple(reversed(range(32))), tuple(range(len(vertices) - 32, len(vertices)))]
for ring in range(len(profile) - 1):
    a = ring * 32
    faces += [(a + i, a + (i + 1) % 32, a + (i + 1) % 32 + 32, a + i + 32) for i in range(32)]
surface("TailoredShirt", vertices, faces, "Lavender", "Spine")
part("Shorts", (0, 0.005, 0.300), (0.126, 0.096, 0.070), "Cream", "Hips")
part("Neck", (0, 0, 0.586), (0.052, 0.047, 0.053), "Skin", "Spine")
head = part("Head", (0, -0.012, 0.718), (0.175, 0.147, 0.168), "Skin", "Head", 32, 16)
for vertex in head.data.vertices:
    vertex.co.x *= 1.0 - max(0, -vertex.co.z / 0.168) * 0.13
part("Nose", (0, -0.162, 0.697), (0.013, 0.017, 0.015), "Skin", "Head", 12, 6)

for side, x in [("L", -1), ("R", 1)]:
    part("Thigh_" + side, (x * 0.073, 0, 0.250), (0.045, 0.045, 0.083), "Skin", "Thigh_" + side)
    part("Knee_" + side, (x * 0.073, 0, 0.180), (0.036, 0.036, 0.036), "Skin", "Thigh_" + side, 16, 8)
    part("Shin_" + side, (x * 0.073, 0, 0.110), (0.035, 0.036, 0.083), "Skin", "Shin_" + side)
    part("Shoe_" + side, (x * 0.073, -0.028, 0.040), (0.054, 0.083, 0.040), "Cream", "Foot_" + side)
    part("Sole_" + side, (x * 0.073, -0.030, 0.012), (0.055, 0.082, 0.012), "Mint", "Foot_" + side)
    part("Sleeve_" + side, (x * 0.160, 0, 0.467), (0.047, 0.047, 0.070), "Lavender", "Arm_" + side)
    part("Cuff_" + side, (x * 0.175, 0, 0.413), (0.035, 0.038, 0.012), "Cream", "Arm_" + side)
    part("Forearm_" + side, (x * 0.182, -0.004, 0.372), (0.031, 0.033, 0.057), "Skin", "Forearm_" + side)
    part("Hand_" + side, (x * 0.186, -0.010, 0.327), (0.035, 0.034, 0.038), "Skin", "Forearm_" + side)
    part("Thumb_" + side, (x * 0.157, -0.030, 0.336), (0.015, 0.021, 0.024), "Skin", "Forearm_" + side, 12, 6)
    part("Ear_" + side, (x * 0.167, -0.002, 0.700), (0.025, 0.018, 0.036), "Skin", "Head", 16, 8)
    part("EyeWhite_" + side, (x * 0.061, -0.151, 0.721), (0.025, 0.009, 0.033), "White", "Head", 16, 8)
    part("Eye_" + side, (x * 0.061, -0.159, 0.721), (0.018, 0.008, 0.028), "Black", "Head", 16, 8)
    part("Iris_" + side, (x * 0.061, -0.166, 0.713), (0.012, 0.003, 0.014), "Mint", "Head", 12, 6)
    part("EyeLight_" + side, (x * 0.061 - 0.005, -0.168, 0.733), (0.006, 0.003, 0.008), "White", "Head", 8, 4)
    part("Cheek_" + side, (x * 0.106, -0.139, 0.682), (0.022, 0.004, 0.011), "Cheek", "Head", 12, 6)
    line("Brow_" + side, [(x * 0.083, -0.145, 0.769), (x * 0.061, -0.157, 0.774),
                          (x * 0.039, -0.152, 0.769)], 0.003, "HairMint", "Head")
    surface("Collar_" + side, [(x * 0.005, -0.054, 0.549), (x * 0.053, -0.043, 0.549),
                              (x * 0.072, -0.086, 0.514), (x * 0.033, -0.096, 0.493)],
            [(0, 1, 2, 3)] if x == -1 else [(3, 2, 1, 0)], "Cream", "Spine")
    line("ShoeSeam_" + side, [(x * 0.073 - 0.025, -0.091, 0.042),
                             (x * 0.073, -0.109, 0.042), (x * 0.073 + 0.025, -0.091, 0.042)],
         0.002, "Mint", "Foot_" + side)
for index in range(3):
    part("ShirtButton_%d" % index, (0, -0.093, 0.478 - index * 0.048),
         (0.006, 0.004, 0.006), "Cream", "Spine", 8, 4)
mouth = helpers["tube"]("Smile", [(-0.020, -0.159, 0.682), (0, -0.161, 0.675),
                                  (0.020, -0.159, 0.682)], 0.003, "Black", col)
bindings[mouth.name] = "Head"

# One continuous bob cap, with a higher forehead opening and rounded lower edge.
vertices = [(0, -0.005, 0.914)]
segments, rings = 32, 10
for ring in range(1, rings + 1):
    for index in range(segments):
        phi = math.tau * index / segments
        front = max(0, -math.sin(phi)) ** 1.6
        theta = (2.30 - 1.04 * front) * ring / rings
        vertices.append((0.189 * math.sin(theta) * math.cos(phi),
                         -0.005 + 0.174 * math.sin(theta) * math.sin(phi),
                         0.731 + 0.183 * math.cos(theta)))
faces = [(0, 1 + i, 1 + (i + 1) % segments) for i in range(segments)]
for ring in range(rings - 1):
    a = 1 + ring * segments
    faces += [(a + i, a + segments + i, a + segments + (i + 1) % segments,
               a + (i + 1) % segments) for i in range(segments)]
mesh = bpy.data.meshes.new("BobCap")
mesh.from_pydata(vertices, [], faces)
mesh.update()
hair = bpy.data.objects.new("Hair", mesh)
col.objects.link(hair)
hair.data.materials.append(bpy.data.materials["HairMint"])
for polygon in mesh.polygons:
    polygon.use_smooth = True
bpy.context.view_layer.objects.active = hair
hair.select_set(True)
shell = hair.modifiers.new("HairThickness", "SOLIDIFY")
shell.thickness = 0.010
bpy.ops.object.modifier_apply(modifier=shell.name)
bindings[hair.name] = "Head"
for index, x in enumerate((-0.13, -0.077, -0.020, 0.040, 0.101)):
    lock("Fringe_%d" % index, [(x * 0.68, -0.082, 0.899, 0.023, 0.014),
         (x * 0.80, -0.121, 0.878, 0.038, 0.019), (x * 0.9, -0.145, 0.852, 0.043, 0.018),
         (x, -0.172, 0.809, 0.036, 0.015), (x - 0.006, -0.181, 0.788, 0.024, 0.010),
         (x - 0.021, -0.184, 0.768 + abs(x) * 0.15, 0.002, 0.002)])
for side in (-1, 1):
    lock("SideLock_%d" % side, [(side * 0.142, -0.030, 0.858, 0.027, 0.024),
         (side * 0.177, -0.039, 0.777, 0.025, 0.029), (side * 0.165, -0.022, 0.655, 0.006, 0.005)])

if STAFF:
    # Curved apron panels sit above the shirt, with an actual pocket, straps and necktie.
    apron_rows = [(0.286, 0.120, -0.096), (0.350, 0.133, -0.105),
                  (0.405, 0.128, -0.102), (0.460, 0.090, -0.106), (0.493, 0.071, -0.101)]
    vertices = [(w * i / 4, y + 0.035 * (i / 4) ** 2, z) for z, w, y in apron_rows for i in range(-4, 5)]
    faces = [(r * 9 + i, r * 9 + i + 1, (r + 1) * 9 + i + 1, (r + 1) * 9 + i)
             for r in range(4) for i in range(8)]
    surface("Apron", vertices, faces, "Mint", "Spine")
    box("ApronPocket", (0, -0.108, 0.357), (0.086, 0.011, 0.045), "Mint", "Spine")
    line("PocketPiping", [(-0.043, -0.116, 0.378), (0, -0.117, 0.377), (0.043, -0.116, 0.378)],
         0.002, "Cream", "Spine")
    for side in (-1, 1):
        line("ApronStrap_%d" % side, [(side * 0.070, -0.096, 0.491), (side * 0.100, -0.053, 0.523),
             (side * 0.092, 0.010, 0.536), (side * 0.090, 0.075, 0.482)], 0.008, "Mint", "Spine")
        part("Bow_%d" % side, (side * 0.018, -0.105, 0.518), (0.018, 0.009, 0.015), "Mint", "Spine", 12, 6)
    box("NameBadge", (0.039, -0.107, 0.467), (0.037, 0.008, 0.017), "Cream", "Spine", 0.002)
    if ROLE in ("xiaoman", "barista"):
        part("ClothCap", (0, -0.015, 0.880), (0.174, 0.165, 0.070), "Mint", "Head", 24, 12)
        part("CapBrim", (0, -0.155, 0.862), (0.143, 0.084, 0.016), "Mint", "Head", 24, 8)
        part("CapBadge", (0, -0.167, 0.906), (0.023, 0.005, 0.023), "Cream", "Head", 12, 6)
    elif ROLE == "taozi":
        lock("Ponytail", [(0.115, 0.116, 0.899, 0.034, 0.034), (0.156, 0.131, 0.826, 0.069, 0.055),
             (0.176, 0.116, 0.711, 0.044, 0.039), (0.155, 0.089, 0.637, 0.006, 0.006)])
        part("HairTie", (0.123, 0.115, 0.875), (0.038, 0.037, 0.014), "Mint", "Head", 16, 8)
        for side in (-1, 1):
            part("Earring_%d" % side, (side * 0.175, -0.016, 0.677), (0.008, 0.008, 0.010), "Cream", "Head", 8, 4)
    elif ROLE == "acheng":
        for side in (-1, 1):
            points = [(side * 0.061 + 0.038 * math.cos(i * math.tau / 16), -0.174,
                       0.722 + 0.040 * math.sin(i * math.tau / 16)) for i in range(17)]
            line("Glasses_%d" % side, points, 0.003, "Black", "Head")
        line("GlassesBridge", [(-0.023, -0.174, 0.727), (0, -0.179, 0.733), (0.023, -0.174, 0.727)], 0.003, "Black", "Head")
    # A small work cup follows the hand bone in the preparation clip.
    cup = helpers["cylinder"]("WorkCup", (0.186, -0.053, 0.311), 0.029, 0.080, "Cream", col, vertices=24)
    bindings[cup.name] = "Forearm_R"
    lid = helpers["cylinder"]("WorkLid", (0.186, -0.053, 0.353), 0.031, 0.009, "Mint", col, vertices=24)
    bindings[lid.name] = "Forearm_R"
    line("WorkStraw", [(0.185, -0.053, 0.352), (0.185, -0.053, 0.409)], 0.003, "Mint", "Forearm_R")

armature = bpy.data.armatures.new("CustomerSkeleton")
rig = bpy.data.objects.new("CustomerRig", armature)
col.objects.link(rig)
bpy.ops.object.select_all(action="DESELECT")
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")


def bone(name, head, tail, parent=None):
    result = armature.edit_bones.new(name)
    result.head, result.tail = head, tail
    if parent:
        result.parent = armature.edit_bones[parent]


bone("Hips", (0, 0, 0.320), (0, 0, 0.410))
bone("Spine", (0, 0, 0.410), (0, 0, 0.586), "Hips")
bone("Head", (0, 0, 0.586), (0, 0, 0.840), "Spine")
for side, x in [("L", -1), ("R", 1)]:
    bone("Thigh_" + side, (x * 0.073, 0, 0.320), (x * 0.073, 0, 0.180), "Hips")
    bone("Shin_" + side, (x * 0.073, 0, 0.180), (x * 0.073, 0, 0.040), "Thigh_" + side)
    bone("Foot_" + side, (x * 0.073, 0, 0.040), (x * 0.073, -0.080, 0.040), "Shin_" + side)
    bone("Arm_" + side, (x * 0.151, 0, 0.515), (x * 0.180, 0, 0.402), "Spine")
    bone("Forearm_" + side, (x * 0.180, 0, 0.402), (x * 0.186, -0.010, 0.327), "Arm_" + side)
bpy.ops.object.mode_set(mode="OBJECT")

for obj in list(col.objects):
    if obj.type != "MESH":
        continue
    group = obj.vertex_groups.new(name=bindings[obj.name])
    group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    modifier = obj.modifiers.new("Skin", "ARMATURE")
    modifier.object = rig
    obj.parent = rig

# Batch by material without losing bone weights; both runtime colors use this skin.
groups = {}
for obj in list(col.objects):
    if obj.type == "MESH":
        groups.setdefault(obj.data.materials[0].name, []).append(obj)
for material, objects in groups.items():
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    objects[0].name = "Body" if STAFF and material == "Lavender" else material

rig.animation_data_create()
fps = 24
bpy.context.scene.render.fps = fps


def set_leg(side, foot_y, foot_z, hip_z):
    x = -0.073 if side == "L" else 0.073
    dy, dz = foot_y, hip_z - foot_z
    distance = math.hypot(dy, dz)
    assert distance < 0.280, "stride exceeds leg reach"
    upper = math.atan2(-dy, dz) + math.acos(distance / 0.280)
    lower = upper - 2 * math.acos(distance / 0.280)
    knee = Vector((x, -0.140 * math.sin(upper), hip_z - 0.140 * math.cos(upper)))
    for name, head, angle in [("Thigh_" + side, Vector((x, 0, hip_z)), -upper),
                              ("Shin_" + side, knee, -lower),
                              ("Foot_" + side, Vector((x, foot_y, foot_z)), 0)]:
        rest = armature.bones[name].matrix_local.to_quaternion()
        matrix = (Quaternion((1, 0, 0), angle) @ rest).to_matrix().to_4x4()
        matrix.translation = head
        rig.pose.bones[name].matrix = matrix
        bpy.context.view_layer.update()


for clip, duration in ([("Work", 1.5), ("Idle", 3)] if STAFF else [("Walk", 1), ("Idle", 3)]):
    action = bpy.data.actions.new(clip)
    rig.animation_data.action = action
    for frame in range(int(fps * duration) + 1):
        phase = frame / (fps * duration)
        bpy.context.scene.frame_set(frame)
        for pose in rig.pose.bones:
            pose.matrix_basis = Matrix.Identity(4)
            pose.rotation_mode = "QUATERNION"
        hip_z = (0.290 + 0.004 * math.cos(phase * math.tau * 2) if clip == "Walk"
                 else 0.315 + 0.002 * math.cos(phase * math.tau))
        hips = armature.bones["Hips"].matrix_local.copy()
        hips.translation.z = hip_z
        rig.pose.bones["Hips"].matrix = hips
        rig.pose.bones["Head"].rotation_quaternion = Quaternion((1, 0, 0), math.radians(-12))
        bpy.context.view_layer.update()
        for side, offset in [("L", 0), ("R", 0.5)]:
            p = (phase + offset) % 1
            y, lift = 0.0, 0.0
            if clip == "Walk":
                if p < 0.6:
                    y = -0.108 + p * 0.36
                else:
                    swing = (p - 0.6) / 0.4
                    y = 0.108 * math.cos(math.pi * swing)
                    lift = 0.050 * math.sin(math.pi * swing)
            set_leg(side, y, 0.040 + lift, hip_z)
            pose = rig.pose.bones["Arm_" + side]
            pose.rotation_quaternion = Quaternion((1, 0, 0),
                -2.6 * y if clip == "Walk" else 0.03)
            rig.pose.bones["Forearm_" + side].rotation_quaternion = Quaternion((1, 0, 0), -0.12)
            if clip == "Work":
                beat = math.sin(phase * math.tau)
                pose.rotation_quaternion = Quaternion((1, 0, 0), -0.65 + 0.10 * beat)
                rig.pose.bones["Forearm_" + side].rotation_quaternion = Quaternion((1, 0, 0),
                    -0.72 + (0.15 if side == "R" else -0.08) * beat)
        for pose in rig.pose.bones:
            pose.keyframe_insert("location", frame=frame, group=pose.name)
            pose.keyframe_insert("rotation_quaternion", frame=frame, group=pose.name)
    track = rig.animation_data.nla_tracks.new()
    track.name = clip
    track.strips.new(clip, 0, action)
    rig.animation_data.action = None

for track in rig.animation_data.nla_tracks:
    track.mute = track.name != "Idle"
bpy.context.scene.frame_set(0)
os.makedirs(os.path.join(ROOT, "assets_src/glb"), exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, ASSET + ".blend"))
for track in rig.animation_data.nla_tracks:
    track.mute = False
bpy.ops.object.select_all(action="DESELECT")
for obj in col.objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active = rig
for folder in ("assets_src/glb", "game/assets/glb"):
    bpy.ops.export_scene.gltf(filepath=os.path.join(ROOT, folder, ASSET + ".glb"),
        export_format="GLB", use_selection=True, export_yup=True,
        export_animations=True, export_animation_mode="NLA_TRACKS",
        export_force_sampling=True, export_frame_range=False)
print("[CHARACTER] role=%s skinned meshes=%d bones=%d" % (ROLE, len(groups), len(armature.bones)))
