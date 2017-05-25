//
//  ACSDPolygon.h
//  ACSDraw
//
//  Created by alan on 14/05/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ACSDGraphic.h"


@interface ACSDPolygon : ACSDGraphic
   {
	int noSides;
	NSPoint pt0,pt1;
	NSPoint centrePoint;
	NSPoint oPt0,oPt1;
   }

-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l
		  noSides:(int)ns pt0:(NSPoint)p0 pt1:(NSPoint)p1;

-(int)noSides;
-(void)setNoSides:(int)ns;
-(NSPoint)pt0;
-(NSPoint)pt1;
-(void)setPt0:(NSPoint)p;
-(void)setPt1:(NSPoint)p;

@end
