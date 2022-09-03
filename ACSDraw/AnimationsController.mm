//
//  AnimationsController.m
//  ACSDraw
//
//  Created by Alan on 30/06/2014.
//
//

#import "AnimationsController.h"
#import "GraphicView+GraphicViewAdditions.h"
#import "ACSDPage.h"
#import "ACSDLayer.h"
#import "ACSDGraphic.h"
#import "AnimationEntry.h"
#import "geometry.h"
#import <AVFoundation/AVFoundation.h>
#import "gSubPath.h"
#import "ACSDPath.h"
#import "ACSDPathElement.h"

AnimationsController *animationsController;

NSString *ACSDrawAEIdxType = @"ACSDrawAEIdxType";

void DoBlockOnMain(void (^block)())
{
	if ([NSThread isMainThread])
	{
		block();
	}
	else
		dispatch_sync(dispatch_get_main_queue(), ^{
			DoBlockOnMain(block);
		});
}

@implementation AnimationsController

-(id)init
{
	if (self = [super initWithTitle:@"Animations"])
	{
		NSInteger l = [NSDate timeIntervalSinceReferenceDate]*100;
		self.tempDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"ACSDraw%ld",(long)l]];
		NSError *err;
		if (![[NSFileManager defaultManager]createDirectoryAtPath:self.tempDirectory withIntermediateDirectories:NO attributes:nil error:&err])
			NSLog(@"Unable to create temp directory %@:%@",self.tempDirectory,[err localizedDescription]);
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)zeroControls
{
	[animationTableView setAllowsEmptySelection:YES];
    self.animationList = nil;
	[animationTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
	[animationTableView reloadData];
    [textView setString:@""];
}

-(void)setControls
{
	if (![self inspectingGraphicView])
    {
        [self zeroControls];
		return;
    }
    if (self.changed & AC_PAGE_CHANGE)
    {
        self.changed |= AC_SELECTION_CHANGE;
        [self setActionsDisabled:YES];
        self.animationList = [[[self inspectingGraphicView] currentPage]animations];
        [animationTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
        [animationTableView reloadData];
        [self setActionsDisabled:NO];
    }
    if (self.changed & AC_SELECTION_CHANGE)
    {
        NSInteger rowIndex = [animationTableView selectedRow];
        if (rowIndex >= 0 && rowIndex < [_animationList count])
        {
            [textView setString:[_animationList[rowIndex] text]];
        }
    }
}

- (void)pageChanged:(NSNotification *)notification				//page changed by graphicView
{
	[self addChange:AC_PAGE_CHANGE];
}

-(void)updateControls
{
	[self setControls];
}

-(void)animationTableSelectionChange:(NSInteger)idx
{
    if (idx < 0 || idx >= [_animationList count])
        return;
    [self addChange:AC_SELECTION_CHANGE];
    //AnimationEntry *ae = _animationList[idx];
    //[textView setString:[ae text]];
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    animationsController = self;
	rowForContextualMenu = -1;
	displayRowForContextualMenu = -1;
    self.errMsg = @"";
	[animationTableView registerForDraggedTypes:[NSArray arrayWithObjects:ACSDrawAEIdxType,nil]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pageChanged:) name:ACSDPageChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unsetRowForContextualMenu:) name:NSMenuDidEndTrackingNotification object:nil];
}

#pragma mark
#pragma mark actions

static NSArray *decomposed(NSString *command)
{
    NSRange r = [command rangeOfString:@"(" options:0];
    if (r.location == 0 || r.length == 0)
        return @[@"",@""];
    NSString *verb = [[command substringToIndex:r.location]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    verb = [verb lowercaseString];
    NSInteger idx = r.location + 1;
    r = [command rangeOfString:@")" options:0 range:NSMakeRange(idx, [command length] - idx)];
    if (r.length == 0)
        return @[verb,@""];
    return @[verb,[command substringWithRange:NSMakeRange(idx, r.location - idx)]];
}

-(BOOL)interpretCommand:(NSString*)command
{
    NSArray *decomp = decomposed(command);
    NSString *verb = decomp[0];
    NSString *selstring = [verb stringByAppendingString:@":"];
    if (selstring)
    {
        SEL selector = NSSelectorFromString(selstring);
        if ([self respondsToSelector:selector])
        {
            if ([self performSelector:selector withObject:decomp[1]])
                return YES;
        }
        else
            self.errMsg = [NSString stringWithFormat:@"%@ not found",verb];
    }
    return NO;
}

-(IBAction)playHit:(id)sender
{
    self.errMsg = @"";
    if (_animationList == nil)
        return;
    self.currentPage = [[self inspectingGraphicView]currentPage];
    if (self.currentPage == nil)
        return;
    self.pageBounds = [[self inspectingGraphicView] bounds];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		for (AnimationEntry *ae in _animationList)
		{
			NSArray *commands = [ae.text componentsSeparatedByString:@"\n"];
			for (NSString *command in commands)
			{
				[self interpretCommand:command];
			}
		}
	});
}

