//
//  TextField_keyHandler.m
//  Textify
//
//  Created by Andrew on 9/17/13.
//  Copyright (c) 2013 Vox Fera. All rights reserved.
//

#import "TextField_keyHandler.h"

@implementation TextField_keyHandler



- (void)keyUp:(NSEvent *)theEvent{
    
    NSString*   const   character   =   [theEvent charactersIgnoringModifiers];
    unichar     const   code        =   [character characterAtIndex:0];
    
    switch (code){
        case NSUpArrowFunctionKey:NSRightArrowFunctionKey:{
            self.floatValue=self.floatValue+.1;
            break;
        }case NSDownArrowFunctionKey:NSLeftArrowFunctionKey:{
           self.floatValue=self.floatValue-.1;
            break;
        }
    }
   
    
    
    
    NSString* updateValueAsString = [NSString stringWithFormat:@"%.2f",self.floatValue];
    NSDictionary *bindingInfo = [self infoForBinding:NSValueBinding];
    [[bindingInfo valueForKey:NSObservedObjectKey] setValue:updateValueAsString
                                                 forKeyPath:[bindingInfo valueForKey:NSObservedKeyPathKey]];

    
//    [self setFloatValue:2.2];
}
@end
