#import "FaceTableSource.h"

@implementation FaceTableSource

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
   {
    return [self.objectList[rowIndex]objectAtIndex:1];
   }


@end