-(IBAction)playToHereHit:(id)sender
{
    self.errMsg = @"";
    if (_animationList == nil)
        return;
    self.currentPage = [[self inspectingGraphicView]currentPage];
    if (self.currentPage == nil)
        return;
    self.pageBounds = [[self inspectingGraphicView] bounds];
    NSInteger rowIndex = [self significantRow];
    NSArray *animations = [_animationList subarrayWithRange:NSMakeRange(0, rowIndex+1)];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		for (AnimationEntry *ae in animations)
		{
			NSArray *commands = [ae.text componentsSeparatedByString:@"\n"];
			for (NSString *command in commands)
			{
				[self interpretCommand:command];
			}
		}
	});
}

-(NSString*)snapshotString
{
    NSMutableString *mstr = [NSMutableString stringWithCapacity:40];
    NSRect bnds = self.pageBounds;
    for (ACSDLayer *layer in [self.currentPage layers])
    {
        if (![layer visible])
            [mstr appendFormat:@"layer(%@,hide)\n",[layer name]];
        for (ACSDGraphic *g in [layer graphics])
        {
            NSPoint pt = [g positionRelativeToRect:bnds];
            [mstr appendFormat:@"Position(%@,%g,%g,)\n",[g name],pt.x,pt.y];
            if ([g alpha] < 1.0)
                [mstr appendFormat:@"Opacity(%@,%g)\n",[g name],[g alpha]];
        }
    }
    return mstr;
}

-(NSString*)moveStringForGraphics:(NSArray*)graphics time:(NSTimeInterval)duration
{
    NSMutableString *mstr = [NSMutableString stringWithCapacity:40];
    NSRect bnds = self.pageBounds;
	for (ACSDGraphic *g in graphics)
	{
		NSPoint pt = [g positionRelativeToRect:bnds];
		[mstr appendFormat:@"Move(%@,%g,%g,,%g)\n",[g name],pt.x,pt.y,duration];
	}
    return mstr;
}

-(ACSDGraphic*)graphicWithName:(NSString*)nm
{
	if (nm == nil)
		return nil;
    for (ACSDLayer *layer in [self.currentPage layers])
    {
        for (ACSDGraphic *g in [layer graphics])
            if ([[g name] isEqual:nm])
                return g;
    }
    return nil;
}

-(ACSDLayer*)layerWithName:(NSString*)nm
{
	if (nm == nil)
		return nil;
    for (ACSDLayer *layer in [self.currentPage layers])
    {
        if ([[layer name] isEqual:nm])
            return layer;
    }
    return nil;
}

-(void)addAnimation:(AnimationEntry*)ae atIndex:(NSInteger)rowIndex
{
    [_animationList insertObject:ae atIndex:rowIndex];
    [animationTableView reloadData];
    [animationTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
}

-(void)addAnimation:(AnimationEntry*)ae
{
    NSInteger rowIndex = [animationTableView selectedRow];
    if (rowIndex < 0 || rowIndex >= [_animationList count])
        rowIndex = [_animationList count];
    else
        rowIndex ++;
    [self addAnimation:ae atIndex:rowIndex];
}

-(IBAction)snapshotHit:(id)sender
{
    if (_animationList == nil)
        return;
    self.currentPage = [[self inspectingGraphicView]currentPage];
    if (self.currentPage == nil)
        return;
    self.pageBounds = [[self inspectingGraphicView] bounds];
    AnimationEntry *ae = [[AnimationEntry alloc]init];
    ae.name = @"snapshot";
    ae.text = [self snapshotString];
    ae.flags = AE_IS_SNAPSHOT;
	[self addAnimation:ae];
}

-(NSInteger)lastSnapshotIndexBefore:(NSInteger)rowIndex
{
    if (_animationList == nil)
        return -1;
    while (rowIndex >= 0)
    {
        AnimationEntry *ae = _animationList[rowIndex];
        if (ae.flags & AE_IS_SNAPSHOT)
            return rowIndex;
        rowIndex--;
    }
    return -1;
}

-(NSMutableDictionary*)opacityStateUpTo:(NSInteger)idx
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:10];
    for (ACSDLayer *layer in [self.currentPage layers])
    {
        for (ACSDGraphic *g in [layer graphics])
            dict[[g name]] = @1.0;
    }
    for (NSInteger i = 0;i <= idx;i++)
    {
        AnimationEntry *ae = _animationList[i];
        NSArray *commands = [ae.text componentsSeparatedByString:@"\n"];
        for (NSString *command in commands)
        {
            NSArray *decomp = decomposed(command);
            if ([decomp[0]isEqualToString:@"opacity"])
            {
                NSArray *params = [decomp[1]componentsSeparatedByString:@","];
                if ([params count] >= 2)
                {
                    float x = [params[1]floatValue];
                    dict[params[0]] = @(x);
                }
            }
        }
    }
    return dict;
}

