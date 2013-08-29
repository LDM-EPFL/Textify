//
//  NSTextView_NoDrag.m
//  CyborgameSubtitler
//
//  Created by Andrew on 8/28/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import "NSTextView_NoDrag.h"

@implementation NSTextView_NoDrag

- (NSArray *)acceptableDragTypes{return nil;}
- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender{return NSDragOperationNone;}
- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender{return NSDragOperationNone;}

@end
