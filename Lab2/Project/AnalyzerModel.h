//
//  AnalyzerModel.h
//  Lab2
//
//  Created by Will Lacey on 10/1/19.
//  Copyright © 2019 Will Lacey. All rights reserved.
//

// Class Imports
#import <Foundation/Foundation.h>

// DSPUtils Imports
#import "CircularBuffer.h"
#import "FFTHelper.h"
#import "Novocaine.h"

@interface AnalyzerModel : NSObject

+(AnalyzerModel*) sharedInstance;

-(void) useMicrophone;

-(void) useSpeaker:(float)withFrequency;

-(void)playAudioManager;

-(int) getSampleRate;

-(void)performFftOnAudio;

-(float*) getAudioData;

-(int) getAudioDataSize;

-(float*) getFftData;

-(int) getFftDataSize;

-(void) close;

@end