-(NSMutableDictionary*)snapshotStateUpTo:(NSInteger)idx
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:10];
    for (ACSDLayer *layer in [self.currentPage layers])
    {
        for (ACSDGraphic *g in [layer graphics])
        {
            NSMutableDictionary *gdict = [NSMutableDictionary dictionaryWithCapacity:10];
            gdict[@"opacity"] = @1.0;
            gdict[@"pos"] = [NSValue valueWithPoint:[g centrePoint]];
            dict[[g name]] = gdict;
        }
    }
    for (NSInteger i = 0;i <= idx;i++)
    {
        AnimationEntry *ae = _animationList[i];
        NSArray *commands = [ae.text componentsSeparatedByString:@"\n"];
        for (NSString *command in commands)
        {
            NSArray *decomp = decomposed(command);
            if ([decomp[0]isEqualToString:@"opacity"])
            {
                NSArray *params = [decomp[1]componentsSeparatedByString:@","];
                if ([params count] >= 2)
                {
                    float x = [params[1]floatValue];
                    NSString *nm = params[0];
                    NSMutableDictionary *gdict = dict[nm];
                    gdict[@"opacity"] = @(x);
                }
            }
            else if ([decomp[0]isEqualToString:@"position"]||[decomp[0]isEqualToString:@"move"])
            {
                NSArray *arr = [self positionParams:decomp[1]];
                if ([arr count] >= 2)
                {
                    NSPoint loc = [arr[1] pointValue];
                    NSString *nm = arr[0];
                    NSMutableDictionary *gdict = dict[nm];
                    gdict[@"pos"] = [NSValue valueWithPoint:loc];
                }
            }
        }
    }
    return dict;
}

-(NSInteger)significantRow
{
    if (_animationList == nil)
        return -1;
    NSInteger rowIndex;
    if (rowForContextualMenu > -1)
        rowIndex = rowForContextualMenu;
    else
        rowIndex = [animationTableView selectedRow];
    if (rowIndex < 0 || rowIndex >= [_animationList count])
        rowIndex = [_animationList count]-1;
    return rowIndex;
}

-(void)addEntryWithName:(NSString*)nm text:(NSString*)text
{
    NSInteger rowIndex = [self significantRow];
    if (rowIndex < 0)
        return;
    AnimationEntry *ae = [[AnimationEntry alloc]init];
    ae.name =nm;
    ae.text = text;
	[self addAnimation:ae atIndex:rowIndex+1];
}

-(IBAction)duplicateHit:(id)sender
{
    NSInteger rowIndex = [self significantRow];
    if (rowIndex < 0)
        return;
    AnimationEntry *ae = [_animationList[rowIndex]copy];
	[self addAnimation:ae atIndex:rowIndex+1];
}

-(IBAction)deleteAnim:(id)sender
{
    NSInteger rowIndex = [self significantRow];
    if (rowIndex < 0)
        return;
    [_animationList removeObjectAtIndex:rowIndex];
    [animationTableView reloadData];
}

-(IBAction)sayHit:(id)sender
{
    [self addEntryWithName:@"Say" text:@"Say()"];
}

-(IBAction)waitHit:(id)sender
{
    [self addEntryWithName:@"Wait" text:@"Wait(1.0)"];
}

-(IBAction)waitSpeechHit:(id)sender
{
    [self addEntryWithName:@"Wait Speech" text:@"WaitSpeech()"];
}

-(IBAction)opacityHit:(id)sender
{
    NSInteger rowIndex = [self significantRow];
    if (rowIndex < 0)
        return;
    NSMutableDictionary *opDict = [self opacityStateUpTo:rowIndex];
    NSMutableString *mstr = [NSMutableString stringWithCapacity:60];
    for (ACSDLayer *layer in [self.currentPage layers])
    {
        if (![layer visible])
            [mstr appendFormat:@"layer(%@,hide)\n",[layer name]];
        for (ACSDGraphic *g in [layer graphics])
            if ([opDict[[g name]]floatValue]!= [g alpha])
                [mstr appendFormat:@"opacity(%@,%@)\n",[g name],opDict[[g name]]];
    }
    AnimationEntry *ae = [[AnimationEntry alloc]init];
    ae.name = @"opacity";
    ae.text = mstr;
	[self addAnimation:ae];
}

-(IBAction)recordMoves:(id)sender
{
	[[self inspectingGraphicView]setRecordNextMove:YES];
}

-(void)graphicsDidMove:(NSArray*)graphics
{
	if (_animationList == nil)
        return;
    AnimationEntry *ae = [[AnimationEntry alloc]init];
    ae.name = @"move";
    ae.text = [self moveStringForGraphics:graphics time:1.0];
	[self addAnimation:ae];
}

#pragma mark
#pragma mark table stuff

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(int)rowIndex
{
    if (rowIndex < 0 || rowIndex >= [_animationList count])
        return nil;
    return [_animationList[rowIndex] name];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn
              row:(int)rowIndex
{
    if (rowIndex < 0 || rowIndex >= [_animationList count])
        return;
    [(AnimationEntry*)_animationList[rowIndex]setName:anObject];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if (_animationList)
		return [_animationList count];
	return 0;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notif
{
	if ([self actionsDisabled])
		return;
	if ([notif object] == animationTableView)
		[self animationTableSelectionChange:[animationTableView selectedRow]];
}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
	[pboard declareTypes:@[ACSDrawAEIdxType] owner:self];
	return [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:rowIndexes] forType:ACSDrawAEIdxType];
}

- (NSDragOperation)tableView:(NSTableView*)tabView validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	if (operation == NSTableViewDropOn)
		return  NSDragOperationNone;
	else
		return NSDragOperationMove;
}

