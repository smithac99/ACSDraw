//
//  ACSDLabel.h
//  ACSDraw
//
//  Created by alan on 02/01/06.
//  Copyright 2006 Alan C Smith. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ACSDGraphic;
@class SVGWriter;

@interface ACSDLabel : NSObject 
   {
	ACSDGraphic *graphic;
	NSTextStorage *contents;
	float verticalPosition,
		horizontalPosition;		//-1.0 to 1.0
	BOOL flipped;
   }

- (id)initWithGraphic:(ACSDGraphic*)g;
- (id)initWithGraphic:(ACSDGraphic*)g contents:(NSTextStorage*)c verticalPosition:(float)vP horizontalPosition:(float)hP flipped:(bool)flip;
- (NSTextStorage*)contents;
- (void)setContents:(NSTextStorage*)cont;
- (void)setLabel:(NSTextStorage*)cont;

- (float)verticalPosition;
- (float)horizontalPosition;
- (void)setGraphic:(ACSDGraphic*)g;
- (void)setVerticalPosition:(float)vp;
- (void)setHorizontalPosition:(float)hp;
- (void)setFlipped:(BOOL)f;
- (BOOL)flipped;
- (void)drawForPath:(NSBezierPath*)bzP;
-(float)paddingRequiredForPath:(NSBezierPath*)bzP;
-(void)writeSVGData:(SVGWriter*)svgWriter;

@end
