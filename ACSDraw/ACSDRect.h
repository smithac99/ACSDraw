//
//  ACSDRect.h
//  ACSDraw
//
//  Created by Alan Smith on Mon Jan 14 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "ACSDGraphic.h"


@interface ACSDRect : ACSDGraphic<ACSDGraphicCornerRadius>

@property 	float cornerRadius,originalCornerRadius,originalCornerRatio;

+(id)rectWithRect:(NSRect)r;
-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l;

@end
