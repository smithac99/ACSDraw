//
//  IComponent.mm
//  Drawtest4
//
//  Created by alan on 27/01/2005.
//  Copyright 2005 Alan C Smith. All rights reserved.
//

#import "IComponent.h"

IVertex *vertexForPoint(NSPoint pt,NSMutableDictionary *vDict);


@implementation IComponent

-(id)initWithVertex:(IVertex*)v
   {
    if (self = [super init])
	   {
		fromVertex = v;
		inside = NO;
		marked = NO;
		isCoincidentPoint = NO;
		children = [[NSMutableArray alloc]initWithCapacity:2];
	   }
	return self;
   }

-(id)initWithVertex:(IVertex*)v inside:(bool) ins
   {
    if (self = [self initWithVertex:v])
	   {
		inside = ins;
	   }
	return self;
   }

IVertex *vertexForPoint(NSPoint pt,NSMutableDictionary *vDict)
   {
	return [IVertex vertexForPoint:pt vertexDict:vDict];
   }

-(id)initWithPoint:(NSPoint)pt vertexDict:(NSMutableDictionary*)vDict
   {
    if (self = [super init])
	   {
		fromVertex = vertexForPoint(pt,vDict);
		marked = NO;
		inside = NO;
		isCoincidentPoint = NO;
		children = [[NSMutableArray alloc]initWithCapacity:2];
		collinearSection = NO;
	   }
	return self;
   }

-(id)initWithFromPoint:(NSPoint)fpt toPoint:(NSPoint)tpt vertexDict:(NSMutableDictionary*)vDict
   {
    if (self = [super init])
	   {
		fromVertex = vertexForPoint(fpt,vDict);
		toVertex = vertexForPoint(tpt,vDict);
		marked = NO;
		inside = NO;
		isCoincidentPoint = NO;
		children = [[NSMutableArray alloc]initWithCapacity:2];
		collinearSection = NO;
	   }
	return self;
   }

-(id)initWithX:(float)xVal y:(float)yVal vertexDict:(NSMutableDictionary*)vDict
   {
    return [self initWithPoint:NSMakePoint(xVal,yVal) vertexDict:vDict];
   }

-(void)dealloc
   {
	if (children)
		[children release];
	[super dealloc];
   }

- (NSString *)description
   {
	return [NSString stringWithFormat:@"From Vertex - %@; To Vertex - %@;inside - %@; noNegs: %d ",
		fromVertex,toVertex,[NSNumber numberWithBool:inside],noNegs];
   }

- (IVertex*)fromVertex
   {
	return fromVertex;
   }

- (NSPoint)fromPoint
   {
	return [fromVertex point];
   }

- (IVertex*)toVertex
   {
	return toVertex;
   }

- (NSPoint)toPoint
   {
	return [toVertex point];
   }

- (void)setToVertex:(IVertex*)v
   {
	toVertex = v;
   }

- (bool)inside
   {
	return inside;
   }

- (void)setInside:(bool)b
   {
	inside = b;
   }

- (bool)marked
   {
	return marked;
   }

- (void)setMarked:(bool)b
   {
	marked = b;
   }

- (bool)collinearSection
   {
	return collinearSection;
   }

- (void)setCollinearSection:(bool)b
   {
	collinearSection = b;
   }

- (int)noNegs
   {
	return noNegs;
   }

- (void)setNoNegs:(int)b
   {
	noNegs = b;
   }

- (bool)isCoincidentPoint
   {
	return isCoincidentPoint;
   }

- (void)setIsCoincidentPoint:(bool)b
   {
	isCoincidentPoint = b;
   }

- (NSMutableArray*)children
   {
	return children;
   }

- (void)expandChildrenHeadElement:(ISegElement**)head currentElement:(ISegElement**)curr;
   {
   }

- (int)componentIntersection:(IComponent*)c2 intersectPoints:(NSMutableArray*)intersectPoints 
	os:(NSMutableArray*)os ot:(NSMutableArray*)ot collinear:(bool*)collinear;
   {
	return NO;
   }

- (void)outlineComponentLeftLines:(NSMutableArray*)leftLines rightLines:(NSMutableArray*)rightLines strokeWidth:(float)strokeWidth vertexDict:(NSMutableDictionary*)vDict
   {
   }

@end
