//
//  NSView+snapshot.m
//  CyborgameSubtitler
//
//  Created by Andrew on 8/25/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import "NSView+snapshot.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/glu.h>

@implementation NSView (snapshot)

// Modified from http://developer.apple.com/samplecode/Color_Sampler/Color_Sampler.html
- (NSImage *) snapshot { return [self snapshotFromRect:[self bounds]]; }
- (NSImage *) snapshotFromRect:(NSRect) sourceRect{
    NSImage *snapshot = [[NSImage alloc] initWithSize:sourceRect.size];
    NSBitmapImageRep *rep;
    [self lockFocus];
    rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:sourceRect];
    [self unlockFocus];
    [snapshot addRepresentation:rep];
    return snapshot;
}


// Modified from: https://developer.apple.com/library/mac/documentation/graphicsimaging/conceptual/opengl-macprogguide/opengl_texturedata/opengl_texturedata.html
-(void)snapshotIntoGlTexture:(GLuint*)texName openGLContext:(NSOpenGLContext *)openGLContext{
    
    
    [openGLContext makeCurrentContext];
    
    NSBitmapImageRep * bitmap =  [self bitmapImageRepForCachingDisplayInRect:
                                  [self visibleRect]]; // 1
    int samplesPerPixel = 0;
    
    [self cacheDisplayInRect:[self visibleRect] toBitmapImageRep:bitmap]; // 2
    samplesPerPixel = (int)[bitmap samplesPerPixel]; // 3
    glPixelStorei(GL_UNPACK_ROW_LENGTH, (int)[bitmap bytesPerRow]/samplesPerPixel); // 4
    glPixelStorei (GL_UNPACK_ALIGNMENT, 1); // 5
    if (*texName == 0) // 6
        glGenTextures (1, texName);
    glBindTexture (GL_TEXTURE_RECTANGLE_ARB, *texName); // 7
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB,
                    GL_TEXTURE_MIN_FILTER, GL_LINEAR); // 8
    
    if(![bitmap isPlanar] &&
       (samplesPerPixel == 3 || samplesPerPixel == 4)) { // 9
        glTexImage2D(GL_TEXTURE_RECTANGLE_ARB,
                     0,
                     samplesPerPixel == 4 ? GL_RGBA8 : GL_RGB8,
                     (int)[bitmap pixelsWide],
                     (int)[bitmap pixelsHigh],
                     0,
                     samplesPerPixel == 4 ? GL_RGBA : GL_RGB,
                     GL_UNSIGNED_BYTE,
                     [bitmap bitmapData]);
    } else {
        NSLog(@"NSView+Snapshot: UNSUPPORTED BITMAP DATA");
    }
}



@end