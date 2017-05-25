//
//  GXPArchiveDelegate.mm
//  ACSDraw
//
//  Created by alan on 29/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GXPArchiveDelegate.h"
#import "XXColorAdditions.h"
#import "XXAttributedStringAdditions.h"
#import "XXImageAdditions.h"
#import "XXAffineTransformAdditions.h"


@implementation GXPArchiveDelegate

- (id)archiver:(NSKeyedArchiver *)archiver willEncodeObject:(id)object
{
	if ([object  isKindOfClass:[NSColor class]])
		return [XXColor XXColorWithNSColor:object];
	if ([object  isKindOfClass:[NSAttributedString class]])
		return [XXAttributedString XXAttributedStringWithNSAttributedString:object];
	if ([object  isKindOfClass:[NSImage class]])
		return [XXImage XXImageWithNSImage:object];
	if ([object  isKindOfClass:[NSAffineTransform class]])
		return [XXAffineTransform XXAffineTransformWithNSAffineTransform:object];
	return object;
}

-(BOOL)filterLayers:(BOOL)b
{
	return YES;
}

@end
