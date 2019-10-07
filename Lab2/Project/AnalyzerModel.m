//
//  AnalyzerModel.m
//  Lab2
//
//  Created by Will Lacey on 10/1/19.
//  Copyright © 2019 Will Lacey. All rights reserved.
//

#import "AnalyzerModel.h"

// Global Class Definitions
#define BUFFER_SIZE (2048*4)
#define FFT_SIZE (BUFFER_SIZE/2)
#define SAMPLE_RATE 44100

@interface AnalyzerModel ()

// Necessary DSP Utilities
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) FFTHelper *fftHelper;
@property (strong, nonatomic) Novocaine *audioManager;

// FFT Analysis Arrays/Buffers
@property (nonatomic) float* audioData;
@property (nonatomic) float* fftData;

// Properties to help manage use of the Microphone and Speaker
@property (nonatomic) BOOL isUsingMicrophone;
@property (nonatomic) BOOL isUsingSpeaker;
@property (strong, nonatomic) NSNumber *speakerFrequency;

@end

@implementation AnalyzerModel

#pragma mark Property Getters
/*!
@brief Allows for the AnalyzerModel to be shared by various classes without creating another instance
*/
+(AnalyzerModel*)sharedInstance{
    static AnalyzerModel * _sharedInstance = nil;
    
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate,^{
        _sharedInstance = [[AnalyzerModel alloc] init];
    });
    
    return _sharedInstance;
}

/*!
@brief Getter for AudioManager; Initializes boolean properties isUsingSpeaker and isUsingSpeaker
*/
-(Novocaine*)audioManager{
    if(!_audioManager){
        _audioManager = [Novocaine audioManager];
        _isUsingMicrophone = FALSE;
        _isUsingSpeaker = FALSE;
    }
    return _audioManager;
}

/*!
@brief Getter for the CircularBuffer (or ring buffer)
*/
-(CircularBuffer*)buffer{
    if(!_buffer){
        _buffer = [[CircularBuffer alloc]initWithNumChannels:1 andBufferSize:BUFFER_SIZE];
    }
    return _buffer;
}

/*!
@brief Getter for the FFT Helper
*/
-(FFTHelper*)fftHelper{
    if(!_fftHelper){
        _fftHelper = [[FFTHelper alloc]initWithFFTSize:BUFFER_SIZE];
    }
    return _fftHelper;
}

/*!
@brief Getter for the speaker's frequency
*/
-(NSNumber*)speakerFrequency{
    if(!_speakerFrequency)
    {
        _speakerFrequency = @(0);
    }
    return _speakerFrequency;
}

#pragma mark Additional Audio Manager Specific Functions
/*!
@brief Initializes the use of the system's Microphone
*/
-(void)useMicrophone{
    self.isUsingMicrophone = TRUE;
    
    // weak reference to self for audio input block
    __block AnalyzerModel * __weak  weakSelf = self;
    
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
        [weakSelf.buffer addNewInterleavedFloatData:data withNumSamples:numFrames withNumChannels:numChannels];
    }];
}

