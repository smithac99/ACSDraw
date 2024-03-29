//
//  ACSDrawDocument+bookAdditions.m
//  ACSDraw
//
//  Created by Alan Smith on 04/03/2023.
//

#import "ACSDrawDocument+bookAdditions.h"
#import "XMLManager.h"
#import "ACSDPage.h"
#import "ACSDLayer.h"
#import "ACSDImage.h"
#import "ACSDText.h"
#import "ACSDPrefsController.h"
#import "AffineTransformAdditions.h"
#import "ACSDDocImage.h"
#import "ACSDLink.h"
#import "NSString+StringAdditions.h"
#import <Vision/Vision.h>
#import "ObjectAdditions.h"
#import "NSMutableArray+additions.h"

NSFont* FontToFitSize(NSFont *fnt, NSString *txt,CGSize sz, BOOL width, BOOL height,BOOL wrapped);
CGRect boundingBoxForString(NSString* str,NSFont* font,CGSize sz);
CGRect boundingBoxForWrappedString(NSString* str,NSFont* font,CGSize sz);

CGRect boundingBoxForString(NSString* str,NSFont* font,CGSize sz)
{
    NSDictionary *attrs = @{NSFontAttributeName:font};
    CGRect r = [str boundingRectWithSize:sz options:0 attributes:attrs
                                 context:nil];
    return r;
}

CGRect boundingBoxForWrappedString(NSString* str,NSFont* font,CGSize sz)
{
    NSDictionary *attrs = @{NSFontAttributeName:font};
    CGRect r = [str boundingRectWithSize:sz options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs
                                 context:nil];
    return r;
}

static BOOL textFits(NSFont *fnt, NSString *txt,CGSize targetSz, BOOL width, BOOL height,BOOL wrapped)
{
    CGSize insz = targetSz;
    if (wrapped)
        insz.height = CGFLOAT_MAX;
    else
        insz.width = CGFLOAT_MAX;
    CGSize thisSz;
    if (wrapped)
        thisSz = boundingBoxForWrappedString(txt, fnt, insz).size;
    else
        thisSz = boundingBoxForString(txt, fnt, insz).size;
    return !((height && (thisSz.height > targetSz.height)) || (width && (thisSz.width > targetSz.width)));
}

NSFont* FontToFitSize(NSFont *fnt, NSString *txt,CGSize sz, BOOL width, BOOL height,BOOL wrapped)
{
    sz.width -= 10;
    sz.height -= 10;
    if (textFits(fnt,txt,sz, width, height,wrapped))
        return fnt;
    float pointSize = [fnt pointSize];
    float upperBound = pointSize,lowerBound = 1;
    float threshold = fminf(1.0, pointSize / 50.0);
    while (upperBound - lowerBound > threshold)
    {
        float mid = (upperBound + lowerBound) / 2.0;
        fnt = [fnt fontWithSize:mid];
        if (textFits(fnt,txt,sz, width, height,wrapped))
            lowerBound = mid;
        else
            upperBound = mid;
    }
    return [fnt fontWithSize:lowerBound];
}

@implementation ACSDrawDocument (bookAdditions)

-(NSString*)bookLingo
{
    return [[NSUserDefaults standardUserDefaults]objectForKey:prefBooksLanguage];
}

-(NSSize)bookDocSize
{
    float w = [[NSUserDefaults standardUserDefaults]floatForKey:prefBooksDocWidth];
    float h = [[NSUserDefaults standardUserDefaults]floatForKey:prefBooksDocHeight];
    return NSMakeSize(w,h);
}

-(XMLNode*)mergeBookNode1:(XMLNode*)b1 node2:(XMLNode*)b2
{
    if (b1 == nil)
        return b2;
    if (b2 == nil)
        return b1;
    XMLNode *mergedRoot = [[XMLNode alloc]init];
    mergedRoot.nodeName = b1.nodeName;
    NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithDictionary:[b1 attributes]];
    [attrs addEntriesFromDictionary:[b2 attributes]];
    mergedRoot.attributes = attrs;
    NSArray<XMLNode*> *b1Pages = [b1 childrenOfType:@"page"];
    NSArray<XMLNode*> *b2Pages = [b2 childrenOfType:@"page"];
    NSInteger b1Idx = 0,b2Idx = 0;
    while (b1Idx < [b1Pages count] || b2Idx < [b2Pages count])
    {
        XMLNode *mergedPage = [[XMLNode alloc]init];
        mergedPage.nodeName = @"page";
        XMLNode *b1Page = b1Pages[b1Idx];
        XMLNode *b2Page = b2Pages[b2Idx];
        NSString *b1key = b1Page.attributes[@"pageno"];
        NSString *b2key = b2Page.attributes[@"pageno"];
        if ([b1key isEqualToString:b2key])
        {
            NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithDictionary:[b1Page attributes]];
            [attrs addEntriesFromDictionary:[b2Page attributes]];
            mergedPage.attributes = attrs;
            if ([b2Page.children count] > 0)
                mergedPage.children = b2Page.children;
            else
                mergedPage.children = b1Page.children;
            b1Idx++;
            b2Idx++;
        }
        else
        {
            if ([b1key intValue] < [b2key intValue])
            {
                mergedPage.attributes = [b1Page.attributes copy];
                mergedPage.children = [b1Page.children copy];
                b1Idx++;
            }
            else
            {
                mergedPage.attributes = [b2Page.attributes copy];
                mergedPage.children = [b2Page.children copy];
                b2Idx++;
            }
        }
        [mergedRoot.children addObject:mergedPage];
    }
    return mergedRoot;
}

