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
    NSSize original_size;
    bool f_fullscreenMode;
    NSTimer *typingTimer;
    SyphonServer *syphonServer;
    NSOpenGLContext *openGLContext;
	NSOpenGLPixelFormat *pixelFormat;
    GLuint glTex_floor;
    GLuint texName;
}

- (void) startAnimation;
- (void) stopAnimation;
- (void)goFullscreen;
- (void)goFullscreen2;
- (void)goWindowed;

typedef enum scrollDirectionTypes{
    HORIZONTAL,
    VERTICAL
} ScrollDirection;

@property int rangeMax;
@property(atomic, copy)   NSURL   *droppedFileURL;
@property(atomic, copy)   NSFont  *fontToUse;
@property(atomic, strong) NSColor *backgroundColor;
@property(atomic, strong) NSColor *backgroundColor2;
@property(atomic, strong) NSColor *fontColor;
@property(atomic, strong) NSColor *fontColorShadow;
@property(atomic, copy) NSString* displayString;
@property(atomic)  NSPoint position;

@property(readwrite, assign) float scrollPosition;
@property(readwrite, assign) bool f_autoScale;
@property(readwrite, assign) bool f_centerText;
@property(readwrite, assign) bool f_drawShadow;
@property(readwrite, assign) bool f_flipText;
@property(readwrite, assign) bool f_mirrorText;
@property(readwrite, assign) bool f_scrollPause;
@property(readwrite, assign) int scaleTextType;
@property(readwrite, assign) ScrollDirection scrollDirection;
@property(readwrite, assign) float gradientAngle;
@property(readwrite, assign) float scaleFactor;
@property(readwrite, assign) float global_offsetX;
@property(readwrite, assign) float global_offsetY;
@property(readwrite, assign) float scrollRate;

@end
