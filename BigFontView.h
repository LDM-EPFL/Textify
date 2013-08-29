//
//  BigFontView.h
//  CyborgameSubtitler
//
//  Created by Andrew on 6/5/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class  SyphonServer;

@interface BigFontView : NSView {
    CVDisplayLinkRef displayLink;
    NSOpenGLContext *openGLContext;
	NSOpenGLPixelFormat *pixelFormat;
    SyphonServer *syphonServer;
    
    NSSize original_size;
    bool f_fullscreenMode;
    NSTimer *typingTimer;
    GLuint glTex_floor;
    GLuint texName;
    NSSize renderDimensions;
}

- (void) startAnimation;
- (void) stopAnimation;
- (void) goFullscreen;
- (void) goWindowed;
- (void) stopTimer;
- (void) startTimer;

typedef enum scrollDirectionTypes{
    HORIZONTAL,
    VERTICAL
} ScrollDirection;

@property int rangeMax;


@end