-(NSString*)languageDir:(NSString*)localDir preferred:(NSArray*)prefArray
{
    NSFileManager *fm = [NSFileManager defaultManager];
    for (NSString *lang in prefArray)
    {
        BOOL isDir;
        NSString *path = [localDir stringByAppendingPathComponent:lang];
        BOOL exists = [fm fileExistsAtPath:path isDirectory:&isDir];
        if (exists && isDir)
            return path;
    }
    NSArray *dirs = [fm contentsOfDirectoryAtPath:localDir error:NULL];
    for (NSString *comp in dirs)
    {
        BOOL isDir;
        NSString *path = [localDir stringByAppendingPathComponent:comp];
        BOOL exists = [fm fileExistsAtPath:path isDirectory:&isDir];
        if (exists && isDir)
            return path;
    }
    return nil;
}

-(BOOL)bookError:(NSInteger)code desc:(NSString*)desc path:(NSString*)path error:(NSError * *)outError
{
    NSMutableDictionary *errorDict = [@{NSLocalizedDescriptionKey:desc}mutableCopy];
    if (path)
        errorDict[NSFilePathErrorKey] = path;
    NSError *err = [[NSError alloc]initWithDomain:@"BookError" code:code userInfo:errorDict];
    *outError = err;
    return NO;
}

-(NSString*)imagePathForImgDir:(NSString*)path
{
    NSFileManager *fm = [NSFileManager defaultManager];
    for (NSString *sdir in @[@"shared_3",@"shared_4",@"shared_2"])
    {
        NSString *fullPath = [path stringByAppendingPathComponent:sdir];
        if ([fm fileExistsAtPath:fullPath])
            return fullPath;
    }
    return nil;
}

- (BOOL)readBookFromURL:(NSURL *)url error:(NSError * _Nullable *)outError
{
    NSString *rootPath = [url path];
    NSString *configPath = [rootPath stringByAppendingPathComponent:@"config"];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir;
    BOOL exists = [fm fileExistsAtPath:configPath isDirectory:&isDir];
    if (!(exists && isDir))
    {
        return [self bookError:-1 desc:@"config dir does not exist" path:configPath error:outError];
    }
    NSString *configXMLPath = [configPath stringByAppendingPathComponent:@"book.xml"];
    if (![fm fileExistsAtPath:configXMLPath])
        return [self bookError:-1 desc:@"config xml does not exist" path:configXMLPath error:outError];
    XMLManager *xmlman = [[XMLManager alloc]init];
    XMLNode *configNode = [xmlman parseFile:configXMLPath];
    if (configNode == nil)
    {
        return [self bookError:-1 desc:@"Could not parse config xml" path:configXMLPath error:outError];
    }
    NSString *localPath = [self languageDir:[rootPath stringByAppendingPathComponent:@"local"] preferred:@[[self bookLingo]]];
    if (localPath == nil)
        return [self bookError:-1 desc:@"No local path for config XML" path:localPath error:outError];
    NSString *localXMLPath = [localPath stringByAppendingPathComponent:@"book.xml"];
    if (![fm fileExistsAtPath:localXMLPath])
        return [self bookError:-1 desc:@"No local config XML" path:localXMLPath error:outError];
    XMLNode *localNode = [xmlman parseFile:localXMLPath];
    if (localNode == nil)
        return [self bookError:-1 desc:@"Could not parse local xml" path:localXMLPath error:outError];
    XMLNode *rootNode = [self mergeBookNode1:configNode node2:localNode];
    NSString *imgPath = [self imagePathForImgDir:[rootPath stringByAppendingPathComponent:@"img"]];
    exists = [fm fileExistsAtPath:imgPath isDirectory:&isDir];
    if (!(exists && isDir))
        return [self bookError:-1 desc:@"No img path" path:imgPath error:outError];
    self.documentSize = [self bookDocSize];
    [self createPagesFromNode:rootNode imageDir:imgPath];
    [self setFileType:@"acsd"];
    if ([self fileURL] != nil)
        [self setFileURL:[NSURL fileURLWithPath:[[[self fileURL] path]stringByAppendingPathExtension:@"acsd"]]];
    return YES;
}

-(NSString*)pathForPageNo:(NSString*)pno dir:(NSString*)dir
{
    NSString *imagePath = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"p%@",pno]];
    for (NSString *suff in @[@"jpg",@"png"])
    {
        NSString *fullpath = [imagePath stringByAppendingPathExtension:suff];
        if ([[NSFileManager defaultManager]fileExistsAtPath:fullpath])
            return fullpath;
    }
    return nil;
}

