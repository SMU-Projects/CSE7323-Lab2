//
//  AnalyzerModel.m
//  Lab2
//
//  Created by Will Lacey on 10/1/19.
//  Copyright © 2019 Will Lacey. All rights reserved.
//

#import "AnalyzerModel.h"

#define BUFFER_SIZE (2048*4)
#define FFT_SIZE (BUFFER_SIZE/2)
#define SAMPLE_RATE 44100

@interface AnalyzerModel ()

@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) FFTHelper *fftHelper;
@property (strong, nonatomic) Novocaine *audioManager;

@property (nonatomic) float* audioData;
@property (nonatomic) float* fftData;

@property (nonatomic) BOOL isUsingMicrophone;
@property (nonatomic) BOOL isUsingSpeaker;
@property (strong, nonatomic) NSNumber *speakerFrequency;

@end

@implementation AnalyzerModel

+(AnalyzerModel*)sharedInstance{
    static AnalyzerModel * _sharedInstance = nil;
    
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate,^{
        _sharedInstance = [[AnalyzerModel alloc] init];
    });
    
    return _sharedInstance;
}


-(Novocaine*)audioManager{
    if(!_audioManager){
        _audioManager = [Novocaine audioManager];
        _isUsingMicrophone = FALSE;
        _isUsingSpeaker = FALSE;
    }
    return _audioManager;
}

-(CircularBuffer*)buffer{
    if(!_buffer){
        _buffer = [[CircularBuffer alloc]initWithNumChannels:1 andBufferSize:BUFFER_SIZE];
    }
    return _buffer;
}

-(FFTHelper*)fftHelper{
    if(!_fftHelper){
        _fftHelper = [[FFTHelper alloc]initWithFFTSize:BUFFER_SIZE];
    }
    return _fftHelper;
}

-(NSNumber*)speakerFrequency{
    if(!_speakerFrequency)
    {
        _speakerFrequency = @(0);
    }
    return _speakerFrequency;
}

-(void)useMicrophone{
    self.isUsingMicrophone = TRUE;
    __block AnalyzerModel * __weak  weakSelf = self;
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
        [weakSelf.buffer addNewInterleavedFloatData:data withNumSamples:numFrames*numChannels withNumChannels:numChannels];
    }];
}

-(void)useSpeaker:(float)withFrequency{
    
    self.speakerFrequency = @(withFrequency);
    
    if(!self.isUsingSpeaker)
    {
        self.isUsingSpeaker = TRUE;
        __block float phase = 0.0;
        [self.audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
            double phaseIncrement = 2*M_PI*[self.speakerFrequency floatValue]/SAMPLE_RATE;
            double sineWavePeriod = 2*M_PI;
            for (int i=0; i < numFrames; ++i)
            {
                for(int j=0;j<numChannels;j++)
                    data[i*numChannels+j] = 0.5*sin(phase);
                
                phase += phaseIncrement;
                if (phase >= sineWavePeriod) phase -= 2*M_PI;
            }
        }];
    }
}

-(void)playAudioManager{
    [self.audioManager play];
}

-(int)getSampleRate{
    return SAMPLE_RATE;
}

-(void)performFftOnAudio{
    if (self.audioData) {free(self.audioData);}
    if (self.fftData) {free(self.fftData);}
    self.audioData = malloc(sizeof(float)*BUFFER_SIZE);
    self.fftData = malloc(sizeof(float)*FFT_SIZE);
    
    [self.buffer fetchFreshData:self.audioData withNumSamples:BUFFER_SIZE];
    [self.fftHelper performForwardFFTWithData:self.audioData
    andCopydBMagnitudeToBuffer:self.fftData];
}

-(float*)getAudioData{
    return self.audioData;
}

-(int)getAudioDataSize{
    return BUFFER_SIZE;
}

-(float*)getFftData{
    return self.fftData;
}

-(int)getFftDataSize{
    return FFT_SIZE;
}

+(float) convertFftMagnitudeIndexToFrequency:(int)fftMagnitudeIndex{
    return (float)fftMagnitudeIndex * ((float)SAMPLE_RATE/2) / (float) FFT_SIZE;
}

