//
//  ACSDMatrix.h
//  ACSDraw
//
//  Created by alan on Sat Mar 22 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ACSDGraphic.h"
#import "TextCharacteristics.h"

extern NSString *cellHeightDidChangeNotification;
extern NSString *cellWidthDidChangeNotification;


@interface ACSDMatrix : ACSDGraphic<NSTextViewDelegate,TextCharacteristics>
   {
	int rows,columns;
	float topMargin,leftMargin,bottomMargin,rightMargin;
	VerticalAlignment verticalAlignment;
	NSMutableArray *cellContents;
	int editedRow,editedColumn;
	ACSDStroke *cellStroke;
	StrokeType strokeType;
	BOOL cellSizeFixed,noCellsFixed;
	float cellWidth,cellHeight;
   }

-(id)initWithName:(NSString*)n fill:(ACSDFill*)f stroke:(ACSDStroke*)str rect:(NSRect)r layer:(ACSDLayer*)l;
- (void)setCellContents:(NSMutableArray*)cc;
- (void)setRows:(int)r;
- (void)setColumns:(int)c;
- (void)setTopMargin:(float)f;
- (void)setLeftMargin:(float)f;
- (void)setRightMargin:(float)f;
- (void)setBottomMargin:(float)f;
- (void)setVerticalAlignment:(VerticalAlignment)v;
- (StrokeType)strokeType;
- (int)rows;
- (int)columns;
- (float)cellHeight;
- (float)cellWidth;
-(BOOL)cellSizeFixed;
-(BOOL)noCellsFixed;
-(void)setGraphicRows:(int)n notify:(BOOL)notify;
-(void)setGraphicColumns:(int)n notify:(BOOL)notify;
-(void)setGraphicCellHeight:(float)cellHeight notify:(BOOL)notify;
-(void)setGraphicCellWidth:(float)f notify:(BOOL)notify;
-(ACSDStroke*)setGraphicStrokeType:(StrokeType)s;
-(ACSDStroke*)cellStroke;
-(void)setCellStroke:(ACSDStroke*)s;
- (NSBezierPath *)cellPath;
- (NSBezierPath *)transformedCellPath;
-(void)setGraphicCellSizeFixed:(int)i notify:(BOOL)notify;
-(void)setGraphicNoCellsFixed:(int)i notify:(BOOL)notify;

@end
