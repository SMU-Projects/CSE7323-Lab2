//
//  ModuleAViewController.m
//  Lab2
//
//  Created by Will Lacey on 10/1/19.
//  Copyright © 2019 Will Lacey. All rights reserved.
//

#import "ModuleBViewController.h"

@interface ModuleBViewController ()

@property (strong, nonatomic) AnalyzerModel *myAnalyzerModel;

@property (strong, nonatomic) SMUGraphHelper *graphHelper;

@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (strong, nonatomic) IBOutlet NSNumber *frequencyValue;
@property (weak, nonatomic) IBOutlet UILabel *frequencyLabel;
@property (weak, nonatomic) IBOutlet UILabel *loudnessLabel;
@property (weak, nonatomic) IBOutlet UILabel *gestureLabel;

@end

@implementation ModuleBViewController

-(AnalyzerModel*)myAnalyzerModel{
    
    if(!_myAnalyzerModel)
        _myAnalyzerModel = [AnalyzerModel sharedInstance];
    
    return _myAnalyzerModel;
}

-(NSNumber*)frequencyValue{
    if(!_frequencyValue){
        _frequencyValue = @(19000);
    }
    return _frequencyValue;
}

-(SMUGraphHelper*)graphHelper {
    if(!_graphHelper){
        _graphHelper = [[SMUGraphHelper alloc]initWithController:self
                                        preferredFramesPerSecond:30
                                                       numGraphs:2
                                                       plotStyle:PlotStyleSeparated
                                               maxPointsPerGraph:[_myAnalyzerModel getAudioDataSize]];
    }
    return _graphHelper;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.graphHelper setScreenBoundsBottomHalf];
    
    [self.myAnalyzerModel useMicrophone];
    [self.myAnalyzerModel useSpeaker:[self.frequencyValue floatValue]];
    [self.myAnalyzerModel playAudioManager];

}

#pragma mark GLK Inherited Functions
//  override the GLKViewController update function, from OpenGLES
- (void)update {
    // take forward FFT
    [self.myAnalyzerModel performFftOnAudio];
    
    int sampleRate = [self.myAnalyzerModel getSampleRate];
    
    float* audioData = [self.myAnalyzerModel getAudioData];
    int audioDataSize = [self.myAnalyzerModel getAudioDataSize];
    
    float* fftData = [self.myAnalyzerModel getFftData];
    int fftDataSize = [self.myAnalyzerModel getFftDataSize];
    
    //send off for graphing
    [self.graphHelper setGraphData:audioData
                    withDataLength:audioDataSize
                     forGraphIndex:0
//                    withNormalization:2
//                    withZeroValue:0
     ];
    
    // graph the FFT Data
    [self.graphHelper setGraphData:fftData
                    withDataLength:fftDataSize
                     forGraphIndex:1
                 withNormalization:64.0
                     withZeroValue:-60
     ];
    
    float fftRange = [self.myAnalyzerModel getFftRangeWithLowerFrequencyBounds:14500 andUpperFrequencyBounds:20500];
    
    NSArray* fftMagnitudeIndices = [self.myAnalyzerModel getLoudestFftMagnitudeIndicesWithLowerFrequencyBounds:14500 andUpperFrequencyBounds:20500 usingFrequencyBucketSize:60];
    
    int fftMagnitudeIndex1 = [[fftMagnitudeIndices objectAtIndex:0] intValue];
    int fftMagnitudeIndex2 = [[fftMagnitudeIndices objectAtIndex:1] intValue];
    
//    NSLog([NSString stringWithFormat:@"F1: %f", [AnalyzerModel convertFftMagnitudeIndexToFrequency:f1]]);
//    NSLog([NSString stringWithFormat:@"F2: %f", [AnalyzerModel convertFftMagnitudeIndexToFrequency:f2]]);
//
//    NSLog([NSString stringWithFormat:@"range: %f", fftRange]);
//
    float lowestFftMagnitude = fftData[fftMagnitudeIndex1] - fftRange;
    float fftMagnitude1 = fftData[fftMagnitudeIndex1] + fabsf(lowestFftMagnitude);
    
    float fftMagnitude2 = fftData[fftMagnitudeIndex2] + fabsf(lowestFftMagnitude);
    
    if(fftMagnitude1 < 1.5*fftMagnitude2)
    {
        if(fftMagnitudeIndex1 > fftMagnitudeIndex2)
        {
            self.gestureLabel.text = @"gesturing away";
        }
        else{
            self.gestureLabel.text = @"gesturing towards";
        }
    }
    else
    {
        self.gestureLabel.text = @"not gesturing";
    }
    
    self.loudnessLabel.text = @"ERROR CHANGE";
    
    [self.graphHelper update]; // update the graph
    free(audioData);
    free(fftData);
}

//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // draw the graph
}

- (IBAction)sliderAction:(id)sender {
    self.frequencyValue = @(self.slider.value);
    [self.myAnalyzerModel useSpeaker:[self.frequencyValue floatValue]];
    self.frequencyLabel.text = [NSString stringWithFormat:@"%@ kHz", self.frequencyValue];
}


- (void) viewDidDisappear:(BOOL)animated{
    [self.myAnalyzerModel close];
}

@end
