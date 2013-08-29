//
//  MIDIController.m
//  PerformanceSpace
//
//  Created by Andrew on 7/25/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//
#import "AppCommon.h"
#import "MIDIController.h"
#include <CoreMIDI/CoreMIDI.h>

// Fixes NSLOG (removes timestamp)
#define NSLog(FORMAT, ...) fprintf(stderr,"%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);


@implementation MIDIController

// Init
- (id)init{
    if (self = [super init]){
        NSError *error = nil;
        OSStatus result = 0;
        
        
        result = MIDIClientCreate(CFSTR("MIDI client"), NULL, NULL, &midiClient);
        if (result != noErr) {
            NSLog(@"MIDI: Error creating MIDI client");
           //%s - %s", GetMacOSStatusErrorString(result), GetMacOSStatusCommentString(result));
        }else{
            NSLog(@"MIDI: Client Created");
        }
        
        
        
        
        error=nil;
        result = MIDIInputPortCreate(midiClient, CFSTR("Input"), midiInputCallback, NULL, &inputPort);
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:result userInfo:nil];
        if(result != noErr){
            NSLog(@"MIDI: FAILED! %@",error);
        }else{
            NSLog(@"MIDI: Input Port Created");
        }
        
        
        // List available devices
        //[self listDevices];
        
        // Load MIDI configuration files
        NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[NSBundle mainBundle] resourcePath] error:nil];
        NSArray *plistFiles = [dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.plist'"]];
        midiMappings=[[NSMutableDictionary alloc] init];
        for(NSString* filename in plistFiles){
            if ([filename rangeOfString:@"midimap"].location != NSNotFound) {
                
                NSString *configFileWithPath=[[NSString alloc] initWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath],filename];
                NSMutableDictionary* thisConfig = [[NSMutableDictionary alloc] initWithContentsOfFile:configFileWithPath];
                
                
                [midiMappings setObject:thisConfig forKey:[thisConfig valueForKey:@"MIDISourceName"]];

                // Try and attach device
                [self connectToDeviceNamed:[thisConfig valueForKey:@"MIDISourceName"]];
            }
        }
        
    
        // Put settings in AppCommon -  We do this so we can access it via the C style callback below... kindof lame I know
        [[AppCommon sharedAppCommon] setMidiMappings:midiMappings];
    
    }
    
    return self;
}

// List all the devices
-(void)listDevices{
    ItemCount numOfDevices = MIDIGetNumberOfDevices();
    
    for (int i = 0; i < numOfDevices; i++) {
        MIDIDeviceRef midiDevicesOnChannel = MIDIGetDevice(i);
        
        // Get properties list
        CFPropertyListRef properties = nil;
        MIDIObjectGetProperties(midiDevicesOnChannel, &properties, true);
        
        // Get entities on that proplist
        CFPropertyListRef entity = nil;
        CFDictionaryGetValueIfPresent(properties, @"entities", &entity);
        
        // I cannot really believe this is the right way to do this, but it seems to work...
       
        if(entity){
            NSArray *nameOfDevice = [(__bridge NSDictionary *)entity valueForKey:@"name"];
            if([nameOfDevice count] > 0){
                
                NSString* deviceName = nameOfDevice[0];
                                                               
                NSLog(@"MIDI: Channel %i : Found %@",i,deviceName);
            }
        }
    }
}

