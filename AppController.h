//
//  AppController.h
//  CyborgameSubtitler
//
//  Created by Andrew on 7/3/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppController : NSView{
    CVDisplayLinkRef displayLink;
    IBOutlet NSWindow *stageWindow;
    IBOutlet NSWindow *controlWindow;
    id eventMon;
}
- (void) startAnimation;
- (void) stopAnimation;
- (void) drawView;

@end