void FitImageToBox(ACSDImage *im,NSRect box)
{
    NSSize boxsz = box.size;
    NSSize imsize = [im bounds].size;
    float wratio = imsize.width / boxsz.width;
    float hratio = imsize.height / boxsz.height;
    float sc;
    if (wratio > hratio)
        sc = 1/wratio;
    else
        sc = 1/hratio;
    [im setGraphicXScale:[im xScale] * sc yScale:[im yScale] * sc undo:NO];
    [im setPosition:NSMakePoint(NSMidX(box), NSMidY(box))];
}

-(float)applyGraphicScale:(float)f
{
    float factor = self.documentSize.height / 768.0;
    return factor * f;
}

-(ACSDDocImage*)loadSVGImage:(NSString*)path intoLayer:(ACSDLayer*)l
{
    NSData *d = [NSData dataWithContentsOfFile:path];
    ACSDrawDocument *adoc = [[ACSDrawDocument alloc]init];
    [adoc setFileURL:[NSURL fileURLWithPath:path]];
    [adoc readFromData:d ofType:@"svg" error:nil];
    NSRect r = NSZeroRect;
    r.size = [adoc documentSize];
    NSString *nm = [[path lastPathComponent]stringByDeletingPathExtension];
    ACSDDocImage *image = [[ACSDDocImage alloc]initWithName:nm fill:nil stroke:nil rect:r layer:l drawDoc:adoc];
    [[l graphics] addObject:image];
    image.sourcePath = path;
    return image;
}

-(void)loadButton:(NSString*)buttonName pos:(NSString*)pos intoLayer:(ACSDLayer*)l
{
    NSString *svgPath = [[NSBundle mainBundle]pathForResource:buttonName ofType:@"svg"];
    ACSDDocImage *im = [self loadSVGImage:svgPath intoLayer:l];
    float sc = [self applyGraphicScale:1];
    [im setGraphicXScale:sc yScale:sc undo:NO];
    float x,y;
    NSSize mySize = self.documentSize;
    NSSize imSize = [im bounds].size;
    y = imSize.height / 2;
    if ([pos hasPrefix:@"t"])
        y = mySize.height - y;
    x = imSize.width / 2;
    if ([pos hasSuffix:@"r"])
        x = mySize.width - x;
    [im setPosition:NSMakePoint(x, y)];
}

