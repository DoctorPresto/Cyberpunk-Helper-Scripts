import json
import os

import bpy
import mathutils

#                             by The Magnificent Doctor Presto August 4 2023
#           /$$           https://github.com/DoctorPresto/Cyberpunk-Helper-Scripts           /$$            /$$$$$$
#          | $$                                                                             | $$           /$$__  $$
#   /$$$$$$| $$$$$$$ /$$   /$$ /$$$$$$$        /$$$$$$ /$$   /$$ /$$$$$$  /$$$$$$  /$$$$$$ /$$$$$$        | $$  \__/$$$$$$  /$$$$$$
#  /$$__  $| $$__  $| $$  | $$/$$_____/       /$$__  $|  $$ /$$//$$__  $$/$$__  $$/$$__  $|_  $$_/        | $$$$  /$$__  $$/$$__  $$
# | $$  \ $| $$  \ $| $$  | $|  $$$$$$       | $$$$$$$$\  $$$$/| $$  \ $| $$  \ $| $$  \__/ | $$          | $$_/ | $$  \ $| $$  \__/
# | $$  | $| $$  | $| $$  | $$\____  $$      | $$_____/ >$$  $$| $$  | $| $$  | $| $$       | $$ /$$      | $$   | $$  | $| $$
# | $$$$$$$| $$  | $|  $$$$$$$/$$$$$$$/      |  $$$$$$$/$$/\  $| $$$$$$$|  $$$$$$| $$       |  $$$$/      | $$   |  $$$$$$| $$
# | $$____/|__/  |__/\____  $|_______/        \_______|__/  \__| $$____/ \______/|__/        \___/        |__/    \______/|__/
# | $$               /$$  | $$         /$$$$$$$ /$$            | $$        /$$
# | $$              |  $$$$$$/        | $$__  $| $$            | $$       | $$
# |__/               \______/         | $$  \ $| $$ /$$$$$$ /$$$$$$$  /$$$$$$$ /$$$$$$  /$$$$$$
#                                     | $$$$$$$| $$/$$__  $| $$__  $$/$$__  $$/$$__  $$/$$__  $$
#                                     | $$__  $| $| $$$$$$$| $$  \ $| $$  | $| $$$$$$$| $$  \__/
#                                     | $$  \ $| $| $$_____| $$  | $| $$  | $| $$_____| $$
#                                     | $$$$$$$| $|  $$$$$$| $$  | $|  $$$$$$|  $$$$$$| $$
#                                     |_______/|__/\_______|__/  |__/\_______/\_______|__/


###  Just enter the path tio your original .json file here and the script will export the changes you've made in blender to a copy of the original json in
### that will be saved into same directory as the original with a new_ prefix. All you need to do is right click on this file in wolvenkit and convert from json back to .phys

physJsonPath = 'the\\full\\path\\to\\original\\json'  # make sure to use \\ in your path

phys = open(physJsonPath)
data = json.load(phys)

dir_name, file_name = os.path.split(physJsonPath)
new_file_name = 'new_' + file_name
output = os.path.join(dir_name, new_file_name)

# this checks the project for a collector that matches the name of the .json and only exports the info from there
collection_name = os.path.splitext(os.path.basename(physJsonPath))[0]
collection = bpy.data.collections.get(collection_name)

if collection is not None:
    for index, obj in enumerate(collection.objects):
        colliderType = obj.name.split('_')[1]
        i = data['Data']['RootChunk']['bodies'][0]['Data']['collisionShapes'][index]

        i['Data']['localToBody']['position']['X'] = obj.location.x
        i['Data']['localToBody']['position']['Y'] = obj.location.y
        i['Data']['localToBody']['position']['Z'] = obj.location.z
        i['Data']['localToBody']['orientation']['i'] = obj.rotation_quaternion.z
        i['Data']['localToBody']['orientation']['j'] = obj.rotation_quaternion.x
        i['Data']['localToBody']['orientation']['k'] = obj.rotation_quaternion.y
        i['Data']['localToBody']['orientation']['r'] = obj.rotation_quaternion.w

        if (
            colliderType == 'physicsColliderConvex'
            or colliderType == 'physicsColliderConcave'
        ):
            mesh = obj.data
            if 'vertices' in i['Data']:
                for j, vert in enumerate(mesh.vertices):
                    i['Data']['vertices'][j]['X'] = vert.co.x
                    i['Data']['vertices'][j]['Y'] = vert.co.y
                    i['Data']['vertices'][j]['Z'] = vert.co.z

        elif colliderType == 'physicsColliderBox':
            # Calculate world-space bounding box vertices
            world_bounds = [
                obj.matrix_world @ mathutils.Vector(coord) for coord in obj.bound_box
            ]

            # Get center of the box in world space
            center = sum(world_bounds, mathutils.Vector()) / 8

            # Update position in the json based on the center of the cube in world space
            i['Data']['localToBody']['position']['X'] = center.x
            i['Data']['localToBody']['position']['Y'] = center.y
            i['Data']['localToBody']['position']['Z'] = center.z
            # Update halfExtents
            i['Data']['halfExtents']['X'] = obj.dimensions.x / 2
            i['Data']['halfExtents']['Y'] = obj.dimensions.y / 2
            i['Data']['halfExtents']['Z'] = obj.dimensions.z / 2

        elif colliderType == 'physicsColliderCapsule':
            i['Data']['radius'] = (
                obj.dimensions.x / 2
            )  # Divided by 2 because blender dimensions are diameter
            i['Data']['height'] = obj.dimensions.z

with open(output, 'w') as f:
    json.dump(data, f, indent=2)

print('Finished')
