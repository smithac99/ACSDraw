/* ArrowListTableSource */

#import <Cocoa/Cocoa.h>

@class ACSDLineEnding;

@interface ArrowListTableSource : NSObject
{
    IBOutlet id tableView;
    IBOutlet id windowController;
}

@property (strong,nonatomic) 	NSMutableArray<ACSDLineEnding*> *arrowList;

@end
