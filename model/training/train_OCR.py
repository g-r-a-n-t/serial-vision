'''Trains a simple convnet on an OCR dataset and convert it to CoreML

'''

from __future__ import print_function
import numpy as np
np.random.seed(1337)  # for reproducibility

import keras
from keras.models import Sequential
from keras.layers import Dense, Dropout, Activation, Flatten
from keras.layers import Convolution2D, MaxPooling2D
from keras.utils import np_utils
from keras import backend as K
from keras import models
from PIL import Image
from numpy import genfromtxt
import gzip, pickle
from glob import glob
import pandas as pd
from scipy import ndimage
import coremltools
from sklearn.model_selection import train_test_split
import sys
import os

# FOR LOADING IMAGES AND LABELS
def dir_to_dataset(glob_files, loc_train_labels=""):
    print('\n')
    print("Gonna process:\t %s"%glob_files)
    dataset = []
    for file_count, file_name in enumerate(sorted(glob(glob_files))):
        if file_count % 100 == 0:
            sys.stdout.write(".")
            sys.stdout.flush()
        img = Image.open(file_name).convert('LA') #tograyscale
        pixels = [f[0] for f in list(img.getdata())]
        #print( file_name)
        dataset.append(pixels)

    print("\n TrainLabels ..")
    if len(loc_train_labels) > 0:
        df = pd.read_csv(loc_train_labels)
        print("\t Labels loaded  ..")
        return np.array(dataset), np.array(df["Class"])
    else:
        return np.array(dataset)




batch_size = 128

#how many epochs (iterations) for training
nb_epoch = 16

# input image dimensions
img_rows, img_cols = 28, 28
# number of convolutional filters to use
nb_filters = 32
# size of pooling area for max pooling
pool_size = (2, 2)
# convolution kernel size
kernel_size = (3, 3)

os.system('cls' if os.name == 'nt' else 'clear')
print('\n')
print('Loading images - Please wait ', end='')
#my images have the extension PNG not png !
Data, y = dir_to_dataset('/Users/grant.wuerker/Desktop/myriad-data/' + sys.argv[1] + '/*.png','~/Desktop/myriad-data/' + sys.argv[1] + '/OCR.csv')

nb_classes = y.max() - y.min() + 1


#random split and random shuffle the dataset 75% for train and 25% for test (= 0.25)
X_train, X_test, Y_train, Y_test = train_test_split(Data, y, test_size=0.25, random_state=42)

print('\n')
print('\n Dataset loaded')

if K.image_dim_ordering() == 'th':
    X_train = X_train.reshape(X_train.shape[0], 1, img_rows, img_cols)
    X_test = X_test.reshape(X_test.shape[0], 1, img_rows, img_cols)
    input_shape = (1, img_rows, img_cols)
else:
    X_train = X_train.reshape(X_train.shape[0], img_rows, img_cols, 1)
    X_test = X_test.reshape(X_test.shape[0], img_rows, img_cols, 1)
    input_shape = (img_rows, img_cols, 1)

X_train = X_train.astype('float32')
X_test = X_test.astype('float32')
X_train /= 255
X_test /= 255

print('\n')
print('\n')
print("%d Classes" % nb_classes)
print(X_train.shape[0], 'train samples')
print(X_test.shape[0], 'test samples')
print('\n')
print('\n')
print('\nBuilding the model')
# convert class vectors to binary class matrices
Y_train = np_utils.to_categorical(Y_train, nb_classes)
Y_test = np_utils.to_categorical(Y_test, nb_classes)


#build the model
model = Sequential()

model.add(Convolution2D(nb_filters, kernel_size[0], kernel_size[1],
                        border_mode='valid',
                        input_shape=input_shape))
model.add(Activation('relu'))
model.add(Convolution2D(nb_filters, kernel_size[0], kernel_size[1]))
model.add(Activation('relu'))
model.add(MaxPooling2D(pool_size=pool_size))
model.add(Dropout(0.25))

model.add(Flatten())
model.add(Dense(128))
model.add(Activation('relu'))
model.add(Dropout(0.5))
model.add(Dense(nb_classes))
model.add(Activation('softmax'))

#compile the mlmodel
print('\n')
print('\nCompiling the model')
model.compile(loss='categorical_crossentropy',
              optimizer='adam',
              metrics=['accuracy'])


#start training
print('\n')
print('\nTrain the model')
print('\n')
print('\n')
model.fit(X_train, Y_train, batch_size=batch_size, epochs=nb_epoch,
          verbose=1, validation_data=(X_test, Y_test))


score = model.evaluate(X_test, Y_test, verbose=0)


models.save_model(model,'OCR_cnn.h5')

print('\n')
print('Model trained and saved ..')
print('Convert the model to CoreML-Model ..')


#THIS SHOULD MATCH YOUR CLASSES !!!
#IT MEANS: Class 0 (in *.csv) is mapped as '0' and so on
output_labels = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z','0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
scale = 1/255.
coreml_model = coremltools.converters.keras.convert('./OCR_cnn.h5',
                                                    input_names='image',
                                                    image_input_names='image',
                                                    output_names='output',
                                                    class_labels=output_labels,
                                                    image_scale=scale)

#SOME ADDITIONAL INFOMARTION ABOUT YOR MODEL
coreml_model.author = 'DrNeurosurg'
coreml_model.license = 'MIT'
coreml_model.short_description = 'Model to classify characters (Font:INCONSOLATA)'

coreml_model.input_description['image'] = 'Grayscale image'
coreml_model.output_description['output'] = 'Predicted character'

# SAVE THE COREML.model for using in Xcode
coreml_model.save('OCR.mlmodel')

print('\n')
print('\n')
print('CoreML-Model saved ! Accuracy = ', score[1])
print('Trained with Keras Version', keras.__version__)
print('\n')
