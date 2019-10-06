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
    if (!self.audioData) {free(self.audioData);NSLog(@"he");}
    if (!self.fftData) {free(self.fftData);}
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
