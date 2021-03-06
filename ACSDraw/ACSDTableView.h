/* ACSDTableView */

#import <Cocoa/Cocoa.h>

#import "TableViewDelegate.h"

@interface ACSDTableView : NSTableView
   {
	NSInteger oldSelectedRow;
	NSUInteger modifierFlags;
	NSInteger clickedRow;
	NSInteger selectedRowPriorToClick;
   }

-(void)reDisplayRow:(NSInteger)row;
-(void)reDisplayRow:(NSInteger)row column:(NSInteger)col;
-(void)refreshSelectionIndicatorForRow:(NSInteger)row;
-(void)reloadRowAtIndex:(NSInteger)rowIndex;
-(NSInteger)oldSelectedRow;
-(void)setOldSelectedRow:(NSInteger)row;
-(NSInteger)modifierFlags;
-(NSInteger)clickedRow;
-(NSInteger)selectedRowPriorToClick;

-(void)editNextColumn;
-(void)editPrevColumn;
-(void)editNextRow;
-(void)editPrevRow;

@end