- (NSInteger)moveAnimationEntryFromIndex:(NSInteger)fromInd toIndex:(NSInteger)toInd
{
	if (fromInd == toInd)
		return toInd;
	if (fromInd < toInd)
	{
		//[[[self undoManager] prepareWithInvocationTarget:self] moveLayerFromIndex:toInd-1 toIndex:fromInd];
		[_animationList insertObject:_animationList[fromInd] atIndex:toInd];
		[_animationList removeObjectAtIndex:fromInd];
        return toInd - 1;
	}
	else
	{
		//[[[self undoManager] prepareWithInvocationTarget:self] moveLayerFromIndex:toInd toIndex:fromInd+1];
		id obj = _animationList[fromInd];
		[_animationList removeObjectAtIndex:fromInd];
		[_animationList insertObject:obj atIndex:toInd];
        return toInd;
	}
	//[[self undoManager] setActionName:@"Move Layer"];
}

- (BOOL)tableView:(NSTableView*)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
	GraphicView *graphicView = [self inspectingGraphicView];
	if (!graphicView)
		return NO;
	NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:ACSDrawAEIdxType];
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    NSUInteger dragRow = [rowIndexes firstIndex];
	row = [self moveAnimationEntryFromIndex:dragRow toIndex:row];
    self.actionsDisabled = YES;
	[animationTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    self.actionsDisabled = NO;
	[animationTableView reloadData];
	return YES;
}

#pragma mark
#pragma mark text

- (void)textDidChange:(NSNotification *)aNotification
{
    NSInteger rowIndex = [animationTableView selectedRow];
    if (rowIndex < 0 || rowIndex >= [_animationList count])
        return;
    [(AnimationEntry*)_animationList[rowIndex]setText:[textView string]];
}

#pragma mark
#pragma mark commands

-(void)waitForSecs:(NSTimeInterval)secs
{
	NSConditionLock *lock = [[NSConditionLock alloc]initWithCondition:PROCESS_NOT_DONE];
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, secs * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[lock lock];
		[lock unlockWithCondition:PROCESS_DONE];
	});
	[lock lockWhenCondition:PROCESS_DONE];
	[lock unlock];
}

-(void)animGraphicMove:(ACSDGraphic*)g from:(NSPoint)from to:(NSPoint)to duration:(NSTimeInterval)secs
{
	if (secs == 0)
	{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [g setPosition:to];
        });
		return;
	}
    NSTimeInterval starttime = [NSDate timeIntervalSinceReferenceDate];
    float duration = secs;
    float frac = 0;
    while (frac <= 1.0)
    {
        NSTimeInterval currtime = [NSDate timeIntervalSinceReferenceDate];
        frac = (currtime - starttime) / duration;
        float t = clamp01(frac);
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSPoint pt = tPointAlongLine(t, from, to);
			[g setPosition:pt];
        });
        [self waitForSecs:0.02];
    }
}

