//
//  ApplyStyleDialogController.m
//  ACSDraw
//
//  Created by Alan Smith on 09/03/2024.
//

#import "ApplyStyleDialogController.h"
#import "GraphicView.h"
#import "MainWindowController.h"
#import "ACSDStyle.h"
#import "ACSDrawDocument.h"
#import "ACSDText.h"
#import "ACSDPage.h"

@implementation ApplyStyleDialogController

-(void)showDialog
{
    self.styleList = [[windowController document]styles];
    [self.styleTableView reloadData];
    [self.dialog makeKeyAndOrderFront:self];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if (rowIndex < 0 || rowIndex >= [self.styleList count])
        return nil;
    return [_styleList[rowIndex] name];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_styleList count];
}

/*-(NSArray<ACSDGraphic*>*)selectedCandidates
{
    GraphicView *gv = [windowController graphicView];
    NSArray *graphics = [[gv selectedGraphics]allObjects];
    NSIndexSet *ixs = [graphics indexesOfObjectsPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj isKindOfClass:[ACSDText class]];
    }];
    return [graphics objectsAtIndexes:ixs];
}

-(NSArray<ACSDGraphic*>*)layerCandidates
{
    GraphicView *gv = [windowController graphicView];
    NSArray *graphics = [[gv currentEditableLayer]graphics];
    NSIndexSet *ixs = [graphics indexesOfObjectsPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj isKindOfClass:[ACSDText class]];
    }];
    return [graphics objectsAtIndexes:ixs];
}

-(NSArray<ACSDGraphic*>*)pageCandidates
{
    GraphicView *gv = [windowController graphicView];
    NSMutableArray *graphics = [NSMutableArray array];
    for (ACSDLayer *l in [gv currentPage].layers)
        [graphics addObjectsFromArray:[l graphics]];

    NSIndexSet *ixs = [graphics indexesOfObjectsPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj isKindOfClass:[ACSDText class]];
    }];
    return [graphics objectsAtIndexes:ixs];
}

-(NSArray<ACSDGraphic*>*)globalCandidates
{
    NSMutableArray *graphics = [NSMutableArray array];
    for (ACSDPage *p in [[windowController document]pages])
        for (ACSDLayer *l in p.layers)
            [graphics addObjectsFromArray:[l graphics]];
    NSIndexSet *ixs = [graphics indexesOfObjectsPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj isKindOfClass:[ACSDText class]];
    }];
    return [graphics objectsAtIndexes:ixs];
}*/
-(NSArray<ACSDGraphic*>*)candidates
{
    int scopeIdx = (int)[_regexpScope indexOfSelectedItem];
    NSArray *graphics = [windowController graphicsForScope:scopeIdx];
    NSString *regexpString = [self.regexpPattern stringValue];
    if ([regexpString length] == 0)
        return graphics;
    NSString *pattern = [NSString stringWithFormat:@"^%@$",regexpString];
    NSError *err = nil;
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&err];
    if (err)
    {
        NSAttributedString *as = [[NSAttributedString alloc]initWithString:[err localizedDescription] attributes:@{NSForegroundColorAttributeName:[NSColor redColor]}];
        [self.message setAttributedStringValue:as];
        return @[];
    }
    NSIndexSet *ixs = [graphics indexesOfObjectsPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *nm = [obj name];
        return [regexp numberOfMatchesInString:nm options:0 range:NSMakeRange(0, [nm length])] > 0;
    }];
    return [graphics objectsAtIndexes:ixs];
}

- (IBAction)applyStyle:(id)sender
{
    [self.message setStringValue:@""];
    NSArray *texts = [self candidates];
    if ([texts count] > 0)
    {
        NSInteger changed = 0;
        ACSDStyle *style = self.styleList[[_styleTableView selectedRow]];
        for (ACSDText *text in texts)
        {
            //[text updateWholeWithNewStyle:style];
            NSAttributedString *astr = [text attributedString];
            NSAttributedString *updatedString = [ACSDText applyStyle:style toAttributedString:astr];
            if (![updatedString isEqual:astr])
            {
                [text setGraphicContents:updatedString];
                changed++;
            }
        }
        NSString *pl = changed != 1 ? @"s":@"";
        if (changed > 0)
        {
            NSString *actionName = [NSString stringWithFormat:@"Update style for %d graphic%@",(int)changed,pl];
            [[[windowController document]undoManager]setActionName:actionName];
        }
        [self.message setStringValue:[NSString stringWithFormat:@"%d graphic%@ updated",(int)changed,pl]];

    }
}

- (IBAction)close:(id)sender
{
}

@end
