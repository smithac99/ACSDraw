//
//  ACSDImageRep.h
//  ACSDraw
//
//  Created by Alan Smith on 02/02/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ACSDrawDocument;
@class GraphicView;

@interface ACSDImageRep : NSImageRep
{
	ACSDrawDocument *document;
	GraphicView *graphicView;
	NSData *data;
}

- (id)initWithData:(NSData*)d;

@end
