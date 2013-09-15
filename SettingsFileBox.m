//
//  SettingsFileBox.m
//  Textify
//
//  Created by Andrew on 9/15/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import "SettingsFileBox.h"
#import "AppDelegate.h"

@implementation SettingsFileBox

-(void)mouseDown:(NSEvent *)theEvent{
    [super mouseDown:theEvent];
    if([theEvent clickCount] > 1){
        [(AppDelegate*)[[NSApplication sharedApplication] delegate] doubleClickSettings];
    }
}
@end
