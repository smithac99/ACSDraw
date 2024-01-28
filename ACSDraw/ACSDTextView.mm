//
//  ACSDTextView.mm
//  ACSDraw
//
//  Created by alan on 05/02/07.
//  Copyright 2007 Alan C Smith. All rights reserved.
//

#import "ACSDPage.h"
#import "ACSDStyle.h"
#import "ACSDLink.h"
#import "ACSDTextView.h"
#import "ACSDText.h"
#import "ArchiveTextDelegate.h"
#import "GraphicView.h"
#import "HighLightLayer.h"
#import "StyleWindowController.h"
#import "TextSubstitution.h"
#import "geometry.h"

NSSet* stylesUsedByAttributedString(NSAttributedString* as);

NSSet* stylesUsedByAttributedString(NSAttributedString* as)
   {
	NSMutableSet *set = [NSMutableSet setWithCapacity:10];
	NSRange longestRange,allRange;
	allRange.location = 0;
	allRange.length = [as length];
	NSUInteger index = 0;
	while (index < allRange.length)
	   {
		ACSDStyle *st = [as attribute:StyleAttribute atIndex:index longestEffectiveRange:&longestRange inRange:allRange];
		if (st)
			[set addObject:st];
		index = longestRange.location + longestRange.length;
	   }
	return set;
   }

@implementation ACSDTextView

- (void)mouseDown:(NSEvent *)theEvent 
   {
	GraphicView *gView = (GraphicView*)[self superview];
	if ([gView cursorMode] == GV_MODE_DOING_LINK)
	   {
		[gView setLinkFromObjects:[[gView document]linkGraphics] toObject:[[gView highLightLayer] targetObject]modifiers:[theEvent modifierFlags]];
		[gView cancelOperation:nil];
		return;
	   }
	else
		[super mouseDown:theEvent];
   }

- (IBAction)clear:(id)sender
   {
	[self deleteBackward:sender];
   }

- (IBAction)copy:(id)sender
{
    NSArray *selectedRanges = [self selectedRanges];
    NSUInteger count;
    if ((count = [selectedRanges count]) == 0)
        return;
    if (count == 1)
    {
        NSRange r = [[selectedRanges objectAtIndex:0]rangeValue];
        if (r.length == 0)
            return;
    }
    [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObjects:NSPasteboardTypeRTFD,NSPasteboardTypeString,ACSDrawTextPBoardType,nil] owner:self];
    NSMutableAttributedString *mas = [[NSMutableAttributedString alloc]init];
    for (int i = 0;i < count;i++)
        [mas appendAttributedString:[[self textStorage] attributedSubstringFromRange:[[selectedRanges objectAtIndex:i]rangeValue]]];
    NSData *data = [mas RTFDFromRange:NSMakeRange(0,[mas length]) documentAttributes:[NSDictionary dictionary]];
    [[NSPasteboard generalPasteboard] setData:data forType:NSPasteboardTypeRTFD];
    NSString *str = [mas string];
    [[NSPasteboard generalPasteboard] setString:str forType:NSPasteboardTypeString];

    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:mas,@"text",stylesUsedByAttributedString(mas),@"styles",nil];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initRequiringSecureCoding:NO];
    [archiver setDelegate:[ArchiveTextDelegate archiveTextDelegateWithType:ARCHIVE_PASTEBOARD styleMatching:0 styles:0 document:[(ACSDText*)[self delegate]document]enclosingGraphic:(ACSDText*)[self delegate]]];
    [archiver encodeObject:dict forKey:@"root"];
    [archiver encodeObject:[[(ACSDText*)[self delegate]document]documentKey] forKey:@"docKey"];
    [archiver finishEncoding];
    [[NSPasteboard generalPasteboard] setData:archiver.encodedData forType:ACSDrawTextPBoardType];
}

-(void)fixAnchorsInAttributedString:(NSMutableAttributedString*)mas
   {
	ACSDText *graphic = (ACSDText*)[self delegate];
	NSRange charRange = NSMakeRange(0,[mas length]);
	NSMutableDictionary *anchorMappings = [NSMutableDictionary dictionaryWithCapacity:5];
	NSUInteger index = charRange.location;
	while (index < charRange.location + charRange.length)
	   {
		NSRange resultRange;
		if (id anc = [mas attribute:ACSDAnchorAttributeName atIndex:index effectiveRange:&resultRange])
		   {
			if (anc)
			   {
				int newN = [graphic nextAnchorID];
				id newAnc = [NSNumber numberWithInt:newN];
				[anchorMappings setObject:newAnc forKey:anc];
				[mas addAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:newN] forKey:ACSDAnchorAttributeName] range:resultRange];
			   }
		   }
		index = resultRange.location + resultRange.length;
	   }
	index = charRange.location;
	while (index < charRange.location + charRange.length)
	   {
		NSRange resultRange;
		if (id lnk = [mas attribute:NSLinkAttributeName atIndex:index effectiveRange:&resultRange])
		   {
			if (lnk && [lnk isKindOfClass:[ACSDLink class]] && ([lnk toObject] == graphic))
			   {
				if (id newAnc = [anchorMappings objectForKey:[NSNumber numberWithInt:[lnk anchorID]]])
					[lnk setAnchorID:[newAnc intValue]];
			   }
		   }
		index = resultRange.location + resultRange.length;
	   }
   }

