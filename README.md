# Serial Vision

A smart app capable of detecting serial numbers on a device. It integrates with a Jamf Pro server to enables quick and easy management of devices.

## Technical Implementation
There are three main components to this app. The first is text detection, by this we mean detecting where characters are inside of an image. The second part is classifying the identified characters, this step is provides us with probability distributions for each identified character. The third step is taking these probability distributions and using that information with what information is provided by Jamf Pro to confidently identify the serial number being displayed in the image.

### Text Detection
We used Swift's Vision library to solve this problem. Vision provides reliable tools for analyzing images. We used the text detection tools provided in this library to identify characters and crop them out one at a time. This is how we set up character classification.

For example, say we are given this image of a device:

![MacBook Pro](https://raw.githubusercontent.com/g-r-a-n-t/serial-vision/master/images/device-back.png)

Running text detection provides a result like this:

![MacBook Pro Bounded](https://github.com/g-r-a-n-t/serial-vision/raw/master/images/bounded-characters.png)

### Text classification

After finding the bounds of each character, we crop them out one at a time and run some basic preprocessing. The result is like this:

![Characters](https://github.com/g-r-a-n-t/serial-vision/raw/master/images/cropped-characters.png)

^^^ fix this image

These are just a handful of the results. If you look closely, you can see where the characters correspond with the raw image. It starts just before "Serial" and ends with the logo that looks like and "E". The images surrounded by red a part of the serial number.

We will now run these images through our CoreMl Model, a pre-trained model which we found online that categorizes capital letters and digits. The result on each character from left to right descending are:

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

One of the problems that we have with this model is that it's not very confident. Take for example the first "C" in our serial number. The image clearly displays a "C", but out model is only 17% confident in that. In fact, it's actually 60% sure that it's a "E". This is probably because this model was trained on different fonts and its not very familiar with this particular shape.

### Serial Identification

To deal with this lack of accuracy in our model, we have to design an algorithm that can handle a little uncertainty. Since we are given all of the serial numbers from our Jamf Pro server, we can take that information into account and make an educated guess.

Let start off by asking how many combinations of each 4 probable characters in a 12 character sequence there are. It would be `4^12 = 16777216`, not overwhelming, but certainly not efficient. If we were to do this for every 12 character sequences in the entire image, we could find a large set of possible serial numbers and there probabilities. Not a bad start.

Now let's do the same thing, but take the information from Jamf Pro into account. Let's say Jamf Pro provides us a list of 1000 serials, what we could do is go through each partial serial starting from the front and build a hash table. So if we had the serial numbers CO2T83GXGTFM and CO2T34FYVSTG in our Jamf Pro Server, that would add these values to our hash table:
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
CO2
CO2T
CO2T3
CO2T34
CO2T34F
CO2T34FY
CO2T34FYV
CO2T34FYVS
CO2T34FYVST
CO2T34FYVSTG
```
This results in a hash table with a maximum size of 12000. So whats the point of going through all of this hassle? It gives us the ability to quickly prune off non-existent serials preemptively when generating probable combinations. The resulting calculations goes like this.
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

And there we have it, CO2T83GXGTFM is our serial number. We can now contact the Jamf Pro server and do whatever we would like to with this device.
