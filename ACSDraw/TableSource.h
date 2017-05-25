/* TableSource */

#import <Cocoa/Cocoa.h>

@interface TableSource : NSObject
   {
    IBOutlet NSTableView *tableView;
    IBOutlet id windowController;
	NSMutableArray *objectList;
   }

- (void)setObjectList:(NSMutableArray*)list;
-(NSTableView*)tableView;
-(NSMutableArray*)objectList;

@end
