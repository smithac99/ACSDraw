//
//  ACSDCircle.h
//  ACSDraw
//
//  Created by Alan Smith on Sun Jan 20 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "ACSDGraphic.h"
@class XMLNode;

@interface ACSDCircle : ACSDGraphic<ACSDGraphicIndentable>
   {
   }

+(id)circleWithSVGNode:(XMLNode*)xmlnode settingsStack:(NSMutableArray*)settingsStack;
+(id)circleWithXMLNode:(XMLNode*)xmlnode settingsStack:(NSMutableArray*)settingsStack;

@end
