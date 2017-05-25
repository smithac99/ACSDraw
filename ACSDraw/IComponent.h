//
//  IComponent.h
//  Drawtest4
//
//  Created by alan on 27/01/2005.
//  Copyright 2005 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IVertex.h"


@interface IComponent : NSObject
   {
	IVertex *fromVertex,*toVertex;
	bool inside,marked,isCoincidentPoint;
	int noNegs;
	NSMutableArray *children;
	bool collinearSection;
   }

-(id)initWithVertex:(IVertex*)v;
-(id)initWithVertex:(IVertex*)v inside:(bool) ins;
-(id)initWithPoint:(NSPoint)pt vertexDict:(NSMutableDictionary*)vDict;
-(id)initWithFromPoint:(NSPoint)fpt toPoint:(NSPoint)tpt vertexDict:(NSMutableDictionary*)vDict;
-(id)initWithX:(float)xVal y:(float)yVal vertexDict:(NSMutableDictionary*)vDict;
- (IVertex*)fromVertex;
- (IVertex*)toVertex;
- (NSPoint)fromPoint;
- (NSPoint)toPoint;
- (void)setToVertex:(IVertex*)v;
- (bool)inside;
- (bool)collinearSection;
- (void)setInside:(bool)b;
- (void)setCollinearSection:(bool)b;
- (bool)isCoincidentPoint;
- (void)setIsCoincidentPoint:(bool)b;
- (int)noNegs;
- (void)setNoNegs:(int)b;
- (NSMutableArray*)children;
- (void)expandChildrenHeadElement:(ISegElement**)head currentElement:(ISegElement**)curr;
- (int)componentIntersection:(IComponent*)c2 intersectPoints:(NSMutableArray*)intersectPoints 
	os:(NSMutableArray*)os ot:(NSMutableArray*)ot collinear:(bool*)collinear;
- (bool)marked;
- (void)setMarked:(bool)b;
- (void)outlineComponentLeftLines:(NSMutableArray*)leftLines rightLines:(NSMutableArray*)rightLines strokeWidth:(float)strokeWidth vertexDict:(NSMutableDictionary*)vDict;

@end
