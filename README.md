# Serial Vision

This is a smart app capable of detecting serial numbers on a device. It integrates with Jamf Pro so users can more easily manage devices when away from their computer.

## Technical Implementation
There are three main components to this app. The first is text detection, by this we mean detecting where characters are inside of an image. The second part is classifying the identified characters, this step provides us with probability distributions for each identified character. The third step is taking these probability distributions and inferring what serial number is contained in the image.

### Text Detection
Apple's general purpose language, Swift, contains a library named Vision. This library contains useful image analysis functionality. We used the text detection toolset to identify characters and crop them out one at a time. By doing so, we can generate the data required for character classification.

For example, say we are given this image of a MacBook Pro. The serial number is `CO2T83GXGTFM` as seen on the bottom right.

![MacBook Pro](https://raw.githubusercontent.com/g-r-a-n-t/serial-vision/master/images/macbook.png)

Running the text detection query in vision will provide us with the bounds for each `word` and `character` in the image. `Words` refers to a group of `characters`. You can see that the serial number is grouped along with some other characters.

![MacBook Pro Bounded](https://github.com/g-r-a-n-t/serial-vision/raw/master/images/macbook-bounded.png)

### Text classification

After finding the bounds of each character, we crop them out one at a time and run some basic preprocessing. The model required 28x28 greyscale images, so we must resize and adjust the colors. The resulting images are below.

![Characters](https://github.com/g-r-a-n-t/serial-vision/raw/master/images/characters.png)

These are just a handful of the results. There are as many images generated for classification as there are characters detected in the image. This sample starts at the closing parenthesis before "Serial" and ends at the mistakenly detected character on the far right.

We will now run these images through our CoreMl Model, a pre-trained alphanumeric classification model that we acquired online. The results on each image classification from left to right in descending order are below.

```
["V": 0.04213860630989075, "U": 0.0704030692577362, "M": 0.056483909487724304, "W": 0.6995975971221924]
...
<Serial Begins>
["C": 0.17175224423408508, "G": 0.0743417963385582, "8": 0.04917260259389877, "E": 0.6008208394050598]
["0": 0.11776313185691833, "Q": 0.13431929051876068, "O": 0.24109108746051788, "B": 0.1440122276544571]
["2": 0.2892942726612091, "D": 0.00848008319735527, "Z": 0.6954318284988403, "B": 0.0017834956524893641]
["J": 0.007001237943768501, "7": 0.011506869457662106, "I": 0.012427874840795994, "T": 0.9652963876724243]
["Z": 0.2578587234020233, "D": 0.07414213567972183, "8": 0.03716360777616501, "B": 0.5000070929527283]
["Z": 0.19050003588199615, "B": 0.08089062571525574, "S": 0.13467521965503693, "3": 0.5002305507659912]
["G": 0.8240635991096497, "S": 0.0878804549574852, "E": 0.021492158994078636, "B": 0.028437484055757523]
["Z": 0.0002905959845520556, "K": 0.0008230094681493938, "X": 0.9878068566322327, "Y": 0.010267496109008789]
["G": 0.6484586000442505, "S": 0.2940235137939453, "Q": 0.023909032344818115, "8": 0.010870172642171383]
["J": 0.0071387276984751225, "7": 0.015800638124346733, "I": 0.01613846980035305, "T": 0.955022394657135]
["F": 0.7725249528884888, "Z": 0.010324284434318542, "P": 0.08070458471775055, "E": 0.10984476655721664]
["V": 0.03197118267416954, "M": 0.1782636046409607, "Y": 0.008165350183844566, "W": 0.7643035054206848]
<Serial Ends>
...
["L": 0.036839403212070465, "J": 0.031821999698877335, "I": 0.04585861787199974, "1": 0.038113344460725784]
```

One of the problems that we have with this model is that it's not very confident. Take for example the first `C` in our serial number. The image clearly displays a `C`, but our model is only `17%` confident in that. In fact, it's actually `60%` sure that it's a `E`. Having a better model would certainly improve this project.

### Serial Identification

To deal with the lack of accuracy in our model, we must design an algorithm that can withstand some uncertainty. Having all the serial numbers we are looking for beforehand from Jamf Pro is very useful here. As you will see below, we do not need to have a high performing model to consistently get the correct serial number.

Let start off by asking how many combinations of each 4 probable characters are in a 12 character sequence. It would be `4^12 = 16777216`, not overwhelming, but certainly not efficient. If we were to do this for every 12 character sequences in the entire image, we could find a large set of possible serial numbers and their probabilities. From this, we could take the most likely sequence of 12 characters that resembles a serial number. Unfortunately, this would take too much time and be too inaccurate for our project. We should do better.

Let's do the same thing, but take the information from Jamf Pro into account. Let's say Jamf Pro provides us with a list of 1000 serials, what we could do is go through each partial serial starting from the front and build a hash table. For example, if we had the serial numbers `CO2T83GXGTFM` and `CO2T34FYVSTG` in our Jamf Pro server, we would build a hash table that contains these values.

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
This would result in a hash table of at most 12000 entries, not very big. So what's the point of going through all of this hassle? It gives us the ability to quickly prune off non-existent serials when generating probable combinations. So when our algorithm is generating combinations, the amount is reduced only to those that are in Jamf Pro. Here it is stepping though the probability distribution sequence containing our serial number.
```
["G", "C", "E", "8"]
Is G in the hash table: No
Is C in the hash table: Yes
Is E in the hash table: No
Is 8 in the hash table: No
["Q", "0", "O", "B"]
Is CQ in the hash table: No
Is C0 in the hash table: No
Is CO in the hash table: Yes
Is CB in the hash table: No
["Z", "2", "D", "B"]
Is COZ in the hash table: No
Is CO2 in the hash table: Yes
Is COD in the hash table: No
Is COB in the hash table: No
["T", "7", "J", "I"]
Is CO2T in the hash table: Yes
Is CO27 in the hash table: No
Is CO2J in the hash table: No
Is CO2I in the hash table: No
["Z", "D", "8", "B"]
Is CO2TZ in the hash table: No
Is CO2TD in the hash table: No
Is CO2T8 in the hash table: Yes
Is CO2TB in the hash table: No
["Z", "3", "S", "B"]
...
["G", "E", "S", "B"]
["Z", "Y", "X", "K"]
["G", "S", "8", "Q"]
["T", "7", "J", "I"]
["Z", "P", "E", "F"]
["M", "W", "Y", "V"]
Is CO2T83GXGTFM in the hash table: Yes
Is CO2T83GXGTFW in the hash table: No
Is CO2T83GXGTFY in the hash table: No
Is CO2T83GXGTFV in the hash table: No
```
Our algorithm has correctly identified the serial number `CO2T83GXGTFM`. This only took roughly `4 * 12 = 48` computations as opposed to `4 ^ 12 = 16777216`, which is much faster.

### Analysis

The obvious trade off with this method as opposed to building a more accurate model is that our algorithm could misidentify as serial number that just so happens to be in one of the probability distribution sequences. The odds of this are slim with a distribution size of 4. For our algorithm to identify the wrong serial in an image containing 50 characters and a Jamf Pro containing 100,000 devices, it would take `(((4/36)^12) * 38) * 100,000 = 1 in 74,323 odds` Having a more accurate model would certainly help, but for the time we have, it may not happen.
