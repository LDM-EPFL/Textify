//
//  MIDIConfigController.m
//  SyMix
//
//  Created by Andrew on 9/1/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import "FRMIDIConfigController.h"
#import "FRMIDIMapping.h"
#import "FRMIDIInput.h"
#import <objc/runtime.h>
#import "FRAppCommon.h"

@implementation FRMIDIConfigController

-(void)removeMapping:(FRMIDIMapping*)thisItem{
    
    NSLog(@"Releasing %@",thisItem.mapping);
    NSArray* mappingToRelease=[thisItem.mapping componentsSeparatedByString:@"/"];
    [[[[[[[FRAppCommon sharedFRAppCommon] midiMappings] valueForKey:mappingToRelease[0]] valueForKey:@"CHANNEL"] valueForKey:mappingToRelease[1]] valueForKey:mappingToRelease[2]] removeObjectForKey:mappingToRelease[3]];
    [[[FRAppCommon sharedFRAppCommon] midiMappings_byMethod] removeObjectForKey:thisItem.name];
    thisItem.mapping=nil;
    
    // Save to disk
    [_midiInput saveSettingsToConfigFile];
    
    
}

// Try and remap a midi control
-(void)incomingMidiMessage:(NSString*)deviceName
                 onChannel:(NSString*)channel
               messageType:(NSString*)messageType
                  signalID:(NSString*)signalID
                     value:(NSString*)value
             mappingExists:(BOOL)mappingExists{
    
    
    //NSLog(@"%@ %@",signalID,value);
    
    // If the user has the midi panel open and has selected an item in the list, proceeed
    if(([[_collectionView selectionIndexes] count] > 0) &&
       _settingsWindowOpen){
        
        
        // A slider must cross 66... a slider at max could appear as a button
        bool isSlider=([value integerValue] == 66);
        bool couldBeButton=([value integerValue] == 127);
        bool touchSensitive=FALSE;
        // Touch sensitive buttons send NOTE_ON val NOTE_OFF
        if([messageType isEqualToString:@"NOTE_OFF"] && [value integerValue] == 64){
            couldBeButton=TRUE;
            touchSensitive=TRUE;
        }
        
        
        
        // Grab the mapping we're dealing with
        FRMIDIMapping* thisItem = [_MIDIMapping_arrayController arrangedObjects][[[_collectionView selectionIndexes] firstIndex]];
        BOOL inUseBySomeoneElse=FALSE;
        
        
        // If the mapping makes sense, let's attempt it...
        if (([[thisItem type] isEqualToString:@"button"] && couldBeButton) ||
            ([[thisItem type] isEqualToString:@"slider"] && isSlider)){
            
            // If a control is being used, check to see if it's by us...
            if(mappingExists){
                NSString* existingMapping =[[[[[[[[FRAppCommon sharedFRAppCommon] midiMappings] valueForKey:deviceName] valueForKey:@"CHANNEL"] valueForKey:channel] valueForKey:messageType] valueForKey:signalID] valueForKey:@"function"][0];
                
                thisItem.warningMessage=[NSString stringWithFormat:@"That control already mapped to '%@'.",[existingMapping componentsSeparatedByString: @"_"][1]];
                
                //Edge case: blank method
                if(![thisItem.method isEqualToString:@""]){
                    inUseBySomeoneElse=([existingMapping isEqualToString:thisItem.method])?false:true;
                }
                
            }
            
            // If the control is being used by another mapping, don't update
            if(inUseBySomeoneElse){
                thisItem.showWarning=TRUE;
            }else{
                thisItem.showWarning=FALSE;
                NSString* settingString = [NSString stringWithFormat:@"%@/%@/%@/%@",deviceName,channel,messageType,signalID];
                
                // Update only if we need to
                if (![thisItem.mapping isEqualToString:settingString]){
                    
                    // Release existing mapping
                    if (thisItem.mapping){
                        NSLog(@"Releasing %@",thisItem.mapping);
                        NSArray* mappingToRelease=[thisItem.mapping componentsSeparatedByString:@"/"];
                        [[[[[[[FRAppCommon sharedFRAppCommon] midiMappings] valueForKey:mappingToRelease[0]] valueForKey:@"CHANNEL"] valueForKey:mappingToRelease[1]] valueForKey:mappingToRelease[2]] removeObjectForKey:mappingToRelease[3]];
                        [[[FRAppCommon sharedFRAppCommon] midiMappings_byMethod] removeObjectForKey:thisItem.name];
                    }
                    
                    //NSLog(@"Registering %@ mapping on %@/%@...",[thisItem type],messageType,signalID);
                    
                    // Update the setting
                    thisItem.mapping=settingString;
                    
                    // Create a new setting
                    NSMutableArray *newSettings=[[NSMutableArray alloc] init];
                    NSMutableDictionary *newSetting = [[NSMutableDictionary alloc] init];
                    [newSetting setValue:thisItem.method forKey:@"function"];
                    if ([[thisItem type] isEqualToString:@"button"]){
                        
                        if(touchSensitive){
                            [newSetting setValue:@"GT" forKey:@"logic"];
                            [newSetting setValue:@"0" forKey:@"valmatch"];
                        }else{
                            [newSetting setValue:@"EQ" forKey:@"logic"];
                            [newSetting setValue:@"0" forKey:@"valmatch"];
                        }
                    }else{
                        [newSetting setValue:@"" forKey:@"logic"];
                        [newSetting setValue:@"" forKey:@"valmatch"];
                    }
                    [newSettings addObject:newSetting];
                    
                    // Update the mappings
                    [[[[[[[FRAppCommon sharedFRAppCommon] midiMappings] valueForKey:deviceName] valueForKey:@"CHANNEL"] valueForKey:channel] valueForKey:messageType] setValue:newSettings forKey:signalID];
                    [[[FRAppCommon sharedFRAppCommon] midiMappings_byMethod] setValue:settingString forKey:thisItem.name];
                    
                    // Save to disk
                    [_midiInput saveSettingsToConfigFile];
                }
            }
            
        }
    }
    
}

