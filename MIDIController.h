//
//  MIDIController.h
//  PerformanceSpace
//
//  Created by Andrew on 7/25/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <CoreMIDI/CoreMIDI.h>

@interface MIDIController : NSObject{
    MIDIClientRef midiClient;
    MIDIPortRef inputPort;
    NSMutableDictionary *midiMappings;
}


@end
