# Serial Vision

Serial Vision is a smart app capable of detecting serial numbers on an Apple device using live camera feed. It integrates with [Jamf Pro](https://www.jamf.com) so IT administrators can easily manage devices on the go.

## App Usage
| Live video screen | Reading a serial | Information from the device |
| --- | --- | --- |
| ![Screenshot](/images/app-screenshot1.jpeg?raw=true) | ![Screenshot](/images/app-screenshot2.jpeg?raw=true) | ![Screenshot](/images/app-screenshot3.jpeg?raw=true) |

The Serial Vision app gives admins the ability to quickly read serial numbers off the backs of devices, which then allows them to query details and manage on the go. This prototype lays the foundation for novel business solutions that could be added to Jamf's product line.

## Technical Implementation
There are three main components to this app. The first is **text detection** - by this we mean detecting where characters are inside of an image. The second part is **character classification** of the detected characters. This step provides us with probability distributions for each identified character. The third step is **serial number determination** - taking the probability distributions and determining what serial number is contained in the image.

### Text Detection
Apple's general purpose language, Swift, contains a visual analysis library called [Vision](https://developer.apple.com/documentation/vision). We used the text detection toolset in this library to find the bounds and position of each character contained within the images being processed. This information was then used to generate input for our character classification model.

Below is an example of Vision detecting character bounds inside an image. This image contains a MacBook Pro, the serial number is `CO2T83GXGTFM` as seen on the bottom right. Running the text detection query in vision will provide us with the bounds for each `word` and `character` in the image. `Words` refers to a group of `characters`. You can see that the serial number is grouped along with some other characters.

| Original  | Bounded  |
| --------- | -------- |
| ![MacBook Pro](https://raw.githubusercontent.com/g-r-a-n-t/serial-vision/master/images/serial.png) | ![MacBook Pro Bounded](https://github.com/g-r-a-n-t/serial-vision/raw/master/images/serial-bounded.png) |

### Text classification

After finding the bounds of each character, we crop them out and run some preprocessing. The model requires 28x28 pixel greyscale images, so we must resize and adjust the colors. A handful of the resulting images are below, the serial number is boxed in red.

![Characters](https://github.com/g-r-a-n-t/serial-vision/raw/master/images/characters.png)

We can now run these images through our Core ML Model, which we will talk about more later. The result of each character classification within the serial number is below. This map structure represents the level of confidence our model has in classifying each character. For example our model is 8% sure that the first character in our serial is a "0", 8% its an "O", 4% sure it's an "L", and 50% sure it's a "C". It has guessed correctly in this case, as 50% is its highest confidence.

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

For difficult to read images like this, the probability distribution will be more diffused, which could result in the most likely sequence of characters resembling a serial number, not being correct. To handle this, we must design an algorithm that checks multiple serials within the probability distribution and selects the one that is most likely to be in the image, while still running quickly.

### Serial Identification

The number of possible serials that could exist in a 12 character sequence given that we are checking the top 4 most likely characters is `4^12 = 16777216`. If we generated each possible sequence, we could take the most likely one resembling a serial number and use that. This could be useful under some circumstances and variations of this could be somewhat quick, but it is not necessary in this project. For this, we are only trying to find a serial that exists in Jamf Pro.

To make this faster, let's make a simple change that leverages known data. Given all of the serial numbers within Jamf Pro (acquired via the [Jamf Pro REST API](https://developer.jamf.com/apis)), we can construct a hash table for pruning invalid sequences as we go through the classification results. For example, if we had the serial numbers `CO2T83GXGTFM` and `CO2T34FYVSTG` in our Jamf Pro server, we would build a hash table that contains these values.

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
Now when our algorithm is generating combinations, it will only consider sequences that could exist in Jamf Pro. This makes it many times faster. With a minimum complexity of `linear` and a maximum complexity of `polynomial`, it can identify the correct serial out of thousands in less than a second.

## Classification Model

### Data Collection
For this project, we needed a large number (in the thousands) of 28x28 pixel greyscale images. In order to gather this information we first created a document including roughly 800 characters, each row containing a full alphanumeric set. We then took pictures of this document using our phones and ran them through the Vision preprocessing code used in our app.

| *Images used to construct our dataset* |                 |
| ---------------------------------------| --------------- |
|  ![Document1](https://github.com/g-r-a-n-t/serial-vision/raw/master/images/document1.jpeg) | ![Document2](https://github.com/g-r-a-n-t/serial-vision/raw/master/images/document2.jpeg) |
| ![Document3](https://github.com/g-r-a-n-t/serial-vision/raw/master/images/document3.jpeg) | ![Document4](https://github.com/g-r-a-n-t/serial-vision/raw/master/images/document4.jpeg) |

After processing each character, the results were dumped into a single directory. We then sorted though these dumps, looking for missing or extra images. Configuring the Finder window to display 12 (`36 % 12 = 0`) thumbnails in a row made this task pretty easy. Since they were in alphabetical order, a change in sequence was easy to detect with the eye. Upon detection of an anomaly, the extra image would be deleted or the missing character would be removed from or classification mapping file.

![Training Data](https://github.com/g-r-a-n-t/serial-vision/raw/master/images/training-data.png)

*Sample of our training data*

After manually processing each picture, we combined the data into one set containing 3,200 images. This was plenty enough to meet our needs.

### Design
We used the Python library [Keras](https://keras.io) to help create and train our model. Keras is a high level API for ML development. Keras used Tensorflow under the hood to train our model. The resulting model was then converted to Apple's [Core ML](https://developer.apple.com/machine-learning) format and added to our iOS app project.

![Model](https://github.com/g-r-a-n-t/serial-vision/raw/master/images/model.png)

*Our model as defined in Keras*

We used a fairly standard design, in fact, this model had already been used by another developer to classify characters of a different font. That code can be found here.
https://github.com/DrNeuroSurg/OCRwithVisionAndCoreML-Part1

![CNN Example](https://github.com/g-r-a-n-t/serial-vision/raw/master/images/cnn-example.png)

*A nice CNN diagram (not ours, it's from Wikipedia)*

### Performance

The model was trained on 2,400 images and validated on 800 images with a batch size of 128 inputs over 6 epochs. Training takes under a minute and the accuracy is consistently above 98% on test data.

![Performance](https://github.com/g-r-a-n-t/serial-vision/raw/master/images/performance.png)

The performance of this model is equally as good on devices. Given that the characters are reasonably clear, the model will often predict with very high confidence the correct value.

## Analysis

The technology developed for this application would serve as a solid foundation for many use cases. Some brief examples include:

- Removing EOL devices from Jamf Pro
- Quick troubleshooting for common problems
- Querying device information such as: hardware, management status, and location/user information
- Updating user/location information
- Sending management commands (the possibilities of this would be endless)

Being able to quickly identify devices in Jamf Pro with a lightweight app would enable many forms of interaction that are not currently possible with just our web app. As it stands, if a user has a problem, the admin must manually search for that device in Jamf Pro using information provided by the user before they can start resolving the issue. If they are working with an ownerless device, they must copy the serial by hand into a search bar to identify it. We have confirmed with IT at Jamf that this would be a useful product. When asked for their thought, we were met with the response, "I've always wanted something like this, it would make my life so much easier." There's no doubt that this could be useful product for Jamf customers.
