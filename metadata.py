# Run this script from the commandline - all necessary inputs will be prompted for there. 
# Don't use quoations or double slashes in paths



#############################################################  
import json

searchPhrase = input(   "Enter the string to search for in class names:   ") 


metadata_json = input(   "Enter the path to your metadata.json file: "   ) 
output_json = input(   "Enter the absolute path for the output file including file name and .json:   ")  


def search_and_output(json_data, output_file_path):
    matching_entries = []

    def find_metadata(classes):
        for entry in classes:
            if "name" in entry and searchPhrase in entry["name"]:#.startswith(searchPhrase):
                matching_entries.append(entry)

    if "classes" in json_data:
        find_metadata(json_data["classes"])

    # Write the output JSON file
    with open(output_file_path, 'w') as output_file:
        json.dump(matching_entries, output_file, indent=2)
        print('classes exported to:', output_json)

    # Read the metadata JSON file
with open(metadata_json, 'r') as file:
    input_data = json.load(file)

# Call the search_and_output function
search_and_output(input_data, output_json)
 