-(void)animPathGrow:(ACSDPath*)g duration:(NSTimeInterval)secs
{
	if (secs == 0)
	{
		return;
	}
	NSMutableArray *originalSubPaths = [g subPaths];
	NSArray *gSubPaths = [gSubPath gSubPathsFromACSDSubPaths:originalSubPaths];
    NSTimeInterval starttime = [NSDate timeIntervalSinceReferenceDate];
    float duration = secs;
    float frac = 0;
    while (frac <= 1.0)
    {
        NSTimeInterval currtime = [NSDate timeIntervalSinceReferenceDate];
        frac = (currtime - starttime) / duration;
        float t = clamp01(frac);
		NSArray *fractionalGSubPaths = [gSubPath s:t alongGSubPaths:gSubPaths];
        dispatch_sync(dispatch_get_main_queue(), ^{
			NSBezierPath *bp = [NSBezierPath bezierPath];
			for (gSubPath *gsp in fractionalGSubPaths)
				[bp appendBezierPath:[gsp bezierPath]];
			NSMutableArray *acsdSubPaths = [ACSDSubPath subPathsFromBezierPath:bp];
			[g invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
			[g setSubPathsAndRebuild:acsdSubPaths];
        });
        [self waitForSecs:0.02];
    }
	dispatch_sync(dispatch_get_main_queue(), ^{
		[g invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
		[g setSubPathsAndRebuild:originalSubPaths];
	});
}

-(void)snapAnimMoves:(NSArray*)animMoves startTime:(NSTimeInterval)startTime adaptor:(AVAssetWriterInputPixelBufferAdaptor*)adaptor
{
    NSTimeInterval currTime = startTime;
    NSTimeInterval interval = 1.0 / 30.0;
    BOOL finished = NO;
    while (!finished)
    {
        finished = YES;
        for (NSMutableDictionary *animdict in animMoves)
        {
            BOOL done = [animdict[@"done"]boolValue];
            if (!done)
            {
                NSTimeInterval duration = [animdict[@"duration"]floatValue];
                float frac = (currTime - startTime) / duration;
                float t = clamp01(frac);
                NSPoint from = [animdict[@"from"]pointValue];
                NSPoint to = [animdict[@"to"]pointValue];
                NSPoint pt = tPointAlongLine(t, from, to);
                ACSDGraphic *g = [self graphicWithName:animdict[@"name"]];
                [g setPosition:pt];
                if (frac >= 1.0)
                    animdict[@"done"] = @YES;
                finished = NO;
            }
        }
        [self appendImageToAdaptor:adaptor atTime:currTime];
        currTime += interval;
    }
}
-(NSArray*)waitParams:(NSString*)paramstring
{
    NSArray *params = [paramstring componentsSeparatedByString:@","];
    if ([params count] < 1)
    {
        self.errMsg = @"No parameters for wait";
        return nil;
    }
    float x = [params[0]floatValue];
    return @[@(x)];
}

-(id)wait:(NSString*)paramstring
{
    float x = [[self waitParams:paramstring][0]floatValue];
	if (x > 0.0)
		[self waitForSecs:x];
    return @YES;
}

-(NSArray*)positionParams:(NSString*)paramstring
{
    NSArray *params = [paramstring componentsSeparatedByString:@","];
    if ([params count] == 0)
    {
        self.errMsg = @"No parameters for position";
        return nil;
    }
    NSString *nm = params[0];
    ACSDGraphic *g = [self graphicWithName:nm];
    if (g == nil)
    {
        self.errMsg = [NSString stringWithFormat:@"Graphic %@ not found",nm];
        return nil;
    }
    if ([params count] < 3)
    {
        self.errMsg = @"Position: Check x,y";
        return nil;
    }
    float x = [params[1]floatValue];
    float y = [params[2]floatValue];
    ACSDGraphic *rg = nil;
    if ([params count] >=4)
    {
        NSString *rname = params[3];
        rg = [self graphicWithName:rname];
    }
    NSRect r;
    if (rg)
        r = [rg bounds];
    else
        r = self.pageBounds;
    NSPoint loc = LocationForRect(x, y, r);
    return @[nm,[NSValue valueWithPoint:loc]];
}

-(id)position:(NSString*)paramstring
{
    NSArray *arr = [self positionParams:paramstring];
    NSString *nm = arr[0];
    ACSDGraphic *g = [self graphicWithName:nm];
    NSPoint loc = [arr[1] pointValue];
    DoBlockOnMain(^{
        [g setPosition:loc];
	});
    return @YES;
}

-(id)layer:(NSString*)paramstring
{
    NSArray *params = [paramstring componentsSeparatedByString:@","];
    if ([params count] == 0)
    {
        self.errMsg = @"No parameters for layer";
        return nil;
    }
    NSString *nm = params[0];
    ACSDLayer *l = [self layerWithName:nm];
    if (l == nil)
    {
        self.errMsg = [NSString stringWithFormat:@"Layer %@ not found",nm];
        return nil;
    }
    if ([params count] < 2)
    {
        self.errMsg = @"layer(name,show|hide)";
        return nil;
    }
    BOOL show;
    if ([params[1]isEqualToString:@"show"])
        show = YES;
    else if ([params[1]isEqualToString:@"hide"])
        show = NO;
    else
    {
        self.errMsg = @"layer(name,show|hide)";
        return nil;
    }
    DoBlockOnMain(^{
        [l setVisible:show];
	});
    return @YES;
}

-(id)opacity:(NSString*)paramstring
{
    NSArray *params = [paramstring componentsSeparatedByString:@","];
    if ([params count] == 0)
    {
        self.errMsg = @"No parameters for opacity";
        return nil;
    }
    NSString *nm = params[0];
    ACSDGraphic *g = [self graphicWithName:nm];
    if (g == nil)
    {
        self.errMsg = [NSString stringWithFormat:@"Graphic %@ not found",nm];
        return nil;
    }
    if ([params count] < 2)
    {
        self.errMsg = @"opacity(obj,opacity)";
        return nil;
    }
    float opacity = [params[1]floatValue];
    DoBlockOnMain(^{
        [g setGraphicAlpha:opacity notify:YES];
	});
    return @YES;
}

-(NSDictionary*)moveParams:(NSString*)paramstring
{
    NSArray *params = [paramstring componentsSeparatedByString:@","];
    if ([params count] == 0)
    {
        self.errMsg = @"No parameters for move";
        return nil;
    }
    if ([params count] < 3)
    {
        self.errMsg = @"move: Check x,y";
        return nil;
    }
    float x = [params[1]floatValue];
    float y = [params[2]floatValue];
	NSTimeInterval duration = 1.0;
	if ([params count] >= 4)
	{
		duration = [params[4]floatValue];
	}
    return @{@"name":params[0],
             @"x":@(x),
             @"y":@(y),
             @"rname":params[3],
             @"duration":@(duration)};
}

-(NSDictionary*)growPathParams:(NSString*)paramstring
{
    NSArray *params = [paramstring componentsSeparatedByString:@","];
    if ([params count] == 0)
    {
        self.errMsg = @"No parameters for growPath";
        return nil;
    }
    if ([params count] < 2)
    {
        self.errMsg = @"growPath obj,duration";
        return nil;
    }
    NSTimeInterval duration = [params[1]floatValue];
    return @{@"name":params[0],
             @"duration":@(duration)
			 };
}

-(id)growpath:(NSString*)paramstring
{
    NSDictionary *params = [self growPathParams:paramstring];
    NSString *nm = params[@"name"];
    ACSDPath *g = (ACSDPath*)[self graphicWithName:params[@"name"]];
    if (g == nil)
    {
        self.errMsg = [NSString stringWithFormat:@"Graphic %@ not found",nm];
        return nil;
	}
	[self animPathGrow:g duration:[params[@"duration"] floatValue]];
    return @YES;
}

-(id)move:(NSString*)paramstring
{
    NSDictionary *params = [self moveParams:paramstring];
    NSString *nm = params[@"name"];
    ACSDGraphic *g = [self graphicWithName:params[@"name"]];
    if (g == nil)
    {
        self.errMsg = [NSString stringWithFormat:@"Graphic %@ not found",nm];
        return nil;
    }
    ACSDGraphic *rg = nil;
    if ([params count] >=4)
    {
        NSString *rname = params[@"rname"];
        rg = [self graphicWithName:rname];
    }
    NSRect r;
    if (rg)
        r = [rg bounds];
    else
        r = self.pageBounds;
    float x = [params[@"x"]floatValue];
    float y = [params[@"y"]floatValue];
    NSPoint loc = LocationForRect(x, y, r);
    [self animGraphicMove:g from:[g centrePoint] to:loc duration:[params[@"duration"] floatValue]];
    return @YES;
}

-(NSSpeechSynthesizer*)speechSynthesizer
{
    if (_speechSynthesizer == nil)
	{
        _speechSynthesizer = [[NSSpeechSynthesizer alloc]initWithVoice:nil];
		_speechSynthesizer.delegate = self;
	}
    return _speechSynthesizer;
}

#define SPEECH_NOT_FINISHED 1
#define SPEECH_FINISHED 2

-(id)say:(NSString*)paramstring
{
    [self.speechLock lock];
    [self.speechLock unlock];
    self.speechLock = [[NSConditionLock alloc]initWithCondition:SPEECH_NOT_FINISHED];
    DoBlockOnMain(^{
		[[self speechSynthesizer]startSpeakingString:paramstring];
	});
    return @YES;
}

-(id)waitspeech:(NSString*)paramstring
{
    [self.speechLock lockWhenCondition:SPEECH_FINISHED];
    [self.speechLock unlock];
    return @YES;
}

#pragma mark -
#pragma mark recording

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)success
{
    [self.speechLock lockWhenCondition:SPEECH_NOT_FINISHED];
    [self.speechLock unlockWithCondition:SPEECH_FINISHED];
}

-(NSURL*)writeSpeech:(NSString*)speech toFileName:(NSString*)filename
{
    [self.speechLock lock];
    [self.speechLock unlock];
    self.speechLock = [[NSConditionLock alloc]initWithCondition:SPEECH_NOT_FINISHED];
    NSURL *url = [NSURL fileURLWithPath:filename];
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL success = [[self speechSynthesizer] startSpeakingString:speech toURL:url];
        if (success == NO)
        {
            NSLog(@"write speech %d url:%@",success,url);
            [self speechSynthesizer:self.speechSynthesizer didFinishSpeaking:NO];
        }
    });
    [self.speechLock lockWhenCondition:SPEECH_FINISHED];
    [self.speechLock unlock];
    self.speechLock = nil;
    return url;
}

