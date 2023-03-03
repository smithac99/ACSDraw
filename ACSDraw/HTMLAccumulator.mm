//
//  HTMLAccumulator.m
//  ACSDraw
//
//  Created by alan on 13/07/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "HTMLAccumulator.h"
#import <WebKit/WebKit.h>

HTMLAccumulator *_sharedHTMLAccumulator = nil;

#define NOT_PROCESSING 1
#define PROCESSING 2

@implementation HTMLAccumulator

@synthesize name;

+(id)sharedHTMLAccumulator
{
	if (!_sharedHTMLAccumulator)
		_sharedHTMLAccumulator = [[HTMLAccumulator alloc]init];
	return _sharedHTMLAccumulator;
}

-(id)init
{
	if (self = [super init])
	{
		htmlDict = [[NSMutableDictionary alloc]initWithCapacity:20];
		queue = [[NSMutableArray alloc]initWithCapacity:10];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemLoaded:) 
													 name:WebViewProgressFinishedNotification object:nil];
		webView = [[WebView alloc]initWithFrame:NSMakeRect(0, 0, 100, 100) frameName:nil groupName:nil];
		cLock = [[NSLock alloc]init];
	}
	return self;
}

-(void)awakeFromNib
{
	_sharedHTMLAccumulator = self;
}

-(BOOL)lookUpItem:(NSString*)nm
{
//	[cLock lock];
	self.name = nm;
	NSString *targetPage = [@"http://en.wikipedia.org/wiki/" stringByAppendingString:
						 [[name stringByReplacingOccurrencesOfString:@" " withString:@"_"]
						  stringByReplacingOccurrencesOfString:@"\n" withString:@"_"]
						 ];
	NSURL *url = [NSURL URLWithString:[targetPage stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPathAllowedCharacterSet]];
	if (!url)
		return NO;
	NSURLRequest *req = [NSURLRequest requestWithURL:url];
	if (!req)
		return NO;
	[[webView mainFrame] loadRequest:req];
	return YES;
}

-(BOOL)lookUpNext
{
	if (queueIndex < [queue count])
	{
		[self lookUpItem:[queue objectAtIndex:queueIndex]];
		queueIndex++;
	}
	return YES;
}

-(DOMNode*)exhaustiveSearch:(DOMNode*)node searchString:(NSString*)searchString
{
	if ([node isKindOfClass:[DOMHTMLTableElement class]])
		if ([[node className]isEqual:@"infobox geography vcard"])
			return node;
	DOMNodeList *children = [node childNodes];
	int ct = [children length];
	for (int i = 0;i < ct;i++)
	{
		DOMNode *chn = [children item:i];
		DOMNode *rn = [self exhaustiveSearch:chn searchString:searchString];
		if (rn)
			return rn;
	}
	return nil;
}

-(NSString*)processNode:(DOMNode*)elem
{
	DOMCSSStyleDeclaration *style = (DOMCSSStyleDeclaration*)[(DOMHTMLElement*)elem style];
	[style setProperty:@"float" value:@"left" priority:nil];
	NSString *text = [(DOMHTMLElement*)elem outerHTML];
	return text;
}


- (BOOL)processLoadedPageSearchString:(NSString*)searchString
{
	DOMHTMLCollection *nodes = [[webView windowScriptObject]evaluateWebScript:
								[NSString stringWithFormat:@"document.getElementsByClassName('%@')",searchString]
								];
	id b = [WebUndefined undefined];
	if (nodes == nil || [nodes length] == 0 || nodes == b)
		return NO;
	DOMNode *elem = [nodes item:0];
	NSString *text = nil;
	if ([elem isKindOfClass:[DOMHTMLTableElement class]])
		text = [self processNode:elem];
	if (text)
	{
		DOMHTMLDocument *htmlDoc = [[webView windowScriptObject]valueForKey:@"document"];
		DOMHTMLElement *body = [htmlDoc body];
		[body setInnerHTML:text];
		DOMElement *el = [htmlDoc getElementById:@"coordinates"];
		if (el)
			[[el style]setProperty:@"visibility" value:@"hidden" priority:nil];
		[htmlDict setObject:[NSArray arrayWithObjects:[NSDate date],[body outerHTML],nil] forKey:name];
		return YES;
	}		
	return NO;	
}

- (void)itemLoaded:(NSNotification *)notification
{
	if (!HTMLSearchStrings)
	{
		HTMLSearchStrings = [NSArray arrayWithObjects:@"infobox geography vcard",@"infobox geography",@"infobox vcard",@"infobox",nil];
		if (!HTMLSearchStrings)
			return;
	}
	BOOL success = NO;
	unsigned strind = 0;
	while (!success && strind < [HTMLSearchStrings count])
		success = [self processLoadedPageSearchString:[HTMLSearchStrings objectAtIndex:strind++]];
	if (success)
		NSLog(@"Wrote %@",name);
	else
		NSLog(@"Failed lookup for %@",name);
	[self lookUpNext];
//	[cLock unlock];
}

-(void)exportSavedHTML:(NSString*)nm
{
	[cLock lock];
    NSData *data  = [NSKeyedArchiver archivedDataWithRootObject:htmlDict requiringSecureCoding:NO error:NULL];
	[data writeToFile:[NSString stringWithFormat:@"%@.htmlexport",nm] atomically:NO];
	[cLock unlock];
}

-(void)addToQueue:(NSString*)nm
{
	[queue addObject:nm];
}

-(void)startQueue
{
	if ([queue count] == 0)
		return;
	queueIndex = 0;
	[self lookUpNext];
}

@end
