//
//  ACSDDocumentController.m
//  ACSDraw
//
//  Created by Alan Smith on 03/03/2023.
//

#import "ACSDDocumentController.h"

@implementation ACSDDocumentController

-(instancetype)init
{
    if (self = [super init])
    {
        
    }
    return self;
}

- (Class)documentClassForType:(NSString *)typeName
{
    return [super documentClassForType:typeName];
}

-(IBAction)openBook:(id)sender
{
    NSOpenPanel *pan = [NSOpenPanel openPanel];
    [pan setCanChooseDirectories:YES];
    NSInteger res = [self runModalOpenPanel:pan forTypes:@[]];
    if (res == NSModalResponseOK)
    {
        for (NSURL *url in [pan URLs])
        {
            NSError *err;
            NSDocument *doc = [self makeDocumentWithContentsOfURL:url ofType:@"acsd" error:&err];
            if (doc)
            {
                [self addDocument:doc];
                [doc makeWindowControllers];
                [doc showWindows];
            }
            else
            {
                if (err)
                {
                    NSAlert *al = [NSAlert alertWithError:err];
                    [al runModal];
                }
            }
        }
    }
}
@end
