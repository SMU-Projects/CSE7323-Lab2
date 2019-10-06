//
//  ModuleAViewController.m
//  Lab2
//
//  Created by Will Lacey on 10/1/19.
//  Copyright © 2019 Will Lacey. All rights reserved.
//

#import "ModuleBViewController.h"

#define BUFFER_SIZE (2048*4)
#define FFT_SIZE (BUFFER_SIZE/2)
#define SAMPLE_RATE 44100

@interface ModuleBViewController ()
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) FFTHelper *fftHelper;
@property (strong, nonatomic) Novocaine *audioManager;

@property (strong, nonatomic) SMUGraphHelper *graphHelper;

@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (strong, nonatomic) IBOutlet NSNumber *frequencyValue;
@property (weak, nonatomic) IBOutlet UILabel *frequencyLabel;
@property (weak, nonatomic) IBOutlet UILabel *loudnessLabel;
@property (weak, nonatomic) IBOutlet UILabel *gestureLabel;

@property (strong, nonatomic) IBOutlet NSNumber *frequency1Number;
@property (strong, nonatomic) IBOutlet NSNumber *frequency2Number;
@property (nonatomic) int frequency1Index;
@property (nonatomic) int frequency2Index;

@end

@implementation ModuleBViewController

-(NSNumber*)frequencyValue{
    if(!_frequencyValue){
        _frequencyValue = @(19);
    }
    return _frequencyValue;
}

-(Novocaine*)audioManager{
    if(!_audioManager){
        _audioManager = [Novocaine audioManager];
    }
    return _audioManager;
}

-(CircularBuffer*)buffer {
    if(!_buffer){
        _buffer = [[CircularBuffer alloc]initWithNumChannels:1 andBufferSize:BUFFER_SIZE];
    }
    return _buffer;
}

-(SMUGraphHelper*)graphHelper {
    if(!_graphHelper){
        _graphHelper = [[SMUGraphHelper alloc]initWithController:self
                                        preferredFramesPerSecond:15
                                                       numGraphs:2
                                                       plotStyle:PlotStyleSeparated
                                               maxPointsPerGraph:BUFFER_SIZE];
    }
    return _graphHelper;
}

-(FFTHelper*)fftHelper {
    if(!_fftHelper){
        _fftHelper = [[FFTHelper alloc]initWithFFTSize:BUFFER_SIZE];
    }
    return _fftHelper;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.graphHelper setScreenBoundsBottomHalf];
    
    __block ModuleBViewController * __weak  weakSelf = self;
    
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
        [weakSelf.buffer addNewInterleavedFloatData:data withNumSamples:numFrames*numChannels withNumChannels:numChannels];
    }];
    
    __block float phase = 0.0;
    [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
        double phaseIncrement = 2000*M_PI*[self.frequencyValue floatValue]/SAMPLE_RATE;
        double sineWavePeriod = 2*M_PI;
        for (int i=0; i < numFrames; ++i)
        {
            for(int j=0;j<numChannels;j++)
                data[i*numChannels+j] = 0.5*sin(phase);
            
            phase += phaseIncrement;
            if (phase >= sineWavePeriod) phase -= 2*M_PI;
        }
    }];
    
    [self.audioManager play];
}

