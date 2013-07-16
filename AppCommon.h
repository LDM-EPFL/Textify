//
//  AppCommon.h
//  PerformanceSpace
//
//  Created by Andrew on 6/14/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//
//////////////////////////////////////////////////////////
//  Singleton used to store shared variables
//////////////////////////////////////////////////////////
@interface AppCommon : NSObject{}

// Custom properties for this ap
@property bool f_goWindowed;
@property bool f_goFullscreen;
@property bool isFullscreen;


+ (AppCommon *)sharedInstance;




@end


