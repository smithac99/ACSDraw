//
//  CanvasWriter.mm
//  ACSDraw
//
//  Created by alan on 13/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CanvasWriter.h"
#import "ACSDGraphic.h"


@implementation CanvasWriter

-(id)initWithBounds:(NSRect)r identifier:(NSString*)ident
   {
	if (self = [super init])
	   {
		bounds = r;
		identifier = [ident copy];
		contents = [[NSMutableString alloc]initWithCapacity:100];
		settings = [[NSMutableDictionary alloc]initWithCapacity:3];
	   }
	return self;
   }

-(void)dealloc
   {
	if (contents)
		[contents release];
	if (identifier)
		[identifier release];
	if (settings)
		[settings release];
	[super dealloc];
   }

-(NSMutableString*)contents
{
	return contents;
}

-(void)setObject:(id)obj forKey:(id)k
{
	[settings setObject:obj forKey:k];
}

-(id)objectForKey:(id)k
{
	return [settings objectForKey:k];
}

-(void)createDataForGraphic:(ACSDGraphic*)g
   {
	[contents appendFormat:@"function draw_%@()\n{\nvar ctx = document.getElementById('c_%@').getContext('2d');\n",identifier,identifier];
	[contents appendFormat:@"ctx.translate(0,%d);\n",(int)bounds.size.height];
	[contents appendString:@"ctx.scale(1,-1);\n"];
	[contents appendFormat:@"ctx.translate(%d,%d);\n",(int)-bounds.origin.x,(int)-bounds.origin.y];
	[g writeCanvasData:self];
	[contents appendFormat:@"\n}\n"];
   }


@end