static NSTimeInterval durationOfAudioFile(NSString *path)
{
    AVAsset *ass = [AVAsset assetWithURL:[NSURL fileURLWithPath:path]];
    CMTime cmt = ass.duration;
    return cmt.value/cmt.timescale;
}

static void WriteImageToPixelBuffer(CGImageRef image,CVPixelBufferRef pxbuffer,int width,int height)
{
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, width,
                                                 height, 8, 4*width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    //CGContextConcatCTM(context, frameTransform);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);

}


-(void)appendImageToAdaptor:(AVAssetWriterInputPixelBufferAdaptor*)adaptor atTime:(NSTimeInterval)time
{
    NSLog(@"Append image %g",time);
    NSSize sz = [[self inspectingGraphicView]bounds].size;
    CVPixelBufferRef buffer = NULL;
    CVPixelBufferPoolCreatePixelBuffer (NULL, adaptor.pixelBufferPool, &buffer);
    if (buffer == NULL)
    {
        NSLog(@"Couldn't get buffer at %g",time);
        return;
    }
    NSImage *im = [[self inspectingGraphicView]imageFromCurrentPageOfSize:sz];
    WriteImageToPixelBuffer([im CGImageForProposedRect:NULL context:nil hints:nil], buffer, sz.width, sz.height);
    [adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(time*1000, 1000)];
	CVPixelBufferRelease(buffer);
}

static BOOL VisualCommand(NSString* str)
{
    NSArray *vis = @[@"position",@"layer",@"opacity"];
    return [vis indexOfObject:str]!= NSNotFound;
}