-(void)createPagesFromNode:(XMLNode*)rootNode imageDir:(NSString*)imageDir
{
    float fontSize = [self applyGraphicScale:[rootNode attributeFloatValue:@"fontsize"]];
    NSString *templateSuffix = [rootNode attributeStringValue:@"templatesuffix"];
    NSString *textjustify = [rootNode attributeStringValue:@"textjustify"];
    float largeFontSize = -1;
    NSString *str;
    if ((str = [rootNode attributeStringValue:@"largefontsize"]))
        largeFontSize = [self applyGraphicScale:[str floatValue]];
    BOOL paragraphlessMode = [[rootNode attributeStringValue:@"noparas"]isEqualToString:@"true"];
    NSString *indentstr = [rootNode attributeStringValue:@"indent"];
    float lineHeightMultiplier = 1.0;
    if ((str = [rootNode attributeStringValue:@"lineheight"]))
        lineHeightMultiplier = [str floatValue];
    float paraHeightMultiplier = 1.0;
    if ((str = [rootNode attributeStringValue:@"paraheight"]))
        paraHeightMultiplier = [str floatValue];
    float letterSpacing = 0;
    NSString *lsstr = [rootNode attributeStringValue:@"letterspacing"];
    if (lsstr)
        letterSpacing = [self applyGraphicScale:[lsstr floatValue]];
    
    NSString *xmlPath = [[NSBundle mainBundle]pathForResource:@"booktemplate" ofType:@"xml"];
    XMLManager *xmlman = [[XMLManager alloc]init];
    XMLNode *templateroot = [xmlman parseFile:xmlPath];
    BOOL showButtons = [[NSUserDefaults standardUserDefaults]boolForKey:prefBooksShowButtons];

    [[self pages]removeObjectAtIndex:0];
    NSMutableArray *settingsStack = [NSMutableArray arrayWithCapacity:6];
    NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithCapacity:10];
    [settings setObject:[NSMutableDictionary dictionaryWithCapacity:10] forKey:@"defs"];
    settings[@"docheight"] = @(self.documentSize.height);
    NSAffineTransform *t = [NSAffineTransform transformWithTranslateXBy:0 yBy:self.documentSize.height];
    [t scaleXBy:1.0 yBy:-1.0];
    settings[@"transform"] = t;
    settings[@"parentrect"] = [NSValue valueWithRect:NSMakeRect(0, 0, self.documentSize.width, self.documentSize.height)];
    [settingsStack addObject:settings];
    NSMutableDictionary *objectDict = [NSMutableDictionary dictionary];
    BOOL showBoxes = [[NSUserDefaults standardUserDefaults]boolForKey:prefBooksShowBoxes];
    for (XMLNode *pageNode in [rootNode childrenOfType:@"page"])
    {
        NSString *pageNo = [pageNode attributeStringValue:@"pageno"];
        NSString *imagePath = [self pathForPageNo:pageNo dir:imageDir];
        NSImage *im = [[NSImage alloc]initByReferencingFile:imagePath];
        NSString *eventName = [pageNo isEqualToString:@"0"] ? @"title" : @"normal";
        NSString *picJustify = [pageNode attributeStringValue:@"picjustify"];

        
        if (picJustify)
        {
            if ([picJustify isEqualToString:@"left"])
                eventName = @"picleft";
            else if ([picJustify isEqualToString:@"right"])
                eventName = @"picright";
        }
        if ([templateSuffix length] > 0)
            eventName = [NSString stringWithFormat:@"%@_%@",eventName,templateSuffix];
        XMLNode *eventNode = [templateroot childOfType:@"event" identifier:eventName];
        ACSDPage *p = [[ACSDPage alloc]initWithXMLNode:eventNode document:self settingsStack:settingsStack objectDict:objectDict];
        [p setPageTitle:[NSString stringWithFormat:@"p%@",pageNo]];
        [[self pages]addObject:p];
        ACSDLayer *layer = p.layers[1];
        NSRect bounds = NSZeroRect;
        bounds.size = im.size;
        ACSDImage *gim = [[ACSDImage alloc]initWithName:pageNo fill:nil stroke:nil rect:bounds layer:layer image:im];
        [layer addGraphic:gim];
        ACSDGraphic *imageBox = [layer graphicsWithName:@"imagebox"][0];
        FitImageToBox(gim, [imageBox bounds]);
        NSMutableString *ms = [NSMutableString string];
        for (XMLNode *para in [pageNode childrenOfType:@"para"])
        {
            NSString *contents = [para.contents stringByReplacingOccurrencesOfString:@"/" withString:@""];
            if ([ms length] > 0)
            {
                NSString *conj = paragraphlessMode ? @" " : @"\n";
                [ms appendString:conj];
            }
            [ms appendString:contents];
        }
        float pageFontSize = fontSize;
        float pageLetterSpacing = letterSpacing;
        float pageLineHeightMultiplier = lineHeightMultiplier;
        if ([pageNo isEqualToString:@"0"])
        {
            pageFontSize = largeFontSize;
            if (largeFontSize > 0)
                pageFontSize = largeFontSize;
            else
                pageFontSize = [self  applyGraphicScale:[eventNode attributeFloatValue:@"largefontsize"]];
            pageLineHeightMultiplier = [eventNode attributeFloatValue:@"largelineheight"];
            pageLetterSpacing = [self  applyGraphicScale:[eventNode attributeFloatValue:@"largespacing"]];
        }

        NSFont *fnt = [NSFont fontWithName:@"onebillionreader-Regular" size:pageFontSize];
        NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithDictionary:@{NSFontAttributeName:fnt}];
        if (pageLetterSpacing != 0)
            attrs[NSKernAttributeName] = @(pageLetterSpacing);
        NSMutableParagraphStyle *mps = [[NSMutableParagraphStyle defaultParagraphStyle]mutableCopy];
        if ([pageNo isEqualToString:@"0"] || [textjustify isEqualToString:@"centre"])
            mps.alignment = NSTextAlignmentCenter;
        else
        {
            if ([indentstr length] > 0)
            {
                NSAttributedString *is = [[NSAttributedString alloc]initWithString:indentstr attributes:attrs];
                mps.firstLineHeadIndent = [is boundingRectWithSize:CGSizeMake(10000, 10000) options:0 context:nil].size.width;
            }
        }
        float lineHeight = pageFontSize;
        if (pageLineHeightMultiplier != 1.0)
            //mps.lineHeightMultiple = lineHeightMultiplier;
            lineHeight = pageFontSize * pageLineHeightMultiplier;
        mps.maximumLineHeight = lineHeight;
        mps.minimumLineHeight = lineHeight;
        mps.paragraphSpacing = paraHeightMultiplier * lineHeight - lineHeight;
        attrs[NSParagraphStyleAttributeName] = mps;
        NSAttributedString *as = [[NSAttributedString alloc]initWithString:ms attributes:attrs];
        ACSDGraphic *textBox = [layer graphicsWithName:@"textbox"][0];
        NSRect destBounds = [textBox bounds];
        float height = [as boundingRectWithSize:NSMakeSize(destBounds.size.width, 10000) options:NSStringDrawingUsesLineFragmentOrigin].size.height;
        if (height > destBounds.size.height)
        {
            if ([pageNo isEqualToString:@"0"])
            {
                pageFontSize = [self applyGraphicScale:[eventNode attributeFloatValue:@"smallfontsize"]];
                fnt = [NSFont fontWithName:@"onebillionreader-Regular" size:pageFontSize];
                NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithDictionary:@{NSFontAttributeName:fnt}];
                if ([eventNode attributeFloatValue:@"smallspacing"])
                {
                    letterSpacing = [self applyGraphicScale:[eventNode attributeFloatValue:@"smallspacing"]];
                    attrs[NSKernAttributeName] = @(letterSpacing);
                }
                if ([eventNode attributeFloatValue:@"smalllineheight"])
                    mps.lineHeightMultiple = [eventNode attributeFloatValue:@"smalllineheight"];
                attrs[NSParagraphStyleAttributeName] = mps;
                as = [[NSAttributedString alloc]initWithString:ms attributes:attrs];
            }
            else
            {
                float diff = height - destBounds.size.height;
                destBounds.size.height += diff;
                destBounds.origin.y -= diff / 2;
            }
        }
        destBounds = NSInsetRect(destBounds, -5, -5);
        ACSDText *atext = [[ACSDText alloc]initWithName:@"t1_1" fill:nil stroke:nil rect:destBounds layer:layer];
        [atext setTopMargin:0];
        [atext setLeftMargin:0];
        [atext setBottomMargin:0];
        [atext setRightMargin:0];
        atext.contents = [[NSTextStorage alloc]initWithAttributedString:as];
        [layer addGraphic:atext];
        if (!showBoxes)
        {
            [imageBox setHidden:YES];
            [textBox setHidden:YES];
        }
        if (showButtons)
        {
            [self loadButton:@"back" pos:@"tl" intoLayer:layer];
            [self loadButton:@"repeataudio" pos:@"tr" intoLayer:layer];
            [self loadButton:@"next" pos:@"br" intoLayer:layer];
            if (![pageNo isEqualToString:@"0"])
                [self loadButton:@"prev" pos:@"bl" intoLayer:layer];
        }
    }
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError * _Nullable *)outError
{
    NSLog(@"here");
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir;
    if ([fm fileExistsAtPath:[url path] isDirectory:&isDir])
    {
        if (isDir)
        {
            return [self readBookFromURL:url error:outError];
        }
    }
    return [self readFromData:[NSData dataWithContentsOfURL:url] ofType:typeName error:outError];
}

