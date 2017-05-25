//
//  StrokeCell.h
//  ACSDraw
//
//  Created by Alan Smith on Sun Jan 27 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FocusCell.h"

@class ACSDStroke;

@interface StrokeCell : FocusCell
   {
	ACSDStroke *stroke;
	float textMarginSize;
   }

+(float)textMarginSize;

@end