// Initialize the mappings
-(void)initializeMappings{
    int unsigned numMethods;
    Method *methods = class_copyMethodList(objc_getMetaClass("FRMIDIPublishedMethods"), &numMethods);
    for (int i = 0; i < numMethods; i++) {
        
        NSString* methodName=NSStringFromSelector(method_getName(methods[i]));
        if ([[methodName componentsSeparatedByString: @"_"][0] isEqualToString:@"button"] |
            [[methodName componentsSeparatedByString: @"_"][0] isEqualToString:@"slider"]
            ){
            FRMIDIMapping *newItem= [[FRMIDIMapping alloc]init];
            newItem.method=methodName;
            ;
            
            // Icon for sliders and buttons
            if ([[methodName componentsSeparatedByString: @"_"][0] isEqualToString:@"button"]){
                newItem.icon=[[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@",[[NSBundle mainBundle] pathForResource:@"button_icon" ofType:@"png"]]];
            }else{
                newItem.icon=[[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@",[[NSBundle mainBundle] pathForResource:@"slider_icon" ofType:@"png"]]];
                
            }
            
            newItem.name=[methodName componentsSeparatedByString: @"_"][1];
            newItem.type=[methodName componentsSeparatedByString: @"_"][0];
            newItem.mapping=[[[FRAppCommon sharedFRAppCommon] midiMappings_byMethod] valueForKey:methodName];
            [_MIDIMapping_arrayController addObject:newItem];
            
        }
    }
    
    //NSLog(@"Loaded %li mappings...",(unsigned long)[[_MIDIMapping_arrayController arrangedObjects] count]);
    
    // Clear any selection
    [_collectionView setSelectionIndexes:[NSMutableIndexSet indexSet]];
}
@end
