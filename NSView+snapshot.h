//
//  NSView+snapshot.h
//  CyborgameSubtitler
//
//  Created by Andrew on 8/25/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSView (snapshot) {}

- (NSImage *) snapshot;
- (NSImage *) snapshotFromRect:(NSRect) sourceRect;
-(void)snapshotIntoGlTexture:(GLuint*)texName openGLContext:(NSOpenGLContext *)openGLContext;
@end
