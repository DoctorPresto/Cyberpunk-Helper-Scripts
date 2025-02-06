                                 # by The Magnificent Doctor Presto August 4 2023
                            # https://github.com/DoctorPresto/Cyberpunk-Helper-Scripts                       
          # /$$                               /$$                                          /$$            /$$$$$$                       
         # | $$                              |__/                                         | $$           /$$__  $$                      
  # /$$$$$$| $$$$$$$ /$$   /$$ /$$$$$$$       /$$/$$$$$$/$$$$  /$$$$$$  /$$$$$$  /$$$$$$ /$$$$$$        | $$  \__/$$$$$$  /$$$$$$       
 # /$$__  $| $$__  $| $$  | $$/$$_____/      | $| $$_  $$_  $$/$$__  $$/$$__  $$/$$__  $|_  $$_/        | $$$$  /$$__  $$/$$__  $$      
# | $$  \ $| $$  \ $| $$  | $|  $$$$$$       | $| $$ \ $$ \ $| $$  \ $| $$  \ $| $$  \__/ | $$          | $$_/ | $$  \ $| $$  \__/      
# | $$  | $| $$  | $| $$  | $$\____  $$      | $| $$ | $$ | $| $$  | $| $$  | $| $$       | $$ /$$      | $$   | $$  | $| $$            
# | $$$$$$$| $$  | $|  $$$$$$$/$$$$$$$/      | $| $$ | $$ | $| $$$$$$$|  $$$$$$| $$       |  $$$$/      | $$   |  $$$$$$| $$            
# | $$____/|__/  |__/\____  $|_______/       |__|__/ |__/ |__| $$____/ \______/|__/        \___/        |__/    \______/|__/            
# | $$               /$$  | $$         /$$$$$$$ /$$          | $$          /$$                                                          
# | $$              |  $$$$$$/        | $$__  $| $$          | $$         | $$                                                          
# |__/               \______/         | $$  \ $| $$ /$$$$$$ /$$$$$$$  /$$$$$$$ /$$$$$$  /$$$$$$                                         
                                    # | $$$$$$$| $$/$$__  $| $$__  $$/$$__  $$/$$__  $$/$$__  $$                                        
                                    # | $$__  $| $| $$$$$$$| $$  \ $| $$  | $| $$$$$$$| $$  \__/                                        
                                    # | $$  \ $| $| $$_____| $$  | $| $$  | $| $$_____| $$                                              
                                    # | $$$$$$$| $|  $$$$$$| $$  | $|  $$$$$$|  $$$$$$| $$                                              
                                    # |_______/|__/\_______|__/  |__/\_______/\_______|__/
import json
import bpy
import os
import bmesh
import mathutils

##  Just convert the .phys file to .json with wolvenkit and put the full path here, make sure to use \\
## if you're trying to match the location of a vehicle ent imported with the cp77 blender plugin, just check the ent file for the vehicleChassisComponent and 
## raise the verts by the Z value in localTransform - remember to undo this before export as well

physJsonPath = "the\\full\\path\\to\\original\\json"  # make sure to use \\ in your path

phys = open(physJsonPath)
data = json.load(phys)

# create a new collector named after the file
collection_name = os.path.splitext(os.path.basename(physJsonPath))[0]
new_collection = bpy.data.collections.new(collection_name)
bpy.context.scene.collection.children.link(new_collection)

# create the new objects
def create_new_object(name, transform):
    mesh = bpy.data.meshes.new(name)
    obj = bpy.data.objects.new(name, mesh)
    new_collection.objects.link(obj)  
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)

 # create dicts for position/orientation
    position = (transform['position']['X'], transform['position']['Y'], transform['position']['Z'])
    orientation = (transform['orientation']['r'], transform['orientation']['j'], transform['orientation']['k'], transform['orientation']['i'])
    obj.location = position
    obj.rotation_mode = 'QUATERNION'
    obj.rotation_quaternion = orientation

    return obj

# Iterate through the collisionShapes array, creatting submeshes in the collector named after the collider types
for index, i in enumerate(data['Data']['RootChunk']['bodies'][0]['Data']['collisionShapes']):

# create dicts for later
    colliderType = i['Data']['$type']
    submeshName = str(index) + '_' + colliderType
    transform = i['Data']['localToBody']

# If the type is "physicsColliderConvex", or "physicsColliderConcave" create meshes with vertices everywhere specified in the vertices array
    if colliderType == "physicsColliderConvex" or colliderType == "physicsColliderConcave":
        obj = create_new_object(submeshName, transform)
        if 'vertices' in i['Data']:
            verts = [(j['X'], j['Y'], j['Z']) for j in i['Data']['vertices']]
            bm = bmesh.new()
            for v in verts:
                bm.verts.new(v)
            bm.to_mesh(obj.data)
            bm.free()

# If the type is "physicsColliderBox", create a box centered at the object's location
    elif colliderType == "physicsColliderBox":
        half_extents = i['Data']['halfExtents']
        dimensions = (2 * half_extents['X'], 2 * half_extents['Y'], 2 * half_extents['Z'])
        bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
        box = bpy.context.object
        box.scale = dimensions
        box.name = submeshName
        box.location = transform['position']['X'], transform['position']['Y'], transform['position']['Z']
        box.rotation_mode = 'QUATERNION'  # Set the rotation mode to QUATERNION first
        box.rotation_quaternion = transform['orientation']['r'], transform['orientation']['j'], transform['orientation']['k'], transform['orientation']['i']

        new_collection.objects.link(box)
        bpy.context.collection.objects.unlink(box) # Unlink from the current collection

 # handle physicsColliderCapsule       
    elif colliderType == "physicsColliderCapsule":
        radius = i['Data']['radius']
        height = i['Data']['height']
        bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=height, location=(0, 0, 0))
        capsule = bpy.context.object
        capsule.name = submeshName
        capsule.rotation_mode = 'QUATERNION'
        capsule.location = transform['position']['X'], transform['position']['Y'], transform['position']['Z']
        capsule.rotation_quaternion = transform['orientation']['r'], transform['orientation']['j'], transform['orientation']['k'], transform['orientation']['i']

        new_collection.objects.link(capsule)
        bpy.context.collection.objects.unlink(capsule)  

print('Finished')