-(XMLNode*)bookXMLFromXliff:(XMLNode*)xliffNode
{
    if (![xliffNode.nodeName isEqualToString:@"xliff"])
        return [self xmlErr:@"no xliff node"];
    NSArray *arr = [xliffNode childrenOfType:@"file"];
    if ([arr count] == 0)
        return [self xmlErr:@"no file node"];
    XMLNode *n = arr[0];
    arr = [n childrenOfType:@"body"];
    if ([arr count] == 0)
        return [self xmlErr:@"no body node"];
    XMLNode *bookNode = [[XMLNode alloc]initWithName:@"book"];
    NSMutableArray *outputPageNodes = [NSMutableArray array];
    NSArray *transUnits = [arr[0] childrenOfType:@"trans-unit"];
    NSInteger i = 0;
    NSString *currPage = nil;
    XMLNode *pageNode;
    while (i < [transUnits count])
    {
        XMLNode *transUnitNode = transUnits[i];
        NSString *key = [transUnitNode attributeStringValue:@"id"];
        NSInteger idx = [key rangeOfString:@"_"].location;
        NSString *pageNoStr = [key substringToIndex:idx];
        XMLNode *targetNode = [transUnitNode childOfType:@"target" identifier:nil];
        if (![pageNoStr isEqualToString:currPage])
        {
            pageNode = [[XMLNode alloc]initWithName:@"page"];
            pageNode.attributes = @{@"pageno":[pageNoStr substringFromIndex:1]};
            currPage = pageNoStr;
            [outputPageNodes addObject:pageNode];
        }
        XMLNode *paraNode = [[XMLNode alloc]initWithName:@"para"];
        paraNode.contents = targetNode.contents;
        [pageNode.children addObject:paraNode];
        i++;
    }
    bookNode.children = outputPageNodes;
    return bookNode;
}

-(id)xmlErr:(NSString*)msg
{
    NSLog(@"%@",msg);
    return nil;
}

- (IBAction)importXliff:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowedFileTypes:@[@"xliff"]];
    [panel beginSheetModalForWindow:[[self frontmostMainWindowController] window]
                  completionHandler:^(NSInteger result)
     {
        if (result == NSModalResponseOK)
        {
            for (NSURL *url in [panel URLs])
            {
                NSString *path = [url path];
                XMLNode *root = [[[XMLManager alloc]init]parseFile:path];
                if (root)
                    [self updateWithBookXML:[self bookXMLFromXliff:root]runParasTogether:YES];
            }
        }
    }];
}

#pragma mark -

-(NSDictionary*)pagesDict
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (ACSDPage *p in self.pages)
    {
        NSString *name = p.pageTitle;
        if (name)
            dict[name] = p;
    }
    return dict;
}

