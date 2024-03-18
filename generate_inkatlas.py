import os
import json

def convert_to_percent(image_size, left, right, top, bottom):
    # function to calculate the uv coords as percents of the image
    left_percent = left / image_size[0]
    right_percent = right / image_size[0]
    top_percent = top / image_size[1]
    bottom_percent = bottom / image_size[1]

    return left_percent, right_percent, top_percent, bottom_percent

def main():
    # Prompt the user for the required info 
    width = int(input("Enter the icon width in pixels: "))
    height = int(input("Enter the icon height in pixels: "))
    columns = int(input("Enter the number of columns: "))
    rows = int(input("Enter the number of rows in the atlas: "))
    spacing = int(input("Enter the number of pixels between icons: "))
    texture_path = input("Enter the relative path to the xbm file(copy from wkit): ")
    output_folder = input("Enter the absolute path to your projects raw folder (single slashes): ")

    total_width = width * columns + spacing * (columns - 1)
    total_height = height * rows + spacing * (rows - 1)

    image_size = (total_width, total_height)

    # setup wkit inkatlas.json structure 
    data = {
        "Header": {
            "WolvenKitVersion": "8.13.0-nightly.2024-03-17",
            "WKitJsonVersion": "0.0.8",
            "GameVersion": 2120,
            "ExportedDateTime": "2024-03-18T04:38:07.1672443Z",
            "DataType": "CR2W",
            "ArchiveFileName": ""
        },
        "Data": {
            "Version": 195,
            "BuildVersion": 0,
            "RootChunk": {
                "$type": "inkTextureAtlas",
                "activeTexture": "StaticTexture",
                "cookingPlatform": "PLATFORM_None",
                "dynamicTexture": {
                    "DepotPath": {"$type": "ResourcePath", "$storage": "uint64", "$value": "0"},
                    "Flags": "Default"
                },
                "dynamicTextureSlot": {
                    "$type": "inkDynamicTextureSlot",
                    "parts": [],
                    "texture": {"DepotPath": {"$type": "ResourcePath", "$storage": "uint64", "$value": "0"},
                                "Flags": "Default"}
                },
                "isSingleTextureMode": 1,
                "parts": [],
                "slices": [],
                "slots": {
                    "Elements": [
                        {
                            "$type": "inkTextureSlot",
                            "parts": [],
                            "slices": [],
                            "texture": {
                                "DepotPath": {
                                    "$type": "ResourcePath",
                                    "$storage": "string",
                                    "$value": texture_path
                                },
                                "Flags": "Default"
                            }
                        }
                    ]
                },
                "texture": {
                    "DepotPath": {
                        "$type": "ResourcePath",
                        "$storage": "string",
                        "$value": texture_path
                    },
                    "Flags": "Default"
                },
                "textureResolution": "UltraHD_3840_2160"
            },
            "EmbeddedFiles": []
        }
    }

    # Populate parts info
    for row in range(rows):
        for col in range(columns):
            left_pixel = col * (width + spacing)
            right_pixel = left_pixel + width
            top_pixel = row * (height + spacing)
            bottom_pixel = top_pixel + height

            # Convert to percents
            left_percent, right_percent, top_percent, bottom_percent = convert_to_percent(
                image_size, left_pixel, right_pixel, top_pixel, bottom_pixel
            )

            # create parts entries for each item
            part_data = {
                "$type": "inkTextureAtlasMapper",
                "clippingRectInPixels": {
                    "$type": "Rect",
                    "bottom": bottom_pixel,
                    "left": left_pixel,
                    "right": right_pixel,
                    "top": top_pixel
                },
                "clippingRectInUVCoords": {
                    "$type": "RectF",
                    "Bottom": bottom_percent,
                    "Left": left_percent,
                    "Right": right_percent,
                    "Top": top_percent
                },
                "partName": {
                    "$type": "CName",
                    "$storage": "string",
                    "$value": f"{row}_{col}"
                }
            }

            # Append part data to parts array 
            data["Data"]["RootChunk"]["slots"]["Elements"][0]["parts"].append(part_data)

    # Create the output folder if it does not exist
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    # set the output file name
    output_file = os.path.join(output_folder, "output.inkatlas.json")

    # Write everything to the .inkatlas.json
    with open(output_file, "w") as json_file:
        json.dump(data, json_file, indent=2)

    print(f"Data has been saved to {output_file}")

if __name__ == "__main__":
    main()