// Make a connection
-(void)connectToDeviceNamed:(NSString*)deviceNameToConnect{
    
    ItemCount numOfDevices = MIDIGetNumberOfDevices();
    
    for (int i = 0; i < numOfDevices; i++) {
        MIDIDeviceRef midiDevicesOnChannel = MIDIGetDevice(i);
        
        // Get properties list
        CFPropertyListRef properties = nil;
        MIDIObjectGetProperties(midiDevicesOnChannel, &properties, true);
        
        // Get entities on that proplist
        CFPropertyListRef entity = nil;
        CFDictionaryGetValueIfPresent(properties, @"entities", &entity);
        
        // I cannot really believe this is the right way to do this, but it seems to work...
        if(entity){
            

            OSStatus result;
            NSError * error;
            NSArray *nameOfDevice = [(__bridge NSDictionary *)entity valueForKey:@"name"];
            NSArray *idOfDevice = [(__bridge NSDictionary *)entity valueForKey:@"uniqueID"];
            NSArray *sources = [(__bridge NSDictionary *)entity valueForKey:@"sources"];
            
            MIDIUniqueID deviceID=0;
            
            if ([sources count] > 0){
                NSArray *thisID = [(NSDictionary *)sources[0] valueForKey:@"uniqueID"];
                deviceID = (MIDIUniqueID)[(NSNumber *)thisID[0] integerValue];
            }
            
            
            
            
            if([nameOfDevice count] > 0 && [idOfDevice count] > 0){
                
                NSString* deviceName = nameOfDevice[0];
                
                
                if ([deviceName isEqualToString:deviceNameToConnect]){
                    MIDIObjectRef endPoint;
                    MIDIObjectType foundObj;
                    result = MIDIObjectFindByUniqueID(deviceID, &endPoint, &foundObj);
                    error = [NSError errorWithDomain:NSOSStatusErrorDomain code:result userInfo:nil];
                    if(result != noErr){
                        NSLog(@"MIDI: FAILED! Cannot locate object by uniqueID %@",error);
                    }else{
                        NSLog(@"MIDI: Connecting %@: (Channel:%i ID:%i Endpoint:%i)",deviceName,i,deviceID,endPoint);
                        result = MIDIPortConnectSource(inputPort, endPoint, (__bridge void *)(deviceName));
                        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:result userInfo:nil];
                        if(result != noErr){
                            NSLog(@"MIDI: CONNECT FAILED! %@",error);
                        }
                    }
                                        
                    
                    
                    
                                        
                }
            }
        }
    }
}

