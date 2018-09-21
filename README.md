# Serial Vision

Serial Vision is a smart app capable of detecting serial numbers on a device using live camera feed. It integrates with Jamf Pro so users can more easily manage devices on the go.

## App Usage
- pictures
- Problem statement, proposed solution, overview of what you have built during the hackathon

## Technical Implementation
There are three main components to this app. The first is text detection, by this we mean detecting where characters are inside of an image. The second part is classifying the identified characters, this step provides us with probability distributions for each identified character. The third step is taking these probability distributions and inferring what serial number is contained in the image.

### Text Detection
Apple's general purpose language, Swift, contains a library named Vision. This library contains useful image analysis functionality. We used the text detection toolset to find the pixel bounds of each character, which was then used to isolate the characters for classification

For example, say we are given this image of a MacBook Pro. The serial number is `CO2T83GXGTFM` as seen on the bottom right. Running the text detection query in vision will provide us with the bounds for each `word` and `character` in the image. `Words` refers to a group of `characters`. You can see that the serial number is grouped along with some other characters.

| Original  | Bounded  |
| --------- | -------- |
| ![MacBook Pro](https://raw.githubusercontent.com/g-r-a-n-t/serial-vision/master/images/serial.png) | ![MacBook Pro Bounded](https://github.com/g-r-a-n-t/serial-vision/raw/master/images/serial-bounded.png) |



### Text classification

After finding the bounds of each character, we crop them out and run some preprocessing. The model requires 28x28 greyscale images, so we must resize and adjust the colors. A handful of the resulting images are below, the serial number is boxed in red.

![Characters](https://github.com/g-r-a-n-t/serial-vision/raw/master/images/characters.png)

We will now run these images through our CoreMl Model, which we will go into more detail about later. The result of each serial number character classification is below.

```
["0": 0.0750194564461708, "O": 0.08124776929616928, "L": 0.038230523467063904, "C": 0.5053677558898926]
["O": 0.14617282152175903, "Q": 0.038274433463811874, "0": 0.6656758189201355, "U": 0.023656057193875313]
["0": 0.04036850854754448, "J": 0.04066077247262001, "7": 0.04391703009605408, "2": 0.5811875462532043]
["T": 0.10070312768220901, "J": 0.025575492531061172, "1": 0.6189287304878235, "I": 0.0793764591217041]
["0": 0.1596156358718872, "9": 0.04016838222742081, "8": 0.14071892201900482, "B": 0.1249534860253334]
["J": 0.10250584036111832, "1": 0.15580035746097565, "3": 0.21958182752132416, "8": 0.07624480128288269]
["0": 0.13221488893032074, "O": 0.17781522870063782, "Q": 0.11892163753509521, "G": 0.13613837957382202]
["X": 0.8197426795959473, "R": 0.016862664371728897, "Y": 0.059248242527246475, "S": 0.01618219166994095]
["Q": 0.1747690886259079, "0": 0.16164137423038483, "O": 0.09578970074653625, "G": 0.1969677358865738]
["T": 0.4557770788669586, "7": 0.07766497880220413, "1": 0.11317556351423264, "I": 0.12429703027009964]
["E": 0.0910964086651802, "P": 0.1551859825849533, "L": 0.038149815052747726, "F": 0.3868154287338257]
["H": 0.05983928591012955, "M": 0.6266825795173645, "V": 0.10437410324811935, "U": 0.08249279856681824]
```

For difficult to read images like this, it's more likely that the probability distribution will be spread out, which could result in the most likely sequence of characters not being a serial number in Jamf Pro. To handle this, we must design an algorithm that checks multiple likely characters in the probability distribution.

### Serial Identification

The number of possible serials that could exist in each 12 character sequence given that we are checking the top 4 most likely characters is `4^12 = 16777216`. If we were to do this for every 12 character sequences in the entire image, we would find a large set of possible serial numbers and their probabilities. From this, we could take the most likely sequence of 12 characters resembling a serial number and use that. A naive implementation of this would be slow and optimization would be tedious, so it is not really an option for us.

To make this simpler and faster, lets use the information we can obtain from Jamf Pro. Given all of the serial numbers within Jamf Pro, we can construct a hash table that will help us prune invalid sequences as we go through the probability distributions. For example, if we had the serial numbers `CO2T83GXGTFM` and `CO2T34FYVSTG` in our Jamf Pro server, we would build a hash table that contains these values.

```
C
CO
CO2
CO2T
CO2T8
CO2T83
CO2T83G
CO2T83GXG
CO2T83GXGT
CO2T83GXGTF
CO2T83GXGTFM
CO2T3
CO2T34
CO2T34F
CO2T34FY
CO2T34FYV
CO2T34FYVS
CO2T34FYVST
CO2T34FYVSTG
```
Now when our algorithm is generating combinations, at each step it will only consider sequences that could exist in Jamf Pro. This makes it many times faster with its minimum complexity being `linear` and it maximum complexity being `polynomial`. Even with a very large Jamf Pro server the complexity tends towards linear.

## Classification Model

### Data Collection
Collecting a dataset for this project within the given timeframe seemed at first like it would be a difficult task, however, we were able to collect everything we needed within a single afternoon.

For this project, we needed a large number of 28x28 greyscale images, roughly 4000. In order to gather this information we first created a document including roughly 800 characters, each row containing a full alphanumeric set. We then took pictures of this document using our phones and ran them through the preprocessing code used in our app.

| *Images used to construct our dataset* |                 |
| ---------------------------------------| --------------- |
|  ![Document1](https://github.com/g-r-a-n-t/serial-vision/raw/master/images/document1.jpeg) | ![Document2](https://github.com/g-r-a-n-t/serial-vision/raw/master/images/document2.jpeg) |
| ![Document3](https://github.com/g-r-a-n-t/serial-vision/raw/master/images/document3.jpeg) | ![Document4](https://github.com/g-r-a-n-t/serial-vision/raw/master/images/document4.jpeg) |

After processing each character, the results were dumped into a single directory. We then sorted though these dumps, looking for missing or extra images. Opening the finder window to display 12 thumbnails in a row made this task pretty easy, since a change in the sequence of each 36 characters was easy to detect. Upon detection of an anomaly, the extra image would be deleted or the missing character would be removed from or classification mapping file.

![Training Data](https://github.com/g-r-a-n-t/serial-vision/raw/master/images/training-data.png)

After manually processing each picture, we combined the data into one set containing 3200 images. This was plenty enough to meet our needs.

### Design
We used the Python library Keres, to help define and train our model. Keras is a high level API for ML development. Tensorflow was used by Keras to build and train our model in the background. The result of training was then converted to a CoreML file and added to our iOS project.

The feature learning section of our model consists of two consecutive `Conv2D` layers, each with kernel sizes of 3, followed by a `MaxPooling2D` layer with a dropout rate of .25. The classification section consists of a `Flatten` layer, a `Dense` layer with a dropout rate of .5, and a `Softmax` classifier. We used ReLU for our activation function. We chose this model because it had been used by others successfully to classify characters.

### Performance

The model was trained on 2400 images and validated on 800 images with a batch size of 128 inputs over 6 epochs. Training time takes under a minute and the accuracy is consistently above 98% on test data.

![Performance](https://github.com/g-r-a-n-t/serial-vision/raw/master/images/performance.png)

The performance of this model is equally as good on devices. Given that the characters are reasonably clear, the model will often predict with very high confidence the correct value.

## Analysis
- what was learned
- How your solution will create impact for your company
- Performance achieved (on test set) – with visual representations as appropriate
-- How would it be used – e.g. part of existing product (which one?) / new product etc.
-- Best guess of time required for deployment of an MVP if this was to be implemented
- key next steps and challenges identified for taking this solution from its current state to production