-(NSArray*)textRectsForBookPage:(NSString *)pno
{
    //pno = [NSString stringWithFormat:@"p%@",pno];
    NSMutableArray *rects = [NSMutableArray array];
    ACSDPage *page = [self pagesDict][pno];
    if (page)
    {
        ACSDGraphic *pageGraphic = nil;
        NSArray *ls = [page layersWithName:@"preview"];
        if ([ls count] > 0)
        {
            ACSDLayer *imageLayer = ls[0];
            NSArray *gs = [imageLayer graphicsWithName:pno];
            if ([gs count] > 0)
                pageGraphic = gs[0];
        }
        if (pageGraphic)
        {
            NSBitmapImageRep *bm = newBitmap(self.documentSize.width,self.documentSize.height);
            NSImage *im = [[NSImage alloc]initWithSize:self.documentSize];
            [im addRepresentation:bm];
            [im lockFocusFlipped:YES];
            NSRect bnds = NSZeroRect;
            bnds.size = self.documentSize;
            [[NSAffineTransform transformWithTranslateXBy:0 yBy:bnds.size.height]concat];
            [[NSAffineTransform transformWithScaleXBy:1.0 yBy:-1.0]concat];
            [pageGraphic draw:bnds inView:nil selected:NO isGuide:NO cacheDrawing:NO options:nil];
            [im unlockFocus];
            CGImageRef cgim = [im CGImageForProposedRect:&bnds context:nil hints:@{}];
            VNImageRequestHandler *irh = [[VNImageRequestHandler alloc]initWithCGImage:cgim options:@{}];
            VNRecognizeTextRequest *req = [[VNRecognizeTextRequest alloc]initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
                if (error == nil)
                {
                    NSArray<VNRecognizedTextObservation*> *obs = request.results;
                    for (VNRecognizedTextObservation *ob in obs)
                    {
                        NSArray<VNRecognizedText*>*txts = [ob topCandidates:1];
                        for (VNRecognizedText *txt in txts)
                        {
                            NSError *er = nil;
                            VNRectangleObservation *rectobj = [txt boundingBoxForRange:NSMakeRange(0, [txt.string length]) error:&er];
                            CGRect r = rectobj.boundingBox;
                            [rects addObject:[NSValue valueWithRect:VNImageRectForNormalizedRect(r,bnds.size.width,bnds.size.height)]];
                        }
                    }
                }
            }];
            NSError *err;
            [irh performRequests:@[req] error:&err];
        }
    }
    return rects;
}

-(NSArray*)consolidateTextRects:(NSArray<NSValue*>*)textRects
{
    if ([textRects count] <= 1)
        return textRects;
    NSRect r0 = [textRects[0]rectValue];
    NSRect r1 = [textRects[1]rectValue];
    NSRect rx = NSUnionRect(r0, r1);
    NSMutableArray *marr = [NSMutableArray arrayWithObject:[NSValue valueWithRect:rx]];
    [marr addObjectsFromArray:[textRects subarrayWithRange:NSMakeRange(2, [textRects count] - 2)]];
    return marr;
}
-(void)updateWithBookXML:(XMLNode*)xmlNode runParasTogether:(BOOL)runParas
{
    NSDictionary *pagesDict = [self pagesDict];
    NSArray *pageNodes = [xmlNode childrenOfType:@"page"];
    for (XMLNode *pageNode in pageNodes)
    {
        NSString *pno = [pageNode attributeStringValue:@"pageno"];
        if (pno)
        {
            pno = [NSString stringWithFormat:@"p%@",pno];
            ACSDPage *page = pagesDict[pno];
            if (page)
            {
                ACSDGraphic *pageGraphic = nil;
                NSArray *ls = [page layersWithName:@"image"];
                if ([ls count] > 0)
                {
                    ACSDLayer *imageLayer = ls[0];
                    NSArray *gs = [imageLayer graphicsWithName:pno];
                    if ([gs count] > 0)
                        pageGraphic = gs[0];
                }
                NSArray<XMLNode*>*paraNodes = [pageNode childrenOfType:@"para"];
                if ([paraNodes count] > 0)
                {
                    NSArray *textRects = [self textRectsForBookPage:pno];
                    CGFloat y = self.documentSize.height - 300,x = 100;
                    if ([paraNodes count] > 1 && runParas)
                    {
                        XMLNode *pNode = [[XMLNode alloc]initWithName:@"para"];
                        NSMutableString *mstr = [@"" mutableCopy];
                        for (XMLNode *para in paraNodes)
                        {
                            if ([mstr length] > 0)
                                [mstr appendString:@"\n"];
                            [mstr appendString:para.contents];
                        }
                        pNode.contents = mstr;
                        paraNodes = @[pNode];
                    }
                    while ([textRects count] > [paraNodes count])
                        textRects = [self consolidateTextRects:textRects];
                    int idx = 1;
                    for (XMLNode *para in paraNodes)
                    {
                        NSString *text = [[para.contents componentsSeparatedByString:@"/"]componentsJoinedByString:@""];
                        NSString *textBoxName = [NSString stringWithFormat:@"t%d_1",idx];
                        NSArray<ACSDGraphic*>*graphics = [page graphicsWithName:textBoxName];
                        if ([graphics count] > 0)
                        {
                            if ([graphics[0] isKindOfClass:[ACSDText class]])
                            {
                                ACSDText *t = (ACSDText*)graphics[0];
                                if (t)
                                {
                                    NSTextStorage *ts = [t contents];
                                    [ts beginEditing];
                                    [ts replaceCharactersInRange:NSMakeRange(0, [ts length]) withString:text];
                                    [ts endEditing];
                                    NSRect destBounds = [t bounds];
                                    NSSize sz = NSInsetRect(destBounds, 5, 5).size;
                                    sz.height = 10000;
                                    sz = [ts boundingRectWithSize:sz options:NSStringDrawingUsesLineFragmentOrigin].size;
                                    float height = sz.height + 10;
                                    if (height > destBounds.size.height)
                                    {
                                        if ([pno isEqualToString:@"0"])
                                        {
                                        }
                                        else
                                        {
                                            float diff = height - destBounds.size.height;
                                            destBounds.size.height += diff;
                                            destBounds.origin.y -= diff / 2;
                                        }
                                        [t setGraphicBoundsTo:destBounds from:[t bounds]];
                                    }
                                    [t invalidateGraphicSizeChanged:YES shapeChanged:NO redraw:YES notify:NO];
                                }
                            }
                        }
                        else
                        {
                            ACSDLayer *layer = page.layers[1];
                            NSRect r = NSMakeRect(x,y,300,200);
                            if ([textRects count] > idx - 1)
                                r = [textRects[idx - 1]rectValue];
                            ACSDText *t = [[ACSDText alloc]initWithName:textBoxName fill:nil stroke:nil rect:r layer:layer];
                            x += 100;
                            y -= 100;
                            NSColor *textFill = [NSColor blackColor];
                            NSFont *f = [NSFont fontWithName:@"onebillionreader-Regular" size:200];
                            if (f == nil)
                                f = [NSFont systemFontOfSize:200];
                            f = FontToFitSize(f, text, r.size, YES, YES, YES);
                            NSAttributedString *mas = [[NSAttributedString alloc]initWithString:text attributes:@{NSFontAttributeName:f,NSForegroundColorAttributeName:textFill}];
                            NSTextStorage *contents = [[NSTextStorage alloc]initWithAttributedString:mas];
                            [contents addLayoutManager:[t layoutManager]];
                            [t setContents:contents];
                            [[layer graphics] addObject:[self registerObject:t]];
                            if (pageGraphic)
                            {
                                [ACSDLink uLinkFromObject:t toObject:pageGraphic anchor:-1 substitutePageNo:NO changeAttributes:YES undoManager:[self undoManager]];
                            }

                        }
                        idx++;
                    }                }

            }
        }
        NSView *graphicView = [[self frontmostMainWindowController] graphicView];
        [graphicView setNeedsDisplay:YES];
    }
}- (IBAction)importBookXML:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowedFileTypes:@[@"public.xml"]];
    [panel beginSheetModalForWindow:[[self frontmostMainWindowController] window]
                  completionHandler:^(NSInteger result)
     {
        if (result == NSModalResponseOK)
        {
            for (NSURL *url in [panel URLs])
            {
                NSString *path = [url path];
                XMLNode *root = [[[XMLManager alloc]init]parseFile:path];
                if (root)
                    [self updateWithBookXML:root runParasTogether:NO];
             }
        }
    }];
}


