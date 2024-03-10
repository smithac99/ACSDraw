//
//  ApplyStyleDialogController.h
//  ACSDraw
//
//  Created by Alan Smith on 09/03/2024.
//

#import <Foundation/Foundation.h>
@class MainWindowController;

@interface ApplyStyleDialogController : NSObject<NSTableViewDataSource,NSTableViewDelegate>
{
    __weak IBOutlet MainWindowController *windowController;
}
@property (weak) IBOutlet NSPanel *dialog;
@property (weak) NSArray *styleList;
@property (weak) IBOutlet NSTableView *styleTableView;
@property (weak) IBOutlet NSPopUpButton *regexpScope;
@property (weak) IBOutlet NSTextField *regexpPattern;
@property (weak) IBOutlet NSTextField *message;

-(void)showDialog;

@end

