//
//  CanvasWriter.h
//  ACSDraw
//
//  Created by alan on 13/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class ACSDGraphic;

@interface CanvasWriter : NSObject 
{
	NSMutableString *contents;
	NSRect bounds;
	NSString *identifier;
	NSMutableDictionary* settings;
}

-(id)initWithBounds:(NSRect)r identifier:(NSString*)ident;
-(NSMutableString*)contents;
-(void)createDataForGraphic:(ACSDGraphic*)g;
-(void)setObject:(id)obj forKey:(id)k;
-(id)objectForKey:(id)k;

@end
