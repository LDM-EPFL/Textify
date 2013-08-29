//
//  PreviewView.m
//  PerformanceSpace
//
//  Created by Andrew on 7/18/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//
#import "PreviewView.h"
#import "AppCommon.h"
#import "AppController.h"

// Fixes NSLOG (removes timestamp)
#define NSLog(FORMAT, ...) fprintf(stderr,"%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
@implementation PreviewView

- (id)initWithFrame:(NSRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        //Drag and Drop Setup
        [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect{
    [super drawRect:dirtyRect];
    // Drawing code here.
}


-(BOOL)acceptsFirstResponder{return YES;}
-(NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {return NSDragOperationCopy;}
-(BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {return YES;}
-(BOOL)performDragOperation:(id<NSDraggingInfo>)sender {return [AppController performDragOperation:sender];}
@end
