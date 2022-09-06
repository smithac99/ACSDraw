/* TableSource */

#import <Cocoa/Cocoa.h>

@interface TableSource : NSObject
   {
    IBOutlet NSTableView *tableView;
    IBOutlet id windowController;
   }
@property (nonatomic,strong) NSMutableArray *objectList;

-(NSTableView*)tableView;

@end
