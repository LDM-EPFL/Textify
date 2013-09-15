//
//  TextSlice.h
//  CyborgameSubtitler
//
//  Created by Andrew on 9/7/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TextSlice : NSObject{
    NSString * _displayText;
}

-(NSString *)displayText;
-(void)setDisplayText:(NSString *)displayText;


@property NSString* displayText;

@end
