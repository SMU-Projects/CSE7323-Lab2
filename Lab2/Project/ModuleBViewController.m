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

@property (strong, nonatomic) IBOutlet NSNumber *frequency1Number;
@property (strong, nonatomic) IBOutlet NSNumber *frequency2Number;
@property (nonatomic) int frequency1Index;
@property (nonatomic) int frequency2Index;

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
    
    
    
    int lowerBounds = (14500 * fftDataSize) / (sampleRate/2); // 14500 frequency index
    int upperBounds = (20500 * fftDataSize) / (sampleRate/2); // 20500 frequency index
    
    // Normalization of FFT
    float lowestValue = 1000;
    for (int i = lowerBounds; i < upperBounds; i++)
    {
        if (fftData[i] < lowestValue)
        {
            lowestValue = fftData[i];
        }
    }
    for (int i = lowerBounds; i < upperBounds; i++)
    {
        fftData[i] += fabsf(lowestValue);
    }

    int bucketSize = (60 * fftDataSize) / (sampleRate/2); // Exact bucket size to differentiate 60Hz difference
    int bucketIndexCount = 0; // Var to track bucket overflow; when bucket fills, evaluate local bucket max
    int bucketMaxIndex = 0; // Var to track local bucket max
    for (int i = lowerBounds; i < upperBounds; i++)
    {
    // If bucket count overflow (or loop has finished), evaluate local bucket max relative to loudest frequencies
        if (bucketIndexCount == bucketSize || i == fftDataSize-1)
        {
            // Loudest Frequency Evaluation
            if ([self.frequency1Number floatValue] < fftData[bucketMaxIndex])
            {
                // set frequency2 variables to previous frequency1 variables if the bucketMaxIndex is not too close to previous f1
                if (!(bucketMaxIndex < (self.frequency1Index + bucketSize/2) && bucketMaxIndex > (self.frequency1Index - bucketSize/2)))
                {
                    self.frequency2Index = self.frequency1Index;
                    self.frequency2Number = @([self.frequency1Number floatValue]);
                }
                self.frequency1Index = bucketMaxIndex;
                self.frequency1Number = @(fftData[bucketMaxIndex]);
            }
            // 2nd Loudest Frequency Evaluation; f2 cannot be too close to f1
            else if ([self.frequency2Number floatValue] < fftData[bucketMaxIndex] && !(bucketMaxIndex < (self.frequency1Index + bucketSize/2) && bucketMaxIndex > (self.frequency1Index - bucketSize/2)))
            {
                self.frequency2Index = bucketMaxIndex;
                self.frequency2Number = @(fftData[bucketMaxIndex]);
            }
            // Reset bucket
            bucketIndexCount = 0;
            bucketMaxIndex = i;
        }

        // Calculate local bucket maximum
        if (fftData[bucketMaxIndex] < fftData[i])
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
