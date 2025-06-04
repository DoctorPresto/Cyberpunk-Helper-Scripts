import os

from PIL import Image
import numpy as np

# just paste this into blender's script editor and then fill this in with the path to your opengl(blue coloured) normnal, and press run, the cyberpunk swizzled
# normal will be in the same folder as the opengl normal with _swizzled added to the filename


# just fill this in with the path to your opengl(blue coloured) normnal, and press run, the cyberpunk swizzled
# normal will be in the same folder as the opengl normal with _swizzled added to the filename

# use double slashes in between folder names in your path C:\\folder1\\folder2\\my_example_normal.png

inpath = 's:\\KB3D_HEM_MetalFrame_normal.png'  # replace this with the path to your normal image to convert
swizzle_or_unswizzle = True  # set to True to swizzle, False to unswizzle
# (the blue looking one not used in game needs to be swizzled, the ones from the game, unswizzled)


def load_img(img_path):
    if img_path is not None:
        print(f'loading: {img_path} ')
    img = Image.open(img_path)
    return img


def swizzle_normal(oglnorm):
    dxnorm = np.array(oglnorm).astype(np.float32)
    dxnorm = dxnorm / 255.0 * 2.0 - 1.0
    dxnorm[..., 1] = -dxnorm[..., 1]
    dxnorm[..., 2] = -1.0
    dxnorm = ((dxnorm + 1.0) / 2.0 * 255.0).astype(np.uint8)
    return Image.fromarray(dxnorm)


def unswizzle_normal(dxnorm):
    oglnorm = np.array(dxnorm).astype(np.float32)
    oglnorm = oglnorm / 255.0 * 2.0 - 1.0
    oglnorm[..., 1] = -oglnorm[..., 1]
    oglnorm[..., 2] = np.sqrt(
        np.clip(1.0 - oglnorm[..., 0] ** 2 - oglnorm[..., 1] ** 2, 0, 1)
    )
    oglnorm = ((oglnorm + 1.0) / 2.0 * 255.0).astype(np.uint8)
    return Image.fromarray(oglnorm)


if swizzle_or_unswizzle == True:
    oglnrm = load_img(inpath)
    print('preparing to swizzle your image')
    outpath = os.path.splitext(inpath)[0] + '_swizzled.png'
    dxnrm = swizzle_normal(oglnrm)
    dxnrm.save(outpath)
else:
    dxnrm = load_img(inpath)
    print('preparing to unswizzle your image')
    outpath = os.path.splitext(inpath)[0] + '_unswizzled.png'
    oglnrm = unswizzle_normal(dxnrm)
    oglnrm.save(outpath)

print(f'successfully converted image saved to: {outpath}')