-(NSURL*)writeImagesToVideoURL
{
    NSSize sz = self.pageBounds.size;
    NSURL *url = [NSURL fileURLWithPath:[[self.tempDirectory stringByAppendingPathComponent:@"tempvid"]stringByAppendingPathExtension:@"mov"]];
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:url fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   @(sz.width), AVVideoWidthKey,
                                   @(sz.height), AVVideoHeightKey,
                                   nil];
    AVAssetWriterInput* writerInput = [AVAssetWriterInput
                                        assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    NSDictionary *bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:bufferAttributes];

    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    [videoWriter addInput:writerInput];
    
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    for (AnimationEntry *ae in _animationList)
    {
        BOOL needsSnap = NO;
        NSArray *commands = [ae.text componentsSeparatedByString:@"\n"];
        NSMutableArray *moves = [NSMutableArray arrayWithCapacity:10];
        for (NSString *str in commands)
        {
            NSArray *decomp = decomposed(str);
            if (VisualCommand(decomp[0]))
            {
                [self interpretCommand:str];
                needsSnap = YES;
            }
            else if ([decomp[0]isEqualToString:@"move"])
            {
                NSMutableDictionary *moveDict = [[self moveParams:decomp[1]]mutableCopy];
                NSRect r;
                if (moveDict[@"rname"] == nil)
                    r = self.pageBounds;
                else
                {
                    ACSDGraphic *rg = [self graphicWithName:moveDict[@"rname"]];
                    if (rg)
                        r = [rg bounds];
                    else
                        r = self.pageBounds;
                }
                float x = [moveDict[@"x"]floatValue];
                float y = [moveDict[@"y"]floatValue];
                NSPoint loc = LocationForRect(x, y, r);
                ACSDGraphic *g = [self graphicWithName:moveDict[@"name"]];
                moveDict[@"from"] = [NSValue valueWithPoint:[g centrePoint]];
                moveDict[@"to"] = [NSValue valueWithPoint:loc];
                [moves addObject:moveDict];
            }
        }
        if (needsSnap)
            [self appendImageToAdaptor:adaptor atTime:[ae.settings[@"starttime"]floatValue]];
        if ([moves count] > 0)
            [self snapAnimMoves:moves startTime:[ae.settings[@"starttime"]floatValue] adaptor:adaptor];
    }
    [writerInput markAsFinished];
    [videoWriter finishWritingWithCompletionHandler:^{
        [self.speechLock lockWhenCondition:SPEECH_NOT_FINISHED];
        [self.speechLock unlockWithCondition:SPEECH_FINISHED];
    }];
    return url;
}

-(void)writeAudioToTempDirectory:(NSString*)dir
{
    int i = 0;
    for (AnimationEntry *ae in _animationList)
    {
        NSArray *commands = [ae.text componentsSeparatedByString:@"\n"];
        for (NSString *str in commands)
        {
            NSArray *decomp = decomposed(str);
            if ([decomp[0]isEqualToString:@"say"])
            {
                NSString *speech = decomp[1];
                NSString *filename =[dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.aiff",i]];
                [self writeSpeech:speech toFileName:filename];
                [ae.settings setObject:filename forKey:@"filename"];
                NSTimeInterval dur = durationOfAudioFile(filename);
                [ae.settings setObject:@(dur) forKey:@"duration"];
                i++;
            }
        }
        
    }
}

-(void)determineStartTimes
{
    NSTimeInterval currTime = 0.0;
    NSTimeInterval speechExtendsTo = 0.0;
    for (AnimationEntry *ae in _animationList)
    {
        float maxdur = 0.0;
        [ae.settings setObject:@(currTime) forKey:@"starttime"];
        NSArray *commands = [ae.text componentsSeparatedByString:@"\n"];
        for (NSString *str in commands)
        {
            NSArray *decomp = decomposed(str);
            if ([decomp[0]isEqualToString:@"say"])
                speechExtendsTo = currTime + [ae.settings[@"duration"]floatValue];
            else if ([decomp[0]isEqualToString:@"waitspeech"])
                currTime = speechExtendsTo;
            else if ([decomp[0]isEqualToString:@"wait"])
            {
                float tm = [[self waitParams:decomp[1]][0]floatValue];
                if (tm > maxdur)
                    maxdur = tm;
            }
            else if ([decomp[0]isEqualToString:@"move"])
            {
                float tm = [[self moveParams:decomp[1]][@"duration"]floatValue];
                if (tm > maxdur)
                    maxdur = tm;
            }
        }
        currTime += maxdur;
    }
}

-(void)writeMovieToURL:(NSURL*)url videoURL:(NSURL*)videoURL
{
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    AVMutableCompositionTrack *videoCompositionTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoURL options:@{ AVURLAssetPreferPreciseDurationAndTimingKey : @YES }];
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,videoAssetTrack.timeRange.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil];
    AVMutableCompositionTrack *audioCompositionTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    for (AnimationEntry *ae in _animationList)
    {
        NSString *filename = ae.settings[@"filename"];
        if (filename)
        {
            NSTimeInterval starttime = [ae.settings[@"starttime"]floatValue];
            //NSTimeInterval dur = [ae.settings[@"duration"]floatValue];
            AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:filename] options:@{ AVURLAssetPreferPreciseDurationAndTimingKey : @YES }];
            [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,videoAssetTrack.timeRange.duration) ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:CMTimeMake(starttime * 1000, 1000) error:nil];
        }
    }
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mutableComposition presetName:AVAssetExportPresetPassthrough];
    exporter.outputURL = url;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    //exporter.videoComposition = mutableComposition;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        [self.speechLock lockWhenCondition:SPEECH_NOT_FINISHED];
        [self.speechLock unlockWithCondition:SPEECH_FINISHED];
    }];
}

