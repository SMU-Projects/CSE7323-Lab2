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

@interface ModuleAViewController ()
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) FFTHelper *fftHelper;
@property (strong, nonatomic) Novocaine *audioManager;

@property (strong, nonatomic) SMUGraphHelper *graphHelper;

@property (weak, nonatomic) IBOutlet UILabel *frequencyLabel1;
@property (weak, nonatomic) IBOutlet UILabel *frequencyLabel2;


@end

@implementation ModuleAViewController

-(Novocaine*)audioManager{
    if(!_audioManager){
        _audioManager = [Novocaine audioManager];
    }
    return _audioManager;
}

-(CircularBuffer*)buffer{
    if(!_buffer){
        _buffer = [[CircularBuffer alloc]initWithNumChannels:1 andBufferSize:BUFFER_SIZE];
    }
    return _buffer;
}

-(SMUGraphHelper*)graphHelper{
    if(!_graphHelper){
        _graphHelper = [[SMUGraphHelper alloc]initWithController:self
                                        preferredFramesPerSecond:15
                                                       numGraphs:2
                                                       plotStyle:PlotStyleSeparated
                                               maxPointsPerGraph:BUFFER_SIZE];
    }
    return _graphHelper;
}

-(FFTHelper*)fftHelper{
    if(!_fftHelper){
        _fftHelper = [[FFTHelper alloc]initWithFFTSize:BUFFER_SIZE];
    }
    return _fftHelper;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.graphHelper setScreenBoundsBottomHalf];
    __block ModuleAViewController * __weak  weakSelf = self;
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
//        [weakSelf.buffer addNewFloatData:data withNumSamples:(numFrames*numChannels)];
        [weakSelf.buffer addNewInterleavedFloatData:data withNumSamples:numFrames*numChannels withNumChannels:numChannels];
    }];
    
    [self.audioManager play];
}

#pragma mark GLK Inherited Functions
//  override the GLKViewController update function, from OpenGLES
- (void)update{
    // just plot the audio stream
    
    // get audio stream data
    float* arrayData = malloc(sizeof(float)*BUFFER_SIZE);
    float* fftMagnitude = malloc(sizeof(float)*FFT_SIZE);
    
    [self.buffer fetchFreshData:arrayData withNumSamples:BUFFER_SIZE];
    
    //send off for graphing
    [self.graphHelper setGraphData:arrayData
                    withDataLength:BUFFER_SIZE
                     forGraphIndex:0];
    
    // take forward FFT
    [self.fftHelper performForwardFFTWithData:arrayData
                   andCopydBMagnitudeToBuffer:fftMagnitude];
    
    // graph the FFT Data
    [self.graphHelper setGraphData:fftMagnitude
                    withDataLength:FFT_SIZE
                     forGraphIndex:1
                 withNormalization:64.0
                     withZeroValue:-60];
    
    // Calculate fft frequencies
    int bucketSize = 10;
    int bucketArrayLength = FFT_SIZE / bucketSize;
    float* bucketArray = malloc(sizeof(float)*bucketArrayLength);
    float frequencyMax1 = -100;
    float frequencyMax2 = -100;
    for (int i = 0; i < FFT_SIZE; i++)
    {
        if (frequencyMax1 < fftMagnitude[i])
        {
            frequencyMax1 = fftMagnitude[i];
        }
    }
    
    self.frequencyLabel1.text = [[NSNumber numberWithFloat:frequencyMax1] stringValue];
    self.frequencyLabel2.text = @"f2:";
    
    [self.graphHelper update]; // update the graph
    free(arrayData);
    free(fftMagnitude);
//    free(bucketArray);
}

//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // draw the graph
}

- (void) viewDidDisappear:(BOOL)animated{
    [self.audioManager pause];
    [self.audioManager setInputBlock:nil];
}

@end
