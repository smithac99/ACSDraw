//
//  AnimationsController.h
//  ACSDraw
//
//  Created by Alan on 30/06/2014.
//
//

#import "ViewController.h"

@class ACSDPage;

enum
{
	AC_PAGE_CHANGE = 1,
	AC_SELECTION_CHANGE = 2,
};

enum
{
	PROCESS_DONE,
	PROCESS_NOT_DONE
};

#define AC_STATUS_IDLE 0
#define AC_STATUS_PLAYING 1
#define AC_STATUS_RECORDING 2


@interface AnimationsController : ViewController<NSSpeechSynthesizerDelegate>
{
    IBOutlet NSTableView *animationTableView;
    IBOutlet NSTextView *textView;
    NSSpeechSynthesizer *speechSynthesizer;
    NSConditionLock *speechLock;
}

@property (assign) NSMutableArray *animationList;
@property (retain) NSString *errMsg;
@property (retain) NSString *tempDirectory;
@property (assign) ACSDPage *currentPage;
@property NSRect pageBounds;
@property int status;
-(void)recordAnimationsToURL:(NSURL*)url;
-(void)graphicsDidMove:(NSArray*)graphics;

@end

extern AnimationsController *animationsController;
void DoBlockOnMain(void (^block)());

