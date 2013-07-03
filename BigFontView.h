//
//  BigFontView.h
//  CyborgameSubtitler
//
//  Created by Andrew on 6/5/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BigFontView : NSView <NSDraggingDestination>{
    CVDisplayLinkRef displayLink;
    __unsafe_unretained NSTextView *_displayBox;
}

- (void) startAnimation;
- (void) stopAnimation;
- (void) drawView;

@property (unsafe_unretained) IBOutlet NSTextView *displayBox;
@end