-(void)insertImagesAsBook:(NSDictionary*)imageDict
{
    NSArray *pageNames = [[imageDict allKeys]sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 caseInsensitiveCompareWithNumbers:obj2];
    }];
    if ([pageNames count] == 0)
        return;
    NSImage *firstImage = imageDict[pageNames[0]][0];
    CGSize sz = [firstImage size];
    NSPoint loc = NSMakePoint(sz.width/2.0, sz.height/2.0);
    [[[self frontmostMainWindowController] graphicView]changeDocumentSize:sz];
    for (NSString *pageName in pageNames)
    {
        ACSDPage *page = [[[self frontmostMainWindowController] graphicView]addNewPageAtIndex:[pages count]];
        page.pageTitle = pageName;
        ACSDLayer *l = [[[self frontmostMainWindowController] graphicView]currentEditableLayer];
        l.name = @"text";
        l = [[[self frontmostMainWindowController] graphicView]addNewLayerAtIndex:[page.layers count]];
        l.name = @"preview";
        l.exportable = NO;
        l = [[[self frontmostMainWindowController] graphicView]addNewLayerAtIndex:[page.layers count]];
        NSArray *arr = imageDict[pageName];
        [[[self frontmostMainWindowController] graphicView]createImage:arr[0] name:pageName location:&loc fileName:arr[1]];
        l.editable = NO;
        l.exportable = NO;
        l.name = @"image";
        [[[self frontmostMainWindowController] graphicView]setCurrentEditableLayerIndex:1 force:NO select:NO withUndo:NO];
    }
    
}

