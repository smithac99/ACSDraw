//
//  ACSDFreeHand.h
//  ACSDraw
//
//  Created by Alan Smith on 07/03/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ACSDGraphic.h"


@interface ACSDFreeHand : ACSDGraphic
   {
	NSMutableArray *points;
	int level;
	float pressureLevel;
   }

-(int)level;
-(float)pressureLevel;
- (void)uSetLevel:(float)l;
- (void)uSetPressureLevel:(float)l;

@end