- (IBAction)paste:(id)sender
{
    NSArray *pasteTypes = @[ACSDrawTextPBoardType,NSPasteboardTypeRTFD,NSPasteboardTypeRTF,NSPasteboardTypeString];
    NSString *bestType = [[NSPasteboard generalPasteboard] availableTypeFromArray:pasteTypes];
    if (bestType == nil)
        return;
    if ([bestType isEqualToString:ACSDrawTextPBoardType])
    {
        NSData *data = [[NSPasteboard generalPasteboard] dataForType:ACSDrawTextPBoardType];
        NSDictionary *dict;
        //NSKeyedUnarchiver *unarch = [[NSKeyedUnarchiver alloc]initForReadingFromData:data error:NULL];
        NSKeyedUnarchiver *unarch = [[NSKeyedUnarchiver alloc]initForReadingWithData:data];
        id docKey = [unarch decodeObjectForKey:@"docKey"];
        int styleMatching;
        id styleCollection;
        NSLog(@"before stylesByKey");
        if ([docKey isEqual:[[(ACSDText*)[self delegate]document]documentKey]])
        {
            styleMatching = MATCH_KEYS;
            styleCollection = [ACSDStyle stylesByKey:[[(ACSDText*)[self delegate]document]styles]];
        }
        else
        {
            styleMatching = MATCH_SIMILAR;
            styleCollection = [ACSDStyle stylesByName:[[(ACSDText*)[self delegate]document]styles]];
        }
        [unarch setDelegate:[ArchiveTextDelegate archiveTextDelegateWithType:ARCHIVE_PASTEBOARD styleMatching:styleMatching
                                                                      styles:styleCollection document:[(ACSDText*)[self delegate]document]enclosingGraphic:(ACSDText*)[self delegate]]];
        NSLog(@"Before Decode");
        id a = [unarch decodeObjectForKey:@"root"];
        if ([a isKindOfClass:[NSDictionary class]])
            dict = a;
        else
            return;
        id mas = [dict objectForKey:@"text"];
        [self fixAnchorsInAttributedString:mas];
        [[self textStorage] beginEditing];
        NSLog(@"Before ReplaceChars");
        [[self textStorage] replaceCharactersInRange:[[[self selectedRanges] objectAtIndex:0]rangeValue]withAttributedString:mas];
        NSLog(@"After ReplaceChars");
        [[self textStorage] endEditing];
    }
    else
        [super paste:sender];
}

- (IBAction)createStyleFromText:(id)sender
   {
	ACSDStyle *st = [ACSDStyle styleFromTypingAttributes:[self typingAttributes]];
	[(ACSDrawDocument*)[(ACSDText*)[self delegate]document]registerObject:st];
	[st setName:@"new style"];
	StyleWindowController *wc = [StyleWindowController sharedStyleWindowController];
	[wc showWindow:self];
	[wc uInsertStyle:st];
	[[self undoManager] setActionName:@"Create Style"];
   }

- (IBAction)updateStyleFromText:(id)sender
   {
	NSMutableDictionary *attr = [ACSDStyle attributesFromTypingAttributes:[self typingAttributes]];
	StyleWindowController *wc = [StyleWindowController sharedStyleWindowController];
	[wc showWindow:self];
	[wc uUpdateStyleWithAttributes:attr];
	[[self undoManager] setActionName:@"Update Style"];
   }

- (IBAction)insertCurrentPageNo:(id)sender
   {
	ACSDText *g = (ACSDText*)[self delegate];
	NSInteger pageNo = [[[g layer] page]pageNo];
	NSRange r = [self rangeForUserTextChange];
	[self insertText:[NSString stringWithFormat:@"%ld",pageNo]];
	NSRange r2 = [self rangeForUserTextChange];
	r.length = r2.location - r.location;
	[[self textStorage]addAttribute:TextSubstitutionAttribute value:[TextSubstitution textSubstitutionWithType:TEXT_SUBSTITUTION_CURRENT_PAGE]range:r];
	[(ACSDText*)[self delegate] setMayContainSubstitutions:YES];
   }

