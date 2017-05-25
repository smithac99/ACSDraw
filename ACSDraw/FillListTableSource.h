/* FillListTableSource */

#import <Cocoa/Cocoa.h>

@interface FillListTableSource : NSObject
   {
    IBOutlet id tableView;
    IBOutlet id windowController;
	NSMutableArray *fillList;
   }

- (void)setFillList:(NSMutableArray*)list;

@end
