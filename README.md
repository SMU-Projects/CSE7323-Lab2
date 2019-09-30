# Audio Filtering, the FFT, and Doppler Shifts

#### Complete Both Modules of the Assignment:
#### Module A 
Create an iOS application using the example template that:
- Reads from the microphone
- Takes an FFT of the incoming audio stream
- Displays the frequency of the two loudest tones within (+-3Hz) accuracy 
	- Have a way to "lock in" the last frequencies detected on the display
-Is able to distinguish tones at least 50Hz apart, lasting for 200ms or more
- An idea for Exceptional Credit: recognize two tones played on a piano (down to one half step apart) and report them by letter (i.e., A4, A#4). Must work at note A2 and above. Note: this is harder than just identifying two perfect sine waves!!
- Exceptional Credit Idea (<strong>required for 7000 level students</strong>): make the FFT analysis follow the model-view-controller framework more closely. That is, make the model an analyzer that is not implemented in the View Controller (i.e., an "analyzer model"). All audio saving and analysis should happen in the model only, not the view controller. The audio analysis should be performed using blocks on a serial queue. Once analysis is complete, a view controller can ask the model for FFT frames, and the view controller can display those frames however it wants. You should design functions for accessing the result of the analyzer such that memory and computation time are reasonable. 

### Required for 5000 and 7000 Students:

```
Automatic Layout 
Buttons, Sliders, and Labels
Stepper and Switch
Picker (you must implement picker delegate)
Segmented Control
Timer (which should repeat and somehow update the UIView)
ScrollView (with scrollable, zoomable content)
Image View
Navigation Controller
Collection View Controller
Table View Controller with three different dynamic prototype cells
The design should work in both portrait and landscape mode
I should not be able to crash your app
Your design must strictly adhere to Model View Controller programming practices
Use lazy instantiation when possible
```

### Exceptional Credit for 5000 students and Required for 7000 students:

```
Implement a modal view and handle properly using custom protocols/delegation
Test your app running on the device, not the emulator to ensure it runs in all scenarios. 
Also see the grading rubric for how much each element is worth. 
```

### Turn in: 

* The source code for your app via upload or github link (if uploading, call the file "teamNameAssignmentOne.zip"). Use proper coding techniques and naming conventions for objective C and/or swift. Use whichever programming language you are most comfortable with.
* Your team member names and team name 
* A video of your working app

### Grading Rubric
|   Feature         |     Points     |
|      :---:        |      :---:     |
| Coding Techniques	| 10 			 |
| MVC Paradigm		| 10 			 |
| Auto Layout		| 10			 |
| Landscape Portrait| 5  			 |
| Button			| 1  			 |
| Slider			| 1  			 |
| Label				| 1 			 |
| Stepper			| 1 			 |
| Switch			| 1 			 |
| Picker			| 5 			 |
| Proper Navigation	| 4  			 |
| Seg. Control		| 2 			 |
| Timer				| 4  			 |
| ScrollView		| 10 			 |
| Collection View	| 10 			 |
| Image View		| 5  			 |
| TableView			| 10 |