/*!
@brief Initializes the use of the system's speaker with a given frequency; This function may be recalled if the speaker's frequency is changed by another class
*/
-(void)useSpeaker:(float)withFrequency{
    
    // Set the speaker's frequency to the new frequency
    self.speakerFrequency = @(withFrequency);
    
    // The following code is only executed on a controller's first time speaker initialization
    if(!self.isUsingSpeaker)
    {
        self.isUsingSpeaker = TRUE;
        
        // Generate a sinisoidal signal with given frequency
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

/*!
@brief Simple function to start the audio manager after initializing use of microphone or speaker
*/
-(void)playAudioManager{
    [self.audioManager play];
}

#pragma mark Additional FFT Analysis Specific Functions
/*!
@brief Getter for the Sample Rate of the Audio Manager
*/
-(int)getSampleRate{
    return SAMPLE_RATE;
}

/*!
@brief Performs FFT on Microphone Audio
*/
-(void)performFftOnAudio{
    // If audioData or fftData are currently used, free data; otherwise allocate arrays
    if (self.audioData) {free(self.audioData);}
    if (self.fftData) {free(self.fftData);}
    self.audioData = malloc(sizeof(float)*BUFFER_SIZE);
    self.fftData = malloc(sizeof(float)*FFT_SIZE);
    
    // Fill audioData float array with Ring Bugger Microphone Audio Data
    [self.buffer fetchFreshData:self.audioData withNumSamples:BUFFER_SIZE];
    
    // Perform the Fast Fourier Transform on the recently filled audioData
    [self.fftHelper performForwardFFTWithData:self.audioData
    andCopydBMagnitudeToBuffer:self.fftData];
}

/*!
@brief Getter for the Audio Data array; Does not need to be freed as the Analysis Model will handle the data
*/
-(float*)getAudioData{
    return self.audioData;
}

/*!
@brief Getter for the Audio Data array Size
*/
-(int)getAudioDataSize{
    return BUFFER_SIZE;
}

/*!
@brief Getter for the FFT Data array; Does not need to be freed as the Analysis Model will handle the data
*/
-(float*)getFftData{
    return self.fftData;
}

/*!
@brief Getter for the Audio Data array Size
*/
-(int)getFftDataSize{
    return FFT_SIZE;
}

/*!
@brief Static function that converts an FFT Magnitude Index (from the fftData array) to a Frequency
*/
+(float) convertFftMagnitudeIndexToFrequency:(int)fftMagnitudeIndex{
    return (float)fftMagnitudeIndex * ((float)SAMPLE_RATE/2) / (float) FFT_SIZE;
}

/*!
@brief Static function that converts a Frequency to an FFT Magnitude Index (for the fftData array)
*/
+(int) convertFrequencyToFftMagnitudeIndex:(float)frequency{
    return frequency * FFT_SIZE / ((float)SAMPLE_RATE/2);
}

/*!
@brief Finds the range of the FFT signal between a lower and upper frequency using the optimized vDSP library; returns the difference between the greatest and lowest FFT magnitude
*/
-(float) getFftRangeWithLowerFrequencyBounds:(float)lowerFrequency andUpperFrequencyBounds:(float)upperFrequency{
    
    // converts the frequency bounds into an FFT Magnitude Index
    int lowerBounds = [AnalyzerModel convertFrequencyToFftMagnitudeIndex:lowerFrequency];
    int upperBounds = [AnalyzerModel convertFrequencyToFftMagnitudeIndex:upperFrequency];

    // uses DSP to quickly find the max and min of the signal
    float maxVal = 0;
    vDSP_maxv((self.fftData+lowerBounds), 1, &maxVal, upperBounds-lowerBounds);
    float minVal = 0;
    vDSP_minv(self.fftData+lowerBounds, 1, &minVal, upperBounds-lowerBounds);
    
    return maxVal - minVal;
}

/*!
@brief Finds the two loudest fftMagnitudes between a lower and upper frequency and returns them as an NSArray*
*/
-(NSArray*) getLoudestFftMagnitudeIndicesWithLowerFrequencyBounds:(float)lowerFrequency andUpperFrequencyBounds:(float)upperFrequency usingFrequencyBucketSize:(float)frequencyBucketSize{
    
    // converts the frequency bounds into an FFT Magnitude Index
    int lowerBounds = [AnalyzerModel convertFrequencyToFftMagnitudeIndex:lowerFrequency];
    int upperBounds = [AnalyzerModel convertFrequencyToFftMagnitudeIndex:upperFrequency];
    
    // fft Magnitude Variables
    float fftMagnitude1 = -1000;
    float fftMagnitude2 = -1000;
    int fftMagnitudeIndex1 = 0;
    int fftMagnitudeIndex2 = 100;
    
    // bucket Variables
    int bucketSize = [AnalyzerModel convertFrequencyToFftMagnitudeIndex:frequencyBucketSize];
    int bucketIndexCount = 0; // Var to track bucket overflow; when bucket fills, evaluate local bucket max
    int bucketMaxIndex = 0; // Var to track local bucket max
    
    // logic for finding two maximum magnitudes
    for (int i = lowerBounds; i < upperBounds; i++)
    {
    // If bucket count overflow (or loop has finished), evaluate local bucket max relative to loudest fft magnitude
        if (bucketIndexCount == bucketSize || i == FFT_SIZE-1)
        {
            // loudest magnitude evaluation
            if (fftMagnitude1 < self.fftData[bucketMaxIndex])
            {
                // set fftMagnitude2 variables to previous fftMagnitude1 variables if the bucketMaxIndex is not too close to previous fftMagnitude1
                if (!(bucketMaxIndex < (fftMagnitudeIndex1 + bucketSize/2) && bucketMaxIndex > (fftMagnitudeIndex1 - bucketSize/2)))
                {
                    fftMagnitudeIndex2 = fftMagnitudeIndex1;
                    fftMagnitude2 = fftMagnitude1;
                }
                fftMagnitudeIndex1 = bucketMaxIndex;
                fftMagnitude1 = self.fftData[bucketMaxIndex];
            }
            // 2nd loudest magnitude evaluation; fftMagnitude2 cannot be too close to fftMagnitude1
            else if (fftMagnitude2 <  self.fftData[bucketMaxIndex] && !(bucketMaxIndex < (fftMagnitudeIndex1 + bucketSize/2) && bucketMaxIndex > (fftMagnitudeIndex1 - bucketSize/2)))
            {
                fftMagnitudeIndex2 = bucketMaxIndex;
                fftMagnitude2 = self.fftData[bucketMaxIndex];
            }
            // reset bucket for next bucket window
            bucketIndexCount = 0;
            bucketMaxIndex = i;
        }

        // calculate local bucket maximum
        if ( self.fftData[bucketMaxIndex] <  self.fftData[i])
        {
            bucketMaxIndex = i;
        }
        bucketIndexCount++; // increment bucket count
    }
    
    // return NSArray of the two magnitudes
    NSArray* fftMagnitudeIndices = @[@(fftMagnitudeIndex1), @(fftMagnitudeIndex2)];
    return fftMagnitudeIndices;
}

#pragma mark Closing Analyzer Model
/*!
@brief Method call that occurs when the model has been closed; Gracefully closes the microphone and speaker blocks and pauses the audio manager until next use
*/
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
