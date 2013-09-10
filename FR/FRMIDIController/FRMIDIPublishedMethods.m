//
//  FRMIDIPublishedMethods.m
//  SyMix
//
//  Created by Andrew on 9/9/13.
//  Copyright (c) 2013 SINLAB. All rights reserved.
//

#import "FRMIDIPublishedMethods.h"
#import "FRAppCommon.h"

@implementation FRMIDIPublishedMethods

// These class contains methods that are custom for this application and are those which are available in the config plist for each controller

+ (void) slider_fontSize:(NSString*)value{
    [[NSUserDefaults standardUserDefaults] setFloat:[value floatValue] forKey:@"scaleFactor"];
}


@end