- (void)removeLinkForRange:(NSRange)charRange
   {
	NSRange maxRange = [(ACSDText*)[self delegate]characterRange];
	NSUInteger index = charRange.location;
	do
	   {
		NSRange resultRange;
		if (id l = [[self textStorage] attribute:NSLinkAttributeName atIndex:index longestEffectiveRange:&resultRange inRange:maxRange])
		   {
			if (l)
			   {
				[l removeFromLinkedObjects];
				[[self textStorage] removeAttribute:NSLinkAttributeName range:resultRange];
			   }
		   }
		index = resultRange.location + resultRange.length;
	   }while (index < charRange.location + charRange.length);
   }

- (IBAction)removeTextLink:(id)sender
{
    NSArray *arr = [self selectedRanges];
    for (unsigned i = 0; i < [arr count];i++)
        [self removeLinkForRange:[[arr objectAtIndex:i]rangeValue]];
}

-(void)uReplaceRange:(NSRange)r withAttributedString:(NSAttributedString*)astr
{
    [[[self undoManager] prepareWithInvocationTarget:self]uReplaceRange:NSMakeRange(r.location, [astr length])withAttributedString:[[self textStorage]attributedSubstringFromRange:r]];
    [[self textStorage] beginEditing];
    [[self textStorage]replaceCharactersInRange:r withAttributedString:astr];
    [[self textStorage] endEditing];
}

- (IBAction)graduateTextSize:(id)sender
{
    NSArray *arr = [self selectedRanges];
    if ([arr count] != 1)
        return;
    NSRange r = [arr[0]rangeValue];
    if (r.length < 3)
        return;
    NSMutableAttributedString *as = [[[self textStorage]attributedSubstringFromRange:r]mutableCopy];
    NSFont *f = [as attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
    float startFontSize = [f pointSize];
    f = [as attribute:NSFontAttributeName atIndex:r.length - 1 effectiveRange:NULL];
    float endFontSize = [f pointSize];
    for (NSInteger i = 1;i < r.length - 1;i++)
    {
        NSFont *f = [as attribute:NSFontAttributeName atIndex:i effectiveRange:NULL];
        float sz = startFontSize + (endFontSize - startFontSize) * i / (r.length - 1);
        f = [f fontWithSize:sz];
        [as addAttributes:@{NSFontAttributeName:f} range:NSMakeRange(i, 1)];
    }
    /*[[self textStorage] beginEditing];
    [[self textStorage]replaceCharactersInRange:r withAttributedString:as];
    [[self textStorage] endEditing];*/
    [self uReplaceRange:r withAttributedString:as];
    [[self undoManager]setActionName:@"Text Gradient"];
}

- (IBAction)graduateTextSizeByScale:(id)sender
{
    NSArray *arr = [self selectedRanges];
    if ([arr count] != 1)
        return;
    NSRange r = [arr[0]rangeValue];
    if (r.length < 3)
        return;
    NSMutableAttributedString *as = [[[self textStorage]attributedSubstringFromRange:r]mutableCopy];
    NSFont *f = [as attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
    float startFontSize = [f pointSize];
    f = [as attribute:NSFontAttributeName atIndex:r.length - 1 effectiveRange:NULL];
    float endFontSize = [f pointSize];
    float startlog = log10(startFontSize);
    float endlog = log10(endFontSize);
    for (NSInteger i = 1;i < r.length - 1;i++)
    {
        NSFont *f = [as attribute:NSFontAttributeName atIndex:i effectiveRange:NULL];
        float sz = pow(10,interpolateVal(startlog, endlog, i * 1.0 / (r.length - 1)));
        f = [f fontWithSize:sz];
        [as addAttributes:@{NSFontAttributeName:f} range:NSMakeRange(i, 1)];
    }
    [self uReplaceRange:r withAttributedString:as];
    [[self undoManager]setActionName:@"Text Gradient by Scale"];
}

- (BOOL)validateMenuItem:(id)menuItem
   {
	SEL action = [menuItem action];
	if (action == @selector(graduateTextSize:))
    {
        NSArray *arr = [self selectedRanges];
        if ([arr count] != 1)
            return NO;
        NSRange r = [arr[0]rangeValue];
        return (r.length >= 3);
    }
	return [super validateMenuItem:menuItem];
   }


/*-(NSDictionary*)typingAttributes
{
    NSMutableDictionary *mdict = [[super typingAttributes]mutableCopy];
    NSArray
    return mdict;
}*/
-(NSDictionary*)typingAttributesPlus
{
    NSMutableDictionary *mdict = [[self typingAttributes]mutableCopy];
    return mdict;
}
@end