-(void)recordAnimationsToURL:(NSURL*)url
{
    if (self.status != AC_STATUS_IDLE)
        return;
    self.status = AC_STATUS_RECORDING;
    self.currentPage = [[self inspectingGraphicView]currentPage];
    if (self.currentPage == nil)
        return;
    self.pageBounds = [[self inspectingGraphicView] bounds];
    NSString *audDir = [self.tempDirectory stringByAppendingPathComponent:@"tempaud"];
    [[NSFileManager defaultManager]removeItemAtPath:audDir error:nil];
    NSError *err = nil;
    [[NSFileManager defaultManager]createDirectoryAtPath:audDir withIntermediateDirectories:NO attributes:nil error:&err];
    if (err)
        NSLog(@"%@",[err localizedDescription]);
    [self.speechLock lock];
    [self.speechLock unlock];
    //self.speechLock = [[NSConditionLock alloc]initWithCondition:SPEECH_NOT_FINISHED];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self writeAudioToTempDirectory:audDir];
        [self determineStartTimes];
        [self.speechLock lock];
        [self.speechLock unlock];
        self.speechLock = [[NSConditionLock alloc]initWithCondition:SPEECH_NOT_FINISHED];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self writeImagesToVideoURL];
        });
        [self.speechLock lockWhenCondition:SPEECH_FINISHED];
        [self.speechLock unlock];
        self.speechLock = [[NSConditionLock alloc]initWithCondition:SPEECH_NOT_FINISHED];
        [self writeMovieToURL:url videoURL:[NSURL fileURLWithPath:[[self.tempDirectory stringByAppendingPathComponent:@"tempvid"]stringByAppendingPathExtension:@"mov"]]];
        [self.speechLock lockWhenCondition:SPEECH_FINISHED];
        [self.speechLock unlock];
        self.speechLock = nil;
        self.status = AC_STATUS_IDLE;
	});
}


#pragma mark -

-(void)g:(ACSDPath*)g setAng0:(float)ang0 ang1:(float)ang1
{
	ang1 += ang0;
	[g invalidateGraphicSizeChanged:NO shapeChanged:NO redraw:NO notify:NO];
	ACSDSubPath *sp = [(ACSDPath*)g subPaths][0];
	ACSDPathElement *el0 = [sp pathElements][0];
	ACSDPathElement *el1 = [sp pathElements][1];
	ACSDPathElement *el2 = [sp pathElements][2];
	NSPoint pt0 = [el0 point];
	NSPoint pt1 = [el1 point];
	NSPoint pt2 = [el2 point];
	float upperarmlen = pointDistance(pt0, pt1);
	float forearmlen = pointDistance(pt1, pt2);
	float rang0 = RADIANS(ang0);
	NSPoint elbowpoint = offset_point(pt0, NSMakePoint(cosf(rang0)*upperarmlen, sinf(rang0)*upperarmlen));
	float rang1 = RADIANS(ang1);
	NSPoint wristpoint = offset_point(elbowpoint, NSMakePoint(cosf(rang1)*forearmlen, sinf(rang1)*forearmlen));
	//[sp setPathElements:@[pt0,elbowpoint,wristpoint]];
	[el1 setPoint:elbowpoint];
	[el2 setPoint:wristpoint];
	[g generatePath];
	[g completeRebuild];
	[g invalidateGraphicSizeChanged:YES	shapeChanged:YES redraw:YES notify:NO];
}
-(void)animArm:(ACSDPath*)g startang0:(float)stang0 enang0:(float)enang0 startang1:(float)stang1 enang1:(float)enang1 duration:(NSTimeInterval)secs
{
	if (secs == 0)
	{
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self g:g setAng0:enang0 ang1:enang1];
		});
		return;
	}
	NSTimeInterval starttime = [NSDate timeIntervalSinceReferenceDate];
	float duration = secs;
	float frac = 0;
	while (frac <= 1.0)
	{
		NSTimeInterval currtime = [NSDate timeIntervalSinceReferenceDate];
		frac = (currtime - starttime) / duration;
		float t = clamp01(frac);
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self g:g setAng0:interpolateVal(stang0, enang0, t) ang1:interpolateVal(stang1, enang1, t)];
		});
		[self waitForSecs:0.02];
	}
}

-(id)arm:(NSString*)paramstring
{
	NSArray *params = [paramstring componentsSeparatedByString:@","];
	if ([params count] < 3)
		return nil;
	float ang0 = [params[0]floatValue] - 90;
	float ang1 = [params[1]floatValue];
	float dur = [params[2]floatValue];
	ACSDGraphic *g = [self graphicWithName:@"arm"];
	if (g == nil || ! [g respondsToSelector:@selector(subPaths)])
	{
		self.errMsg = @"arm not found";
		return nil;
	}
	[self animArm:(ACSDPath*)g startang0:-90 enang0:ang0 startang1:0 enang1:ang1 duration:dur];
	return @YES;
}

@end