+(int) convertFrequencyToFftMagnitudeIndex:(float)frequency{
    return frequency * FFT_SIZE / ((float)SAMPLE_RATE/2);
}

-(float) getFftRangeWithLowerFrequencyBounds:(float)lowerFrequency andUpperFrequencyBounds:(float)upperFrequency{
    
    int lowerBounds = [AnalyzerModel convertFrequencyToFftMagnitudeIndex:lowerFrequency];
    int upperBounds = [AnalyzerModel convertFrequencyToFftMagnitudeIndex:upperFrequency];
    
    float highestValue = -1000;
    float lowestValue = 1000;
    for (int i = lowerBounds; i < upperBounds; i++)
    {
        if (self.fftData[i] > highestValue)
        {
            highestValue = self.fftData[i];
        }
        if (self.fftData[i] < lowestValue)
        {
            lowestValue = self.fftData[i];
        }
    }
    return highestValue - lowestValue;
}

-(NSArray*) getLoudestFftMagnitudeIndicesWithLowerFrequencyBounds:(float)lowerFrequency andUpperFrequencyBounds:(float)upperFrequency usingFrequencyBucketSize:(float)frequencyBucketSize{
    
    int lowerBounds = [AnalyzerModel convertFrequencyToFftMagnitudeIndex:lowerFrequency];
    int upperBounds = [AnalyzerModel convertFrequencyToFftMagnitudeIndex:upperFrequency];
    
    float frequency1Float = -1000;
    float frequency2Float = -1000;
    int frequency1Index = 0;
    int frequency2Index = 100;
    
    int bucketSize = [AnalyzerModel convertFrequencyToFftMagnitudeIndex:frequencyBucketSize];
    int bucketIndexCount = 0; // Var to track bucket overflow; when bucket fills, evaluate local bucket max
    int bucketMaxIndex = 0; // Var to track local bucket max
    for (int i = lowerBounds; i < upperBounds; i++)
    {
    // If bucket count overflow (or loop has finished), evaluate local bucket max relative to loudest frequencies
        if (bucketIndexCount == bucketSize || i == FFT_SIZE-1)
        {
            // Loudest Frequency Evaluation
            if (frequency1Float < self.fftData[bucketMaxIndex])
            {
                // set frequency2 variables to previous frequency1 variables if the bucketMaxIndex is not too close to previous f1
                if (!(bucketMaxIndex < (frequency1Index + bucketSize/2) && bucketMaxIndex > (frequency1Index - bucketSize/2)))
                {
                    frequency2Index = frequency1Index;
                    frequency2Float = frequency1Float;
                }
                frequency1Index = bucketMaxIndex;
                frequency1Float = self.fftData[bucketMaxIndex];
            }
            // 2nd Loudest Frequency Evaluation; f2 cannot be too close to f1
            else if (frequency2Float <  self.fftData[bucketMaxIndex] && !(bucketMaxIndex < (frequency1Index + bucketSize/2) && bucketMaxIndex > (frequency1Index - bucketSize/2)))
            {
                frequency2Index = bucketMaxIndex;
                frequency2Float = self.fftData[bucketMaxIndex];
            }
            // Reset bucket
            bucketIndexCount = 0;
            bucketMaxIndex = i;
        }

        // Calculate local bucket maximum
        if ( self.fftData[bucketMaxIndex] <  self.fftData[i])
        {
            bucketMaxIndex = i;
        }
        bucketIndexCount++; // Increment bucket count
    }
    
    NSArray* frequencies = @[@(frequency1Index), @(frequency2Index)];
    return frequencies;
}

-(void) close{
    if (!self.isUsingMicrophone){
        [self.audioManager setInputBlock:nil];
        self.isUsingMicrophone = FALSE;
    }
    if (self.isUsingSpeaker){
        [self.audioManager setOutputBlock:nil];
        self.isUsingSpeaker = FALSE;
    }
    [self.audioManager pause];
}

@end
