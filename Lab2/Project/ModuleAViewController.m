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
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) FFTHelper *fftHelper;
@property (strong, nonatomic) Novocaine *audioManager;

@property (strong, nonatomic) SMUGraphHelper *graphHelper;

@property (strong, nonatomic) IBOutlet NSNumber *frequency1Number;
@property (strong, nonatomic) IBOutlet NSNumber *frequency2Number;
@property (weak, nonatomic) IBOutlet UILabel *frequency1Label;
@property (weak, nonatomic) IBOutlet UILabel *frequency2Label;
@property (strong, nonatomic) IBOutlet NSTimer *timer;


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

-(NSNumber*)frequency1Number{
    if(!_frequency1Number){
        _frequency1Number = @(-100);
    }
    return _frequency1Number;
}

-(NSNumber*)frequency2Number{
    if(!_frequency2Number){
        _frequency2Number = @(-100);
    }
    return _frequency2Number;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.graphHelper setScreenBoundsBottomHalf];
    __block ModuleAViewController * __weak  weakSelf = self;
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
        [weakSelf.buffer addNewInterleavedFloatData:data withNumSamples:numFrames*numChannels withNumChannels:numChannels];
    }];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                  target:self
                                                selector:@selector(updateLabels)
                                                userInfo:nil
                                                 repeats:YES];
    
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
    int bucketSize = 12; // while this value is hardcoded, I found it to be more accurate than the exact bucket size calculation
    // int bucketSize = (50 * FFT_SIZE) / (SAMPLE_RATE/2); // Exact bucket size to differentiate 50Hz difference
    int bucketIndexCount = 0; // Var to track bucket overflow; when bucket fills, evaluate local bucket max
    int bucketMaxIndex = 0; // Var to track local bucket max
    float frequencyMax1 = -100; // Loudest Frequency
    float frequencyMax2 = -100; // 2nd Loudest Frequency
    float tempFrequency = 0; //
    for (int i = 0; i < FFT_SIZE; i++)
    {
        // If bucket count overflow (or loop has finished), evaluate local bucket max relative to loudest frequencies
        if (bucketIndexCount == bucketSize || i == FFT_SIZE-1)
        {
            // Loudest Frequency Evaluation
            if (frequencyMax1 < fftMagnitude[bucketMaxIndex])
            {
                frequencyMax1 = fftMagnitude[bucketMaxIndex];
                
                // frequency = (max index) / (fft array length) * (sampling rate)
                tempFrequency = ((float)bucketMaxIndex / (float)FFT_SIZE) * SAMPLE_RATE/2;
                
                // if tempfrequency is greater than frequency1Number, update frequency1Number before next timer interval
                    // this code attempts to remove rapid fluctuations between timer intervals
                if([self.frequency1Number floatValue] < tempFrequency)
                {
                    self.frequency1Number = @(tempFrequency);
                }
            }
            // 2nd Loudest Frequency Evaluation
            else if (frequencyMax2 < fftMagnitude[bucketMaxIndex])
            {
                frequencyMax2 = fftMagnitude[bucketMaxIndex];
                
                // frequency = (max index) / (fft array length) * (sampling rate)
                tempFrequency = ((float)bucketMaxIndex / (float)FFT_SIZE) * SAMPLE_RATE/2;
                
                // if tempfrequency is greater than frequency1Number, update frequency1Number before next timer interval
                    // this code attempts to remove rapid fluctuations between timer intervals
                if([self.frequency2Number floatValue] < tempFrequency)
                {
                    self.frequency2Number = @(tempFrequency);
                }
            }
            // Reset bucket
            bucketIndexCount = 0;
            bucketMaxIndex = i;
        }
        
        // Calculate local bucket maximum
        if (fftMagnitude[bucketMaxIndex] < fftMagnitude[i])
        {
            bucketMaxIndex = i;
        }
        bucketIndexCount++; // Increment bucket count
    }
    
    [self.graphHelper update]; // update the graph
    free(arrayData);
    free(fftMagnitude);
}

-(void) updateLabels{
    self.frequency1Label.text = [NSString stringWithFormat:@"f1: %@Hz", self.frequency1Number];
    self.frequency2Label.text = [NSString stringWithFormat:@"f2: %@Hz", self.frequency2Number];
    self.frequency1Number = @(-100);
    self.frequency2Number = @(-100);
}

//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // draw the graph
}

- (void) viewDidDisappear:(BOOL)animated{
    [self.audioManager pause];
    [self.audioManager setInputBlock:nil];
    [self.timer invalidate];
}

@end
