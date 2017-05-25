//
//  GraphicOtherController.h
//  ACSDraw
//
//  Created by Alan on 10/12/2014.
//
//

#import "ViewController.h"

void MoveRowsFromIndexSetToPosition(NSMutableArray* arr,NSIndexSet *ixs,NSInteger pos);

extern NSString *ACSDrawGraphicIdxPasteboardType;
extern NSString *ACSDrawGraphicAttribIdxPasteboardType;

enum
{
    GOC_SOURCE_CHANGE = 1,
	GOC_SELECTION_CHANGE = 2,
	GOC_ATTRIBUTE_CHANGE = 4
};

@interface GraphicOtherController : ViewController<NSTableViewDataSource,NSTableViewDelegate>

@property (assign) IBOutlet NSTableView *graphicsTableView;
@property (assign) IBOutlet NSTableView *attributesTableView;
@property (retain) NSMutableArray *tempAttributes;

@end
