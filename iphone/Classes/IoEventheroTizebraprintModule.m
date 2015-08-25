/**
 * tizebraprint
 *
 * Created by Your Name
 * Copyright (c) 2015 Your Company. All rights reserved.
 */

#import "IoEventheroTizebraprintModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"

#import <ExternalAccessory/ExternalAccessory.h>
#import "NetworkDiscoverer.h"
#import "DiscoveredPrinterNetwork.h"

#import "ZebraPrinterConnection.h"
#import "MfiBtPrinterConnection.h"
#import "TcpPrinterConnection.h"
#import "ZebraPrinterFactory.h"
#import "ZebraPrinter.h"
#import "GraphicsUtil.h"

#include "TiCallback.h"

@implementation IoEventheroTizebraprintModule

#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
    return @"7155b8a5-4855-4f19-81a7-2a7c803957a8";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
    return @"io.eventhero.tizebraprint";
}

#pragma mark Lifecycle

-(void)startup
{
    // this method is called when the module is first loaded
    // you *must* call the superclass
    [super startup];
    
    NSLog(@"[INFO] %@ loaded",self);
}

-(void)shutdown:(id)sender
{
    // this method is called when the module is being unloaded
    // typically this is during shutdown. make sure you don't do too
    // much processing here or the app will be quit forceably
    
    // you *must* call the superclass
    [super shutdown:sender];
}

#pragma mark Cleanup

-(void)dealloc
{
    // release any resources that have been retained by the module
    [super dealloc];
}

#pragma mark Internal Memory Management

-(void)didReceiveMemoryWarning:(NSNotification*)notification
{
    // optionally release any resources that can be dynamically
    // reloaded once memory is available - such as caches
    [super didReceiveMemoryWarning:notification];
}

#pragma mark Listener Notifications

-(void)_listenerAdded:(NSString *)type count:(int)count
{
    if (count == 1 && [type isEqualToString:@"my_event"])
    {
        // the first (of potentially many) listener is being added
        // for event named 'my_event'
    }
}

-(void)_listenerRemoved:(NSString *)type count:(int)count
{
    if (count == 0 && [type isEqualToString:@"my_event"])
    {
        // the last listener called for event named 'my_event' has
        // been removed, we can optionally clean up any resources
        // since no body is listening at this point for that event
    }
}

#pragma private methods

