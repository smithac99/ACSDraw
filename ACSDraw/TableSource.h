/* TableSource */

#import <Cocoa/Cocoa.h>

@interface TableSource : NSObject
   {
    IBOutlet NSTableView *tableView;
    IBOutlet id windowController;
   }
@property (nonatomic) NSMutableArray *objectList;

-(NSTableView*)tableView;

@end
