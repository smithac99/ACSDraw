//
//  NSView+Additions.h
//  ACSDraw
//
//  Created by alan on 21/10/15.
//
//

#import <Cocoa/Cocoa.h>

@interface NSView (Additions)

- (NSSize)scale;
- (void)setScale:(NSSize)newScale;
- (void)resetScaling;

@end