-(UIImage *)imageFromPDF:(CGPDFDocumentRef)pdf page:(size_t)pageNumber width:(CGFloat)width height:(CGFloat)height {
    // Drawing an image of this size
    CGRect imageRect = CGRectMake(0, 0, width, height);
    NSLog(@"[DEBUG] [TiZebraPrint] CGRectMake(0, 0, width, height) = [%f, %f, %f, %f]",
          imageRect.origin.x, imageRect.origin.y, imageRect.size.width, imageRect.size.height);
    
    // Start image drawing context
    UIGraphicsBeginImageContext(imageRect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Fill context with white color
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextFillRect(context, imageRect);
    
    UIImage *resultingImage = nil;
    
    CGPDFPageRef page = CGPDFDocumentGetPage(pdf, pageNumber);
    if (page != NULL) {
        CGContextSaveGState(context);
        
        // kCGPDFMediaBox is the max rect usually equal to the printed page size
        CGRect pageRect = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
        NSLog(@"[DEBUG] [TiZebraPrint] CGPDFPageGetBoxRect(page, kCGPDFMediaBox) = [%f, %f, %f, %f]",
              pageRect.origin.x, pageRect.origin.y, pageRect.size.width, pageRect.size.height);
        
        // This two transforms flip the image upside down
        CGContextTranslateCTM(context, 0.0, imageRect.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        
        // Create transform mapping PDF rect to drawing rect, no rotation, preserving aspect ratio
        // CGAffineTransform pdfTransform = CGPDFPageGetDrawingTransform(page, kCGPDFMediaBox, imageRect, 0, true);
        // CGContextConcatCTM(context, pdfTransform);
        
        CGFloat pdfScale = imageRect.size.width / pageRect.size.width;
        NSLog(@"[DEBUG] [TiZebraPrint] pdfScale = %f", pdfScale);
        // PDF units are PDF points (72 points per inch), image units are pixels, need to scale pdf page
        CGContextScaleCTM(context, pdfScale, pdfScale);
        
        CGContextDrawPDFPage(context, page);
        
        CGContextRestoreGState(context);
        
        resultingImage = UIGraphicsGetImageFromCurrentImageContext(); // returns autoreleased object
    }
    // End image drawing context
    UIGraphicsEndImageContext();
    
    return resultingImage;
}

#pragma Public APIs

// Rendering PDF to images has little to do with printing and can be reused with multiple printer drivers.
// This method needs to be pulled out into a separate shared module
-(id)renderPdf:(id)args
{
    NSLog(@"[DEBUG] [TiZebraPrint] renderPdf() args %@",args);
    
    ENSURE_ARG_COUNT(args, 1);
    
    NSDictionary *printArg = nil;
    ENSURE_ARG_AT_INDEX(printArg, args, 0, NSDictionary)
    
    // PDFs need a page number to print
    NSString *pdf = [TiUtils stringValue:@"pdf" properties:printArg def:@""];
    CGFloat width = [TiUtils floatValue:@"width" properties:printArg def:-1];
    CGFloat height = [TiUtils floatValue:@"height" properties:printArg def:-1];
    
    //    NSURL* url = [TiUtils toURL:[args objectForKey:@"url"] proxy:self];
    //    if (url==nil) {
    //        NSLog(@"[ERROR] Print called without passing in a url property!");
    //        return;
    //    }
    
    
    NSMutableArray *images = [NSMutableArray array];
    
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:pdf];
    CGPDFDocumentRef thisPDF = CGPDFDocumentCreateWithURL(url);
    if(thisPDF) {
        size_t nPages = CGPDFDocumentGetNumberOfPages(thisPDF);
        for (size_t pageNum = 1; pageNum <= nPages; pageNum++) {
            UIImage *image = [self imageFromPDF:thisPDF page:pageNum width:width height:height];
            if(image) {
                [images addObject:[[[TiBlob alloc] initWithImage:image] autorelease]];
            }
        }
    }
    
    CGPDFDocumentRelease(thisPDF); // works even when thisPDF is NULL
    
    return images;
}

-(void)findBluetoothPrinters:(id)args
{
    ENSURE_ARG_COUNT(args, 1);
    
    KrollCallback* callback = nil;
    ENSURE_ARG_AT_INDEX(callback, args, 0, KrollCallback)
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *printers = [NSMutableArray array];
        
        NSLog(@"[INFO] [TiZebraPrint] getting bluetooth printers");
        NSArray *accessories = [[EAAccessoryManager sharedAccessoryManager] connectedAccessories];
        for (EAAccessory *accessory in accessories) {
            if([accessory.protocolStrings indexOfObject:@"com.zebra.rawport"] != NSNotFound){
                [printers addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"bluetooth",@"kind",accessory.name,@"name",accessory.serialNumber,@"serialNumber", nil]];
            }
        }
        [TiCallback performSuccessCallback:callback withKey:@"printers" andValue:printers];
    });
}

-(void)findNetworkPrinters:(id)args
{
    ENSURE_ARG_COUNT(args, 1);
    
    KrollCallback* callback = nil;
    ENSURE_ARG_AT_INDEX(callback, args, 0, KrollCallback)
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"[INFO] [TiZebraPrint] getting network printers");
        NSError *error = nil;
        NSArray *networkPrintersList = [NetworkDiscoverer localBroadcast:&error];
        if (error) {
            NSLog(@"[ERROR] [TiZebraPrint] NetworkDiscoverer ? %@",error);
            [TiCallback performErrorCallback:callback withError:error];
        } else {
            NSMutableArray *printers = [NSMutableArray array];
            for (DiscoveredPrinterNetwork *d in networkPrintersList) {
                NSLog(@"[INFO] [TiZebraPrint] ip: %@ port: %i dnsName: %@", d.address, d.port, d.dnsName);
                
                NSMutableDictionary *thisPrinter = [NSMutableDictionary dictionary];
                [thisPrinter setValue:@"network" forKey:@"kind"];
                [thisPrinter setValue:d.dnsName forKey:@"name"];
                [thisPrinter setValue:d.address forKey:@"ip"];
                [thisPrinter setValue:NUMINTEGER(d.port) forKey:@"port"];
                
                [printers addObject:thisPrinter];
            }
            [TiCallback performSuccessCallback:callback withKey:@"printers" andValue:printers];
        }
    });
}
@end
