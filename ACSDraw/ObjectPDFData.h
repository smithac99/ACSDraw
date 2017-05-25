//
//  ObjectPDFData.h
//  ACSDraw
//
//  Created by alan on 16/02/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ACSDGraphic.h"

@interface ObjectPDFData : NSObject 
   {
	NSPoint offset;
	NSData *pdfData;
	NSRect bounds;
   }

- (id)initWithObject:(ACSDGraphic*)object;
- (NSPoint)offset;
- (NSData*)pdfData;
- (NSRect)bounds;


@end
