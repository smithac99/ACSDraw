//
//  XXAttributedStringAdditions.mm
//  ACSDraw
//
//  Created by alan on 30/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XXAttributedStringAdditions.h"


@implementation XXAttributedString(XXAttributedStringAdditions)

+(id)XXAttributedStringWithNSAttributedString:(NSAttributedString*)nsas
{
	return [[XXAttributedString alloc]initWithNSAttributedString:nsas];
}

-(id)initWithNSAttributedString:(NSAttributedString*)nsas
{
	if (self = [super init])
	{
		self.string = [[nsas string]copy];
		if ([self.string length] > 0)
		{
			NSRange effectiveRange = NSMakeRange(0, 0);
			NSFont *f = [nsas attribute:NSFontAttributeName atIndex:NSMaxRange(effectiveRange) effectiveRange:&effectiveRange];
			self.fontSize = [f pointSize];
			self.fontName = [[f fontName]copy];
		}
	}
	return self;
}

@end
