/* PatternDisplay */

#import <Cocoa/Cocoa.h>
#import "ACSDPattern.h"
#import "FlippableView.h"

@interface PatternDisplay : FlippableView
   {
    IBOutlet id controller;
    ACSDPattern *pattern;
   }
- (void)setPattern:(ACSDPattern*)patt;

@end
