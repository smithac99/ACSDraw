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
@property NSPoint offset;
@property (retain) NSData *pdfData;
@property NSRect bounds;

- (id)initWithObject:(ACSDGraphic*)object;
- (NSPoint)offset;
- (NSData*)pdfData;
- (NSRect)bounds;


@end
