//
//  XXAttributedStringAdditions.h
//  ACSDraw
//
//  Created by alan on 30/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "XXAttributedString.h"

@interface XXAttributedString(XXAttributedStringAdditions)

+(id)XXAttributedStringWithNSAttributedString:(NSAttributedString*)nsas;
-(id)initWithNSAttributedString:(NSAttributedString*)nsas;

@end
