# Audio Filtering, the FFT, and Doppler Shifts

#### Complete Both Modules of the Assignment:
#### Module A 
Create an iOS application using the example template that:
```

- Reads from the microphone
- Takes an FFT of the incoming audio stream
- Displays the frequency of the two loudest tones within (+-3Hz) accuracy 
	- Have a way to "lock in" the last frequencies detected on the display
-Is able to distinguish tones at least 50Hz apart, lasting for 200ms or more
- An idea for Exceptional Credit: recognize two tones played on a piano (down to one half step apart) and report them by letter (i.e., A4, A#4). Must work at note A2 and above. Note: this is harder than just identifying two perfect sine waves!!
- Exceptional Credit Idea (<strong>required for 7000 level students</strong>): make the FFT analysis follow the model-view-controller framework more closely. That is, make the model an analyzer that is not implemented in the View Controller (i.e., an "analyzer model"). All audio saving and analysis should happen in the model only, not the view controller. The audio analysis should be performed using blocks on a serial queue. Once analysis is complete, a view controller can ask the model for FFT frames, and the view controller can display those frames however it wants. You should design functions for accessing the result of the analyzer such that memory and computation time are reasonable. 
```
Verify the functionality of the application to the instructor during lab time or office hours (or scheduled via email). The sound source must be external to the phone (i.e., laptop, instrument, another phone, etc.).

#### Module B
Create an iOS application using the example template that:
```
- Reads from the microphone
- Plays a settable (via a slider or setter control) inaudible tone to the speakers (15-20kHz)
- Displays the magnitude of the FFT of the microphone data in decibels
- Is able to distinguish when the user is {not gesturing, gestures toward, or gesturing away} from the microphone using Doppler shifts in the frequency
```

### Turn in: 

* The source code for your app in zipped format or via GitHub. (Upload as "teamNameAssignmentTwo.zip".) Use proper coding techniques and naming conventions for swift, objective C, and objective C++.
* Your team member names and team name in the comments for main files.
* A video of the app functioning properly 

[5 points] Proper Interface Design (navigation and auto layout)
[25 points] Algorithms Design (efficiency, argmax finding, proper sampling, and ring buffer use, etc.)
[30 points] Module A (frequency displayed, 6Hz accuracy, 200 ms duration, 50 Hz difference)
[30 points] Module B (tone is settable, FFT displayed properly, Accurate gesture detection across all settable tones)
[10 points] Exceptional (free reign to make updates: perhaps using the gestures as a form of control in the app, or implementing more than just towards/away detection, etc.)

### Grading Rubric
|   Points          |     Feature    |
|      :---:        |      :---:     |
| [5 points] 		| Proper Interface Design (navigation and auto layout) 			 |
| [25 points]		| Algorithms Design (efficiency, argmax finding, proper sampling, and ring buffer use, etc.) 			 |
| [30 points]		| Module A (frequency displayed, 6Hz accuracy, 200 ms duration, 50 Hz difference)			 |
| [30 points]		| Module B (tone is settable, FFT displayed properly, Accurate gesture detection across all settable tones)  			 |
| [10 points]		| Exceptional (free reign to make updates: perhaps using the gestures as a form of control in the app, or implementing more than just towards/away detection, etc.)  			 |