// MIDI Callback function
// based on http://comelearncocoawithme.blogspot.ch/2011/08/reading-from-external-controllers-with.html
#define SYSEX_LENGTH 1024
static void midiInputCallback (const MIDIPacketList *list, void *procRef, void *srcRef){

    @autoreleasepool {
    
        
        // Unpack callback data
        NSString  *deviceName = (__bridge NSString*)srcRef;
        
       
        
        bool continueSysEx = false;
        UInt16 nBytes;
        const MIDIPacket *packet = &list->packet[0];
        unsigned char sysExMessage[SYSEX_LENGTH];
        unsigned int sysExLength = 0;
        
        for (unsigned int i = 0; i < list->numPackets; i++) {
            nBytes = packet->length;
            // Check if this is the end of a continued SysEx message
            if (continueSysEx) {
                unsigned int lengthToCopy = MIN (nBytes, SYSEX_LENGTH - sysExLength);
                // Copy the message into our SysEx message buffer,
                // making sure not to overrun the buffer
                memcpy(sysExMessage + sysExLength, packet->data, lengthToCopy);
                sysExLength += lengthToCopy;
                
                // Check if the last byte is SysEx End.
                continueSysEx = (packet->data[nBytes - 1] == 0xF7);

                if (!continueSysEx || sysExLength == SYSEX_LENGTH) {
                    // We would process the SysEx message here, as it is we're just ignoring it
                    
                    sysExLength = 0;
                }
            } else {
                UInt16 iByte, size;
                
                iByte = 0;
                while (iByte < nBytes) {
                    size = 0;
                    
                    // First byte should be status
                    unsigned char status = packet->data[iByte];
                    if (status < 0xC0) {
                        size = 3;
                    } else if (status < 0xE0) {
                        size = 2;
                    } else if (status < 0xF0) {
                        size = 3;
                    } else if (status == 0xF0) {
                        // MIDI SysEx then we copy the rest of the message into the SysEx message buffer
                        unsigned int lengthLeftInMessage = nBytes - iByte;
                        unsigned int lengthToCopy = MIN (lengthLeftInMessage, SYSEX_LENGTH);
                        
                        memcpy(sysExMessage + sysExLength, packet->data, lengthToCopy);
                        sysExLength += lengthToCopy;
                        
                        size = 0;
                        iByte = nBytes;
                        
                        // Check whether the message at the end is the end of the SysEx
                        continueSysEx = (packet->data[nBytes - 1] != 0xF7);
                    } else if (status < 0xF3) {
                        size = 3;
                    } else if (status == 0xF3) {
                        size = 2;
                    } else {
                        size = 1;
                    }
                    
                    //unsigned char messageType = status & 0xF0; //Mask all but top four bits
                    unsigned char messageChannel = status & 0xF;
                    unsigned int signalID = packet->data[iByte + 1];
                    unsigned int value = packet->data[iByte + 2];
                                       
                    switch (status & 0xF0) {
                        
                        // Note OFF
                        case 0x80:
                            [MIDIController handleMappingForDeviceNamed:deviceName
                                                            MessageType:@"NOTE_OFF"
                                                              onChannel:[NSString stringWithFormat:@"%i",messageChannel]
                                                               signalID:[NSString stringWithFormat:@"%i",signalID]
                                                                  value:[NSString stringWithFormat:@"%i",value]];
                            break;
                        
                        // Note ON
                        case 0x90:
                            [MIDIController handleMappingForDeviceNamed:deviceName
                                                            MessageType:@"NOTE_ON"
                                                              onChannel:[NSString stringWithFormat:@"%i",messageChannel]
                                                               signalID:[NSString stringWithFormat:@"%i",signalID]
                                                                  value:[NSString stringWithFormat:@"%i",value]];
                            break;
                       
                        // CONTROL
                        case 0xB0:
                            [MIDIController handleMappingForDeviceNamed:deviceName
                                                            MessageType:@"CONTROL"
                                                              onChannel:[NSString stringWithFormat:@"%i",messageChannel]
                                                               signalID:[NSString stringWithFormat:@"%i",signalID]
                                                                  value:[NSString stringWithFormat:@"%i",value]];
                            break;

                        /* 
                         
                         We don't care about these types for now...
                         
                        case 0xA0:
                            NSLog(@"%@: Aftertouch: %d, %d", deviceName, packet->data[iByte + 1], packet->data[iByte + 2]);
                            break;
                            
                            
                        case 0xC0:
                            NSLog(@"%@: Program change: %d", deviceName, packet->data[iByte + 1]);
                            break;
                            
                        case 0xD0:
                            NSLog(@"%@: Change aftertouch: %d", deviceName, packet->data[iByte + 1]);
                            break;
                            
                        case 0xE0:
                            NSLog(@"%@: Pitch wheel: %d, %d", deviceName, packet->data[iByte + 1], packet->data[iByte + 2]);
                            break;
                            
                        default:
                            NSLog(@"%@: Unknown!", deviceName);
                            break;
                         */
                    }
                    
                    iByte += size;
                }
            }
            
            packet = MIDIPacketNext(packet);
        }
    }
}
// Callback helper
+(void)handleMappingForDeviceNamed:(NSString*)deviceName MessageType:(NSString*)messageType onChannel:(NSString*)channel signalID:(NSString*)signalID value:(NSString*)value{
    
    // We can't access "self" from within this callback, so we use this copy of settings
    NSDictionary* midiMap = [[AppCommon sharedAppCommon] midiMappings];
    midiMap = [midiMap valueForKey:deviceName];

    
    // Look to see if we have a mapping for this
    NSMutableDictionary *mapping = [[[[midiMap valueForKey:@"CHANNEL"] valueForKey:channel] valueForKey:messageType] valueForKey:signalID];
    
    // YES! Do it...
    if(mapping){
        for(NSDictionary *thisAction in mapping){
            
            // Make sure the method is available
            SEL method = NSSelectorFromString([thisAction valueForKey:@"function"]);
            if([MIDIController respondsToSelector:method]){
                
                NSString* logic = [thisAction valueForKey:@"logic"];
                int valueToCompare = [[thisAction valueForKey:@"valmatch"] intValue];
                int incomingValue = [value intValue];
                
                
                // Apply logic
                if ([logic length] > 0){
                    if ([logic isEqualToString:@"EQ"]){
                        if (incomingValue == valueToCompare){
                            [MIDIController performSelector:method withObject:value];
                        }
                    }else if ([logic isEqualToString:@"GT"]){
                        if (incomingValue > valueToCompare){
                            [MIDIController performSelector:method withObject:value];
                        }
                    }else if ([logic isEqualToString:@"LT"]){
                        if (incomingValue < valueToCompare){
                            [MIDIController performSelector:method withObject:value];
                        }
                    }else{
                        NSLog(@"MIDI: Invalid logic %@ specified in mapping!", logic);
                    }
                    
                // No logic, just pass through
                }else{
                    [MIDIController performSelector:method withObject:value];
                }
                
                
                
            }else{
                NSLog(@"MIDI: Invalid method %@ specified in mapping!", NSStringFromSelector(method));
            }
            
            
            
        }
    }

}


// Custom functions ///////////////////////////////////////////////////////////////////////////////////////////
// Everything after here is custom to this application. These are the functions which are allowed in the midi mapping plists
+ (void) adjust_fontSize:(NSString*)value{
    [[NSUserDefaults standardUserDefaults] setFloat:[value floatValue] forKey:@"scaleFactor"];
}





@end
