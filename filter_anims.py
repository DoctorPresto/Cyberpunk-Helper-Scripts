import bpy
import os
import json

##########################      You need to fill these out         ######################################################

# you need to edit this so that it points to the json you want to filter, paths need two slashes \\ not \
file_to_search = "path\\to\\your\\anims.json"

## set this to True if you have imported the anims file to blender and also want it to delete all the extra nla strips
delete_anims = False 

# List of anims to search for, seperated by a comma, individual lines is optional but easier to read
names_to_search = [
"anim__1", 
"anim__2", 

]

#########################     you don't need to touch any of this    ########################################################

# we're going to use the path of the original json to set the output path, this gets the path to the directory 
# we're going to make the new file in 
dir_path, file_name = os.path.split(file_to_search)

# lelts get the name of the anims.json
file_name_without_extension, file_extension = os.path.splitext(file_name)

#  set the new filename to match the original but with _filtered in front 
new_file_name = "filtered_" + file_name_without_extension + file_extension

# tell the script to make the new file in the directory of the original 
output_path = os.path.join(dir_path, new_file_name)

with open(file_to_search, "r") as json_file:
    data = json.load(json_file)

# Create a copy of the original JSON data
output_data = data.copy()

# Create a new animations array that only contains the animations we're searching for
output_data["Data"]["RootChunk"]["animations"] = [
    animation for animation in data["Data"]["RootChunk"]["animations"] if
    animation["Data"]["animation"]["Data"]["name"]["$value"] in names_to_search
]

# Write the modified JSON data to the output file
with open(output_path, "w") as output_file:
    json.dump(output_data, output_file, indent=4)
    
# If the delete_anims bool is set to True, delete any NLA strips which have matching names to the ones we searched
if delete_anims:
    for obj in bpy.context.scene.objects:
        if obj.type == 'ARMATURE' and obj.animation_data and obj.animation_data.nla_tracks:
            for strip in obj.animation_data.nla_tracks:
                if strip.name not in names_to_search:
                    obj.animation_data.nla_tracks.remove(strip)

print("your new anims.json has been saved to:" + output_path)
