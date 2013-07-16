//
//  OverlayView.m
//  CyborgameSubtitler
//
//  Created by Andrew on 7/16/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import "OverlayView.h"

@implementation OverlayView

- (id)initWithFrame:(NSRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

NSImage *image;
- (void)setImage:(NSImage *)newImage{
    image = newImage;
    [image setFlipped:YES];
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect{
    
    float transparencyVal = [[NSUserDefaults standardUserDefaults] floatForKey:@"overlayTransparencyVal"];
        [self setAlphaValue:transparencyVal];
    NSURL *imageURL = [NSURL URLWithString:@"http://t3.gstatic.com/images?q=tbn:ANd9GcRVCGJB_l3cf83uDLTKSrJqs2nwakhaTHijT40DFjuTr5_i5fGfWg"];
    image = [[NSImage alloc] initWithContentsOfURL:imageURL];
    
    //[image drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
    
    // Or stretch image to fill view
    [image drawInRect:[self bounds] fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
}

@end
