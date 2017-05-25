/* LayerTableView */

#import <Cocoa/Cocoa.h>
#import "ACSDTableView.h"

#define SELECTION_COLUMN 3

enum
   {
	DRAG_TYPE_NONE = 0,
	DRAG_TYPE_NORMAL,
	DRAG_TYPE_SELECTION
   };

@interface LayerTableView : ACSDTableView
   {
	int dragType;
   }

+ (id)selectionImage:(int)num;
-(int)dragType;

@end
