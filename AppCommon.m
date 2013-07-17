//
//  AppCommon.m
//  PerformanceSpace
//
//  Created by Andrew on 6/14/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "AppCommon.h"

@implementation AppCommon

+ (AppCommon*)sharedInstance {
    static AppCommon *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init{
    if (self = [super init]){

        self.isFullscreen=false;
    }
    return self;
}

@end
