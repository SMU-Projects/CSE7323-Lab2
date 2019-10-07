//
//  ModuleAViewController.m
//  Lab2
//
//  Created by Will Lacey on 10/1/19.
//  Copyright © 2019 Will Lacey. All rights reserved.
//

#import "ModuleAViewController.h"

#define BUFFER_SIZE (2048*4)
#define FFT_SIZE (BUFFER_SIZE/2)
#define SAMPLE_RATE 44100

@interface ModuleAViewController ()

@property (strong, nonatomic) AnalyzerModel *myAnalyzerModel;

@property (strong, nonatomic) SMUGraphHelper *graphHelper;

@property (nonatomic) float fftMagnitude1;
@property (nonatomic) float fftMagnitude2;
@property (nonatomic) int fftMagnitudeIndex1;
@property (nonatomic) int fftMagnitudeIndex2;

@property (weak, nonatomic) IBOutlet UILabel *frequency1Label;
@property (weak, nonatomic) IBOutlet UILabel *frequency2Label;
@property (strong, nonatomic) IBOutlet NSTimer *timer;

@end

@implementation ModuleAViewController

-(AnalyzerModel*)myAnalyzerModel{
    
    if(!_myAnalyzerModel)
        _myAnalyzerModel = [AnalyzerModel sharedInstance];
    
    return _myAnalyzerModel;
}

-(SMUGraphHelper*)graphHelper{
    if(!_graphHelper){
        _graphHelper = [[SMUGraphHelper alloc]initWithController:self
                                        preferredFramesPerSecond:30
                                                       numGraphs:2
                                                       plotStyle:PlotStyleSeparated
                                               maxPointsPerGraph:BUFFER_SIZE];
    }
    return _graphHelper;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.graphHelper setScreenBoundsBottomHalf];
    
    [self.myAnalyzerModel useMicrophone];
    [self.myAnalyzerModel playAudioManager];
    
    self.fftMagnitude1 = -1000;
    self.fftMagnitude2 = -1000;
    self.fftMagnitudeIndex1 = 0;
    self.fftMagnitudeIndex2 = 0;
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                  target:self
                                                selector:@selector(updateLabels)
                                                userInfo:nil
                                                 repeats:YES];
}

#pragma mark GLK Inherited Functions
//  override the GLKViewController update function, from OpenGLES
- (void)update{
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
    
        NSArray* fftMagnitudeIndices = [self.myAnalyzerModel getLoudestFftMagnitudeIndicesWithLowerFrequencyBounds:0 andUpperFrequencyBounds:sampleRate/2 usingFrequencyBucketSize:50];

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
    
    [self.graphHelper update]; // update the graph
}

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

//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // draw the graph
}

- (void) viewDidDisappear:(BOOL)animated{
    [self.myAnalyzerModel close];
    [self.timer invalidate];
}

@end
