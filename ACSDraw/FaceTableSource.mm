#import "FaceTableSource.h"

@implementation FaceTableSource

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
   {
    //NSParameterAssert(rowIndex >= 0 && rowIndex < (int)[objectList count]);
    return [[objectList objectAtIndex:rowIndex]objectAtIndex:1];
   }


@end
