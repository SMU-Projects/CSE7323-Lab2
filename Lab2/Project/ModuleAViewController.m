//
//  ModuleAViewController.m
//  Lab2
//
//  Created by Will Lacey on 10/1/19.
//  Copyright © 2019 Will Lacey. All rights reserved.
//

#import "ModuleAViewController.h"

@interface ModuleAViewController ()

@property (strong, nonatomic) AnalyzerModel *myAnalyzerModel; // Shared Analyzer Model

@property (strong, nonatomic) SMUGraphHelper *graphHelper; // SMU's GraphHelper Class

// Module A class properties for fft analysis
@property (nonatomic) float fftMagnitude1;
@property (nonatomic) float fftMagnitude2;
@property (nonatomic) int fftMagnitudeIndex1;
@property (nonatomic) int fftMagnitudeIndex2;

// Module A UI and NSTimer properties
@property (weak, nonatomic) IBOutlet UILabel *frequency1Label;
@property (weak, nonatomic) IBOutlet UILabel *frequency2Label;
@property (strong, nonatomic) IBOutlet NSTimer *timer;

@end

@implementation ModuleAViewController

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
@brief Getter for graphHelper property; preparest the GLKView for its graphs
*/
-(SMUGraphHelper*)graphHelper{
    if(!_graphHelper){
    _graphHelper = [[SMUGraphHelper alloc]initWithController:self
                                    preferredFramesPerSecond:30
                                                   numGraphs:2
                                                   plotStyle:PlotStyleSeparated
                                           maxPointsPerGraph:[_myAnalyzerModel getAudioDataSize]];
    }
    return _graphHelper;
}

#pragma mark Module A Specific Functions
/*!
@brief Method call that occurs when the view has loaded; initializes core Module A functionality
*/
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.graphHelper setScreenBoundsBottomHalf];
    
    // Prepares AudioManager; Accesses the Microphone
    [self.myAnalyzerModel useMicrophone];
    [self.myAnalyzerModel playAudioManager];
    
     // Initializes fftMagnitude properties to artificially low values for future calculations
    self.fftMagnitude1 = -1000;
    self.fftMagnitude2 = -1000;
    self.fftMagnitudeIndex1 = 0;
    self.fftMagnitudeIndex2 = 0;
    
    // Initialize Timer; Timer will call method updateLabels() every 200 milliseconds
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                  target:self
                                                selector:@selector(updateLabels)
                                                userInfo:nil
                                                 repeats:YES];
}

/*!
@brief Timer Method; Updates labels and resets class variables for next Timer interval
*/
-(void) updateLabels{
//     update labels to frequency values
    self.frequency1Label.text = [NSString stringWithFormat:@"f1: %fHz", [AnalyzerModel convertFftMagnitudeIndexToFrequency:self.fftMagnitudeIndex1]];
    self.frequency2Label.text = [NSString stringWithFormat:@"f2: %fHz", [AnalyzerModel convertFftMagnitudeIndexToFrequency:self.fftMagnitudeIndex2]];
    
    // reset frequency value until next timer interval
    self.fftMagnitude1 = -1000;
    self.fftMagnitude2 = -1000;
    self.fftMagnitudeIndex1 = 0;
    self.fftMagnitudeIndex2 = 0;
}

#pragma mark GLK Inherited Functions
/*!
@brief Overriden GLKViewController update function, from OpenGLES
*/
- (void)update{
    // Take forward FFT on audio data
    [self.myAnalyzerModel performFftOnAudio];
    
    // Collect useful variables from AnalyzerModel
    int sampleRate = [self.myAnalyzerModel getSampleRate];
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
    
    // Function Call to AnalyzerModel to collect the two loudest frequency indices this frame
    NSArray* fftMagnitudeIndices = [self.myAnalyzerModel getLoudestFftMagnitudeIndicesWithLowerFrequencyBounds:0 andUpperFrequencyBounds:sampleRate/2 usingFrequencyBucketSize:50];

    // The following code evaluates if the found FFT Magnitudes are significant within this Timer interval
    int newFftMagnitudeIndex1 = [[fftMagnitudeIndices objectAtIndex:0] intValue];
    int newFftMagnitudeIndex2 = [[fftMagnitudeIndices objectAtIndex:1] intValue];
    if (fftData[newFftMagnitudeIndex1] > self.fftMagnitude1)
    {
        self.fftMagnitude1 = fftData[newFftMagnitudeIndex1];
        self.fftMagnitudeIndex1 = newFftMagnitudeIndex1;
    }
    if (fftData[newFftMagnitudeIndex2] > self.fftMagnitude2)
    {
        self.fftMagnitude2 = fftData[newFftMagnitudeIndex2];
        self.fftMagnitudeIndex2 = newFftMagnitudeIndex2;
    }
    
    // Update the Graph
    [self.graphHelper update];
}

/*!
@brief Overriden GLKView draw function, from OpenGLES
*/
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // Draw the Graph
}

#pragma mark Closing Module A Functions
/*!
@brief Method call that occurs when the view has disappeared; Gracefully closes Ttimer and AnalyzerModel
*/
- (void) viewDidDisappear:(BOOL)animated{
    [self.myAnalyzerModel close];
    [self.timer invalidate];
}

@end
