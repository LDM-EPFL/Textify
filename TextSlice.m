//
//  TextSlice.m
//  CyborgameSubtitler
//
//  Created by Andrew on 9/7/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import "TextSlice.h"

@implementation TextSlice

- (id) init {
    self = [super init];
    if (self != nil) {
    	_displayText = [[NSString alloc] init];
    }
    return self;
}

-(NSString *)displayText{
    return _displayText;
}


-(void)setDisplayText:(NSString *)userInput{

    // Eliminate blank lines from this block
    NSArray *splitContents = [userInput componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
    
    NSString *cleanedOutput=[[NSString alloc] init];
    BOOL firstLine=true;
    for(NSString* line in splitContents){
        if([line length] > 0){
            if(!firstLine){
                cleanedOutput=[NSString stringWithFormat:@"%@\n%@",cleanedOutput,line];
            }else{
                cleanedOutput=line;
                firstLine=false;
            }
        }
    }
    
    
    _displayText=cleanedOutput;
}

@end