-(void)insertPreviewImagesForBook:(NSDictionary*)imageDict
{
    GraphicView *gview = [[self frontmostMainWindowController] graphicView];
    CGSize sz = [gview bounds].size;
    NSPoint loc = NSMakePoint(sz.width/2.0, sz.height/2.0);
    for (ACSDPage *page in pages)
    {
        NSString *name = [page pageTitle];
        if (name)
        {
            if (imageDict[name])
            {
                NSImage *oldim = nil;
                NSArray<ACSDLayer*>*layers = [page layersWithName:@"image"];
                if ([layers count] > 0)
                {
                    ACSDLayer *l = layers[0];
                    NSArray *gs = [l graphicsWithName:name];
                    if ([gs count] > 0)
                    {
                        ACSDGraphic *g = gs[0];
                        if (g && [g isKindOfClass:[ACSDImage class]])
                        {
                            oldim = [((ACSDImage*)g) image];
                        }
                    }
                }
                layers = [page layersWithName:@"preview"];
                if ([layers count] > 0)
                {
                    ACSDLayer *layer = layers[0];
                    NSInteger idx = [pages indexOfObject:page];
                    [gview setCurrentPageIndex:idx force:NO withUndo:YES];
                    [gview setCurrentEditableLayerIndex:[page.layers indexOfObject:layer] force:NO select:NO withUndo:YES];
                    ACSDImage *im = [gview createImage:imageDict[name][0] name:name location:&loc fileName:imageDict[name][1]];
                    
/*                    NSError *err;
                    VNImageRequestHandler *reqHandler = [[VNImageRequestHandler alloc]initWithCGImage:[oldim CGImageForProposedRect:NULL context:nil hints:nil] options:@{}];
                    VNImageRegistrationRequest *imageRegReq = [[VNTranslationalImageRegistrationRequest alloc]initWithTargetedCGImage:[imageDict[name][0] CGImageForProposedRect:NULL context:nil hints:nil] options:@{}];
                    [reqHandler performRequests:@[imageRegReq] error:nil];
                    VNImageTranslationAlignmentObservation *obs = [imageRegReq.results firstObject];
                    CGAffineTransform trans = obs.alignmentTransform;
                    NSLog(@"tr %g %g %g %g",trans.a,trans.d,trans.tx,trans.ty);
                    
                    VNImageRequestHandler *reqHandler2 = [[VNImageRequestHandler alloc]initWithCGImage:[oldim CGImageForProposedRect:NULL context:nil hints:nil] options:@{}];
                    VNImageRegistrationRequest *imageRegReq2 = [[VNHomographicImageRegistrationRequest alloc]initWithTargetedCGImage:[imageDict[name][0] CGImageForProposedRect:NULL context:nil hints:nil] options:@{}];
                    [reqHandler2 performRequests:@[imageRegReq2] error:&err];
                    VNImageHomographicAlignmentObservation *obs2 = [imageRegReq2.results firstObject];
*/
                    [im setAlpha:0.6];
                    [im setGraphicXScale:1.417 yScale:1.417 undo:NO];
                }
            }
        }
    }
}




- (IBAction)importImagesAsBook:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:YES];
    [panel setAllowedFileTypes:@[@"public.image"]];
    [panel beginSheetModalForWindow:[[self frontmostMainWindowController] window]
                  completionHandler:^(NSInteger result)
     {
        if (result == NSModalResponseOK)
        {
            NSMutableDictionary *imageDict = [NSMutableDictionary dictionary];
            for (NSURL *url in [panel URLs])
            {
                NSString *path = [url path];
                NSString *fn = [[url lastPathComponent]stringByDeletingPathExtension];
                NSImage *im = [[NSImage alloc]initWithContentsOfURL:url];
                imageDict[fn] = @[im,path];
            }
            [self insertImagesAsBook:imageDict];
        }
    }];
}

- (IBAction)importPreviewImagesForBook:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:YES];
    [panel setAllowedFileTypes:@[@"public.image"]];
    [panel beginSheetModalForWindow:[[self frontmostMainWindowController] window]
                  completionHandler:^(NSInteger result)
     {
        if (result == NSModalResponseOK)
        {
            NSMutableDictionary *imageDict = [NSMutableDictionary dictionary];
            for (NSURL *url in [panel URLs])
            {
                NSString *path = [url path];
                NSString *fn = [[url lastPathComponent]stringByDeletingPathExtension];
                NSImage *im = [[NSImage alloc]initWithContentsOfURL:url];
                imageDict[fn] = @[im,path];
            }
            [self insertPreviewImagesForBook:imageDict];
        }
    }];
    
}

- (IBAction)importSVGsAsGraphics:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:YES];
    [panel setAllowedFileTypes:@[@"svg"]];
    [panel beginSheetModalForWindow:[[self frontmostMainWindowController] window]
                  completionHandler:^(NSInteger result)
     {
        if (result == NSModalResponseOK)
        {
            for (NSURL *url in [panel URLs])
            {
                NSData *d = [NSData dataWithContentsOfURL:url];
                ACSDrawDocument *adoc = [[ACSDrawDocument alloc]init];
                [adoc readFromData:d ofType:@"svg" error:nil];
                NSArray *graphics = [adoc allGraphics];
                NSMutableSet *strokeSet = [NSMutableSet setWithCapacity:10];
                NSMutableSet *fillSet = [NSMutableSet setWithCapacity:10];
                GraphicView *gv = [[self frontmostMainWindowController]graphicView];
                ACSDLayer *l = [gv currentEditableLayer];
                for (ACSDGraphic *g in graphics)
                {
                    [g setFillFromFills:self.fills];
                    [g setStrokeFromStrokes:self.strokes];
                    [strokeSet unionSet:[g usedStrokes]];
                    [fillSet unionSet:[g usedFills]];
                    [g.layer.graphics removeObject:g];
                    [g setLayer:l];
                    [gv addElement:g];
                }
                [[self strokes] addNewObjectsFromArray:[strokeSet allObjects]];
                [[self fills] addNewObjectsFromArray:[fillSet allObjects]];
            }
        }
    }];
    
    
}

@end
