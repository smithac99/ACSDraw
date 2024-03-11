//
//  TextSizesDialogController.m
//  ACSDraw
//
//  Created by Alan Smith on 11/03/2024.
//

#import "TextSizesDialogController.h"
#import "ACSDText.h"

@interface TextSizesDialogController ()
{
    NSArray *savedObjects,*savedStrings;
}
@end

@implementation TextSizesDialogController

-(void)showDialog
{
    [self.textPanel makeKeyAndOrderFront:self];
}

-(void)startDrag
{
    NSArray *selectedObjs = [[[_windowController graphicView]selectedGraphics]allObjects];
    NSMutableArray *mObjects = [NSMutableArray array];
    NSMutableArray *mStrings = [NSMutableArray array];
    for (ACSDGraphic *g in selectedObjs)
    {
        if ([g isKindOfClass:[ACSDText class]])
        {
            [mObjects addObject:g];
            [mStrings addObject:[[(ACSDText*)g attributedString]copy]];
        }
    }
    savedObjects = mObjects;
    savedStrings = mStrings;
}

-(void)dragFontSize
{
    float val = [self.fontSizeSlider floatValue];
    float sc;
    if (val >= 0.0)
        sc = val + 1.0;
    else
        sc = 1.0 / (-val + 1);
    NSLog(@"%g %g",val,sc);
    for (NSInteger i = 0; i < [savedObjects count];i++)
    {
        ACSDText *tx = savedObjects[i];
        NSAttributedString *astr = savedStrings[i];
        NSMutableAttributedString *mstr = [[NSMutableAttributedString alloc]initWithAttributedString:astr];
        [mstr beginEditing];
        [astr enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0,[astr length]) options:0
                             usingBlock:^void (id value,NSRange r,BOOL *stop){
            NSFont *f = [astr attribute:NSFontAttributeName atIndex:r.location effectiveRange:NULL];
            float newSize = [f pointSize] * sc;
            NSLog(@"%g",newSize);
            NSFont *fnew = [[NSFontManager sharedFontManager]convertFont:f toSize:newSize];
            [mstr addAttribute:NSFontAttributeName value:fnew range:r];
        }];
        [mstr endEditing];
        [tx setGraphicContents:mstr];

    }
}

- (IBAction)fontSizeSliderHit:(id)sender
{
    NSEvent *ev = [[NSApplication sharedApplication] currentEvent];
    if (ev.type == NSEventTypeLeftMouseDown)
    {
        [self startDrag];
    }
    else if (ev.type == NSEventTypeLeftMouseUp)
    {
        [sender setFloatValue:0.0];
    }
    else if (ev.type == NSEventTypeLeftMouseDragged)
    {
        [self dragFontSize];
    }

}

-(void)dragLineHeight
{
    float val = [self.lineHeightSlider floatValue];
    float sc;
    if (val >= 0.0)
        sc = val + 1.0;
    else
        sc = 1.0 / (-val + 1);
    NSLog(@"%g",sc);
    for (NSInteger i = 0; i < [savedObjects count];i++)
    {
        ACSDText *tx = savedObjects[i];
        NSAttributedString *astr = savedStrings[i];
        NSMutableAttributedString *mstr = [[NSMutableAttributedString alloc]initWithAttributedString:astr];
        [mstr beginEditing];
        [astr enumerateAttribute:NSParagraphStyleAttributeName inRange:NSMakeRange(0,[astr length]) options:0
                             usingBlock:^void (id value,NSRange r,BOOL *stop){
            NSParagraphStyle *pst = [astr attribute:NSParagraphStyleAttributeName atIndex:r.location effectiveRange:NULL];
            float newSize = pst.lineHeightMultiple;
            NSLog(@"%g",newSize);
            if (newSize == 0)
                newSize = 1;
            newSize *= sc;
            NSLog(@"%g",newSize);
            NSMutableParagraphStyle *mpst = [pst mutableCopy];
            mpst.lineHeightMultiple = newSize;
            [mstr addAttribute:NSParagraphStyleAttributeName value:mpst range:r];
        }];
        [mstr endEditing];
        [tx setGraphicContents:mstr];

    }
}

- (IBAction)lineHeightSliderHit:(id)sender
{
    NSEvent *ev = [[NSApplication sharedApplication] currentEvent];
    if (ev.type == NSEventTypeLeftMouseDown)
    {
        [self startDrag];
    }
    else if (ev.type == NSEventTypeLeftMouseUp)
    {
        [sender setFloatValue:0.0];
    }
    else if (ev.type == NSEventTypeLeftMouseDragged)
    {
        [self dragLineHeight];
    }

}

-(void)dragTracking
{
    float val = [self.trackingSlider floatValue];
    for (NSInteger i = 0; i < [savedObjects count];i++)
    {
        ACSDText *tx = savedObjects[i];
        NSAttributedString *astr = savedStrings[i];
        NSMutableAttributedString *mstr = [[NSMutableAttributedString alloc]initWithAttributedString:astr];
        [mstr beginEditing];
        [astr enumerateAttribute:NSKernAttributeName inRange:NSMakeRange(0,[astr length]) options:0
                             usingBlock:^void (id value,NSRange r,BOOL *stop){
            float tracking = [value floatValue];
            tracking += val;
            [mstr addAttribute:NSKernAttributeName value:@(tracking) range:r];
        }];
        [mstr endEditing];
        [tx setGraphicContents:mstr];

    }
}
- (IBAction)trackingSliderHeight:(id)sender
{
    NSEvent *ev = [[NSApplication sharedApplication] currentEvent];
    if (ev.type == NSEventTypeLeftMouseDown)
    {
        [self startDrag];
    }
    else if (ev.type == NSEventTypeLeftMouseUp)
    {
        [sender setFloatValue:0.0];
    }
    else if (ev.type == NSEventTypeLeftMouseDragged)
    {
        [self dragTracking];
    }

}
- (IBAction)resetTracking:(id)sender
{
    NSArray *selectedObjs = [[[_windowController graphicView]selectedGraphics]allObjects];
    for (ACSDGraphic *g in selectedObjs)
    {
        if ([g isKindOfClass:[ACSDText class]])
        {
            NSAttributedString *astr = [[NSAttributedString alloc]initWithAttributedString:[((ACSDText*)g) attributedString]];
            NSMutableAttributedString *mstr = [[NSMutableAttributedString alloc]initWithAttributedString:astr];
            __block BOOL changed = NO;
            [mstr beginEditing];
            [astr enumerateAttribute:NSKernAttributeName inRange:NSMakeRange(0,[astr length]) options:0
                                 usingBlock:^void (id value,NSRange r,BOOL *stop){
                [mstr removeAttribute:NSKernAttributeName range:r];
                changed = changed || YES;
            }];
            [mstr endEditing];
            if (changed)
                [((ACSDText*)g) setGraphicContents:mstr];
        }
    }

}

@end
