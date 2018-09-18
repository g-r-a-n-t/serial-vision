import glob
from shutil import copyfile

datasets = ['set1', 'set2', 'set3'] # must be in order
all_image_classes = ['Class\n']

for dataset in datasets:
    images = glob.glob(dataset + '/characters/*.png')
    for image in images:
        copyfile(image, 'combined/' + dataset + image[-10:])

    image_classes = open(dataset + '/characters/OCR.csv').readlines()
    image_classes.pop(0)
    all_image_classes += image_classes

classes_out = open('combined/OCR.csv', 'w')
classes_out.write(''.join(all_image_classes))
