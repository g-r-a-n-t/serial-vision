import os
import glob

g = glob.glob('*.png')

for filename in g:
    l = len(filename)
    leading_zeros = '0' * (15 - l)
    filename_back = filename[5:]
    newname = leading_zeros + filename_back
    os.rename(filename, newname)
    print(filename, newname)
