//
//  ACSDGrid.h
//  ACSDraw
//
//  Created by alan on 14/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ACSDGraphic.h"

extern NSString *cellHeightDidChangeNotification;
extern NSString *cellWidthDidChangeNotification;


enum
{
	GRID_MODE_FIXED_NO_CELLS,
	GRID_MODE_FIXED_CELL_DIMENSION 
};

@interface ACSDGrid : ACSDGraphic
{
	int rows,columns;
	int gridMode;
	float cellWidth,cellHeight;
}

+ (NSString*)graphicTypeName;
- (void)setRows:(int)r;
- (void)setColumns:(int)c;
- (int)rows;
- (int)columns;
- (float)cellHeight;
- (float)cellWidth;
- (int)gridMode;
-(void)setGraphicRows:(int)n notify:(BOOL)notify;
-(void)setGraphicColumns:(int)n notify:(BOOL)notify;
-(void)setGraphicGridMode:(int)i notify:(BOOL)notify;
-(void)setGraphicCellHeight:(float)f notify:(BOOL)notify;
-(void)setGraphicCellWidth:(float)f notify:(BOOL)notify;

@end
