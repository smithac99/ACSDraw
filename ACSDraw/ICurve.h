//
//  ICurve.h
//  Drawtest4
//
//  Created by alan on 27/01/2005.
//  Copyright 2005 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IComponent.h"


@interface ICurve : IComponent
   {
   }

@property 	NSPoint cp1,cp2;

-(id)initWithVertex:(IVertex*)v controlPoint1:(NSPoint)cpt1 controlPoint2:(NSPoint)cpt2;
-(id)initWithVertex:(IVertex*)v inside:(bool)ins controlPoint1:(NSPoint)cpt1 controlPoint2:(NSPoint)cpt2;
-(id)initWithPoint:(NSPoint)pt controlPoint1:(NSPoint)cpt1 controlPoint2:(NSPoint)cpt2 vertexDict:(NSMutableDictionary*)vDict ;
-(id)initWithFromPoint:(NSPoint)fpt toPoint:(NSPoint)tpt controlPoint1:(NSPoint)cpt1 controlPoint2:(NSPoint)cpt2 vertexDict:(NSMutableDictionary*)vDict;
- (void)getNegIntersectionsPtA:(NSPoint)a ptB:(NSPoint)b intersectPoints:(NSMutableArray*)intersectPoints 
	os:(NSMutableArray*)os ot:(NSMutableArray*)ot;

@end