#pragma mark GLK Inherited Functions
//  override the GLKViewController update function, from OpenGLES
- (void)update {
    // just plot the audio stream
    
    // get audio stream data
    float* arrayData = malloc(sizeof(float)*BUFFER_SIZE);
    float* fftMagnitude = malloc(sizeof(float)*FFT_SIZE);
    
    [self.buffer fetchFreshData:arrayData withNumSamples:BUFFER_SIZE];
    
    //send off for graphing
    [self.graphHelper setGraphData:arrayData
                    withDataLength:BUFFER_SIZE
                     forGraphIndex:0
//                    withNormalization:2
//                    withZeroValue:0
     ];
    
    // take forward FFT
    [self.fftHelper performForwardFFTWithData:arrayData
                   andCopydBMagnitudeToBuffer:fftMagnitude];
    
    // graph the FFT Data
    [self.graphHelper setGraphData:fftMagnitude
                    withDataLength:FFT_SIZE
                     forGraphIndex:1
                 withNormalization:64.0
                     withZeroValue:-60
     ];
    
    int lowerBounds = (14500 * FFT_SIZE) / (SAMPLE_RATE/2); // 14500 frequency index
    int upperBounds = (20500 * FFT_SIZE) / (SAMPLE_RATE/2); // 20500 frequency index
    
    // Normalization of FFT
    float lowestValue = 1000;
    for (int i = lowerBounds; i < upperBounds; i++)
    {
        if (fftMagnitude[i] < lowestValue)
        {
            lowestValue = fftMagnitude[i];
        }
    }
    for (int i = lowerBounds; i < upperBounds; i++)
    {
        fftMagnitude[i] += fabsf(lowestValue);
    }

    int bucketSize = (60 * FFT_SIZE) / (SAMPLE_RATE/2); // Exact bucket size to differentiate 60Hz difference
    int bucketIndexCount = 0; // Var to track bucket overflow; when bucket fills, evaluate local bucket max
    int bucketMaxIndex = 0; // Var to track local bucket max
    for (int i = lowerBounds; i < upperBounds; i++)
    {
    // If bucket count overflow (or loop has finished), evaluate local bucket max relative to loudest frequencies
        if (bucketIndexCount == bucketSize || i == FFT_SIZE-1)
        {
            // Loudest Frequency Evaluation
            if ([self.frequency1Number floatValue] < fftMagnitude[bucketMaxIndex])
            {
                // set frequency2 variables to previous frequency1 variables if the bucketMaxIndex is not too close to previous f1
                if (!(bucketMaxIndex < (self.frequency1Index + bucketSize/2) && bucketMaxIndex > (self.frequency1Index - bucketSize/2)))
                {
                    self.frequency2Index = self.frequency1Index;
                    self.frequency2Number = @([self.frequency1Number floatValue]);
                }
                self.frequency1Index = bucketMaxIndex;
                self.frequency1Number = @(fftMagnitude[bucketMaxIndex]);
            }
            // 2nd Loudest Frequency Evaluation; f2 cannot be too close to f1
            else if ([self.frequency2Number floatValue] < fftMagnitude[bucketMaxIndex] && !(bucketMaxIndex < (self.frequency1Index + bucketSize/2) && bucketMaxIndex > (self.frequency1Index - bucketSize/2)))
            {
                self.frequency2Index = bucketMaxIndex;
                self.frequency2Number = @(fftMagnitude[bucketMaxIndex]);
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
    
    if([self.frequency1Number floatValue] < 1.5*[self.frequency2Number floatValue])
    {
        if(self.frequency1Index > self.frequency2Index)
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
    
    self.frequency1Number = @(-100);
    self.frequency2Number = @(-100);
    self.frequency1Index = 0;
    self.frequency2Index = 0;
    
    self.loudnessLabel.text = @"ERROR CHANGE";
    
    // Print Frequency
//    self.loudnessLabel.text = [@(self.frequency1Index / (float)FFT_SIZE * SAMPLE_RATE/2) stringValue];
    
    // Print Loudness
//    self.loudnessLabel.text = [NSString stringWithFormat:@"%@ dB", @(20 * log10f(fabsf(fftMagnitude[(int)self.frequency1Index])))];
    
    [self.graphHelper update]; // update the graph
    free(arrayData);
    free(fftMagnitude);
}

//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // draw the graph
}

- (IBAction)sliderAction:(id)sender {
    self.frequencyValue = @(self.slider.value);
    self.frequencyLabel.text = [NSString stringWithFormat:@"%@ kHz", self.frequencyValue];
}


- (void) viewDidDisappear:(BOOL)animated{
    [self.audioManager pause];
    [self.audioManager setInputBlock:nil];
    [self.audioManager setOutputBlock:nil];
}

@end
