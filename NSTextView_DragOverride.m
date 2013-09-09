//
//  NSTextView_DragOverride.m
//  CyborgameSubtitler
//
//  Created by Andrew on 8/28/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import "NSTextView_DragOverride.h"
#import "AppController.h"

@implementation NSTextView_DragOverride

/*
-(void)awakeFromNib{
    NSLog(@"hello");
    [[self textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [[self textContainer] setWidthTracksTextView:NO];
    [self setHorizontallyResizable:YES];
}
 */

-(BOOL)performDragOperation:(id<NSDraggingInfo>)sender {return [AppController performDragOperation:sender];}
@end
