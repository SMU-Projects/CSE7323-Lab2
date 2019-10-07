//
//  ModuleAViewController.m
//  Lab2
//
//  Created by Will Lacey on 10/1/19.
//  Copyright © 2019 Will Lacey. All rights reserved.
//

#import "ModuleBViewController.h"

@interface ModuleBViewController ()

@property (strong, nonatomic) AnalyzerModel *myAnalyzerModel; // Shared Analyzer Model

@property (strong, nonatomic) SMUGraphHelper *graphHelper; // SMU's GraphHelper Class

// Module B class properties for fft analysis
@property (strong, nonatomic) IBOutlet NSNumber *frequencyValue;

// Module B UI properties
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UILabel *frequencyLabel;
@property (weak, nonatomic) IBOutlet UILabel *loudnessLabel;
@property (weak, nonatomic) IBOutlet UILabel *gestureLabel;

@end

@implementation ModuleBViewController

#pragma mark Property Getters
/*!
@brief Declares myAnalyzerModel as a shared instance
*/
-(AnalyzerModel*)myAnalyzerModel{
    
    if(!_myAnalyzerModel)
        _myAnalyzerModel = [AnalyzerModel sharedInstance];
    
    return _myAnalyzerModel;
}

/*!
@brief Getter for the slider's frequencyValue; Serves as an in between property for the UI and AudioManager queues
*/
-(NSNumber*)frequencyValue{
    if(!_frequencyValue){
        _frequencyValue = @(19000); // 19 kHz
    }
    return _frequencyValue;
}

/*!
@brief Getter for graphHelper property; preparest the GLKView for its graphs
*/
-(SMUGraphHelper*)graphHelper {
    if(!_graphHelper){
        _graphHelper = [[SMUGraphHelper alloc]initWithController:self
                                        preferredFramesPerSecond:30
                                                       numGraphs:2
                                                       plotStyle:PlotStyleSeparated
                                               maxPointsPerGraph:[self.myAnalyzerModel getAudioDataSize]];
    }
    return _graphHelper;
}

#pragma mark Module B Specific Functions
/*!
@brief Method call that occurs when the view has loaded; initializes core Module B functionality
*/
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.graphHelper setScreenBoundsBottomHalf];
    
    // Prepares AudioManager; Accesses the Microphone and Speaker
    [self.myAnalyzerModel useMicrophone];
    [self.myAnalyzerModel useSpeaker:[self.frequencyValue floatValue]];
    [self.myAnalyzerModel playAudioManager];

}

/*!
@brief Method call that occurs when a slider action has occured; changes the frequency of the speaker output
*/
- (IBAction)sliderAction:(id)sender {
    self.frequencyValue = @(self.slider.value);
    [self.myAnalyzerModel useSpeaker:[self.frequencyValue floatValue]];
    self.frequencyLabel.text = [NSString stringWithFormat:@"%@ kHz", self.frequencyValue];
}

#pragma mark GLK Inherited Functions
//  override the GLKViewController update function, from OpenGLES
- (void)update {
    // Take forward FFT on audio data
    [self.myAnalyzerModel performFftOnAudio];
    
    // Collect useful variables from AnalyzerModel
    float* audioData = [self.myAnalyzerModel getAudioData];
    int audioDataSize = [self.myAnalyzerModel getAudioDataSize];
    float* fftData = [self.myAnalyzerModel getFftData];
    int fftDataSize = [self.myAnalyzerModel getFftDataSize];
    
    // Graph Raw Audio Data
    [self.graphHelper setGraphData:audioData
                    withDataLength:audioDataSize
                     forGraphIndex:0
     ];
    
    // Graph FFT Data
    [self.graphHelper setGraphData:fftData
                    withDataLength:fftDataSize
                     forGraphIndex:1
                 withNormalization:64.0
                     withZeroValue:-60
     ];
    
    // Function Call to AnalyzerModel to find the range of the FFT signal; returns the difference between the greatest and lowest value
    float fftRange = [self.myAnalyzerModel getFftRangeWithLowerFrequencyBounds:14500 andUpperFrequencyBounds:20500];
    
    // Function Call to AnalyzerModel to collect the two loudest frequency indices this frame
    NSArray* fftMagnitudeIndices = [self.myAnalyzerModel getLoudestFftMagnitudeIndicesWithLowerFrequencyBounds:14500 andUpperFrequencyBounds:20500 usingFrequencyBucketSize:60];
    
    // The following code evaluates the doppler effect from the speaker output and the gestures made by the user
    int fftMagnitudeIndex1 = [[fftMagnitudeIndices objectAtIndex:0] intValue];
    int fftMagnitudeIndex2 = [[fftMagnitudeIndices objectAtIndex:1] intValue];
    float lowestFftMagnitude = fftData[fftMagnitudeIndex1] - fftRange;
    float doppler1 = fftData[fftMagnitudeIndex1] + fabsf(lowestFftMagnitude);
    float doppler2 = fftData[fftMagnitudeIndex2] + fabsf(lowestFftMagnitude);
    if(doppler1 < 1.5*doppler2)
    {
        if(fftMagnitudeIndex1 > fftMagnitudeIndex2)
        {
            self.gestureLabel.text = @"gesturing away";
        }
        else
        {
            self.gestureLabel.text = @"gesturing towards";
        }
    }
    else
    {
        self.gestureLabel.text = @"not gesturing";
    }
    
    // Output the loudness of the FFT Magnitude in Decibels (...I honestly just didn't know what formula or data to use for this calculation, below are some other ideas I had)
    self.loudnessLabel.text = [NSString stringWithFormat:@"%f dB", fftData[fftMagnitudeIndex1]];
    
//    self.loudnessLabel.text = [NSString stringWithFormat:@"%f dB", 20*logf(fabsf(audioData[fftMagnitudeIndex1]))];
    
//    self.loudnessLabel.text = [NSString stringWithFormat:@"%f dB", 20*logf(fftData[fftMagnitudeIndex1])];
    
    // Update the Graph
    [self.graphHelper update];
}

/*!
@brief Overriden GLKView draw function, from OpenGLES
*/
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // Draw the Graph
}

#pragma mark Closing Module B Functions
/*!
@brief Method call that occurs when the view has disappeared; Gracefully closes AnalyzerModel
*/
- (void) viewDidDisappear:(BOOL)animated{
    [self.myAnalyzerModel close];
}

@end
