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
// Quick but doesn't work properly on openGL windows
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


// Works on openGL
-(NSImage*) snapshotGL{
    return [self snapshotGLFlipped:NO];
}


-(NSImage*) snapshotGLFlipped:(BOOL)flipped{

    @try {
        
        
        NSRect bounds = [self bounds];
        int height = bounds.size.height;
        int width = bounds.size.width;
        
        NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc]
                                      initWithBitmapDataPlanes:NULL
                                      pixelsWide:width
                                      pixelsHigh:height
                                      bitsPerSample:8
                                      samplesPerPixel:4
                                      hasAlpha:YES
                                      isPlanar:NO
                                      colorSpaceName:NSDeviceRGBColorSpace
                                      bytesPerRow:4 * width
                                      bitsPerPixel:0
                                      ];
        
        
        
        glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, [imageRep bitmapData]);
        
        
        // Allocate the image and populate it with the imageRep
        NSImage *image=[[NSImage alloc] initWithSize:NSMakeSize(width,height)];
        [image addRepresentation:imageRep];
        [image setFlipped:flipped];
        [image lockFocusOnRepresentation:imageRep];
        [image unlockFocus];
        return image;
        
    }
    @catch (NSException *exception) {
        NSLog(@"Error capturing screen");
    }
    
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