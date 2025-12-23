//
//  ACSDTypeSetter.m
//  ACSDraw
//
//  Created by Alan Smith on 23/07/2025.
//

#import "ACSDTypeSetter.h"

@implementation ACSDTypeSetter

- (BOOL)shouldBreakLineByWordBeforeCharacterAtIndex:(NSUInteger) charIndex
{
    NSAttributedString *as = [self.layoutManager attributedString];
    if (charIndex > 0)
    {
        unichar ch = [[as string] characterAtIndex:charIndex - 1];
        if (ch == '-')
            return NO;
    }
    return [super shouldBreakLineByWordBeforeCharacterAtIndex:charIndex];
}

@end
