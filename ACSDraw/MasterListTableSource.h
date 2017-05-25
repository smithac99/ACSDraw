/* MasterListTableSource */

#import <Cocoa/Cocoa.h>

@interface MasterListTableSource : NSObject
   {
    IBOutlet NSTableView *tableView;
    IBOutlet id windowController;
	NSMutableArray *masterList;
   }

- (void)setMasterList:(NSMutableArray*)list;
-(NSArray*)masterList;

@end
