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

-(KrollCallback *)extractCallbackFrom:(id)args
{
    KrollCallback* callback = nil;
    ENSURE_ARG_FOR_KEY(callback,args,@"callback",KrollCallback)
    return callback;
}

-(void) performErrorCallback:(KrollCallback *)callback withError:(NSError *)error {
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    [event setValue:NUMBOOL(NO) forKey:@"success"];
    [event setValue:NUMLONG(error.code) forKey:@"code"];
    [event setValue:error.localizedDescription forKey:@"message"];
    
    [callback call:[NSArray arrayWithObject:event] thisObject:self];
}

-(void) performErrorCallback:(KrollCallback *)callback withCode:(NSInteger)code andMessage:(NSString *)message {
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    [event setValue:NUMBOOL(NO) forKey:@"success"];
    [event setValue:NUMLONG(code) forKey:@"code"];
    [event setValue:message forKey:@"message"];
    
    [callback call:[NSArray arrayWithObject:event] thisObject:self];
}

-(void) performSuccessCallback:(KrollCallback *)callback {
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    [event setValue:NUMBOOL(YES) forKey:@"success"];
    
    [callback call:[NSArray arrayWithObject:event] thisObject:self];
}

-(void) performSuccessCallback:(KrollCallback *)callback withKey:(NSString *)key andValue:(id)value {
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    [event setValue:NUMBOOL(YES) forKey:@"success"];
    [event setObject:value forKey:key];
    
    [callback call:[NSArray arrayWithObject:event] thisObject:self];
}

-(void)openConnection:(id)args withCallback:(void(^)(id<ZebraPrinterConnection,NSObject>))callback {
    // we need either the Bluetooth serial number OR the network IP & Port
    NSString *serialNumber = [TiUtils stringValue:@"serialNumber" properties:args];
    NSString *ip = [TiUtils stringValue:@"ip" properties:args];
    NSInteger port = [TiUtils intValue:@"port" properties:args];
    NSLog(@"[DEBUG] [TiZebraPrint] Connection params: %@, %@, %d", serialNumber, ip, port);
    
    id<ZebraPrinterConnection, NSObject> connection = nil;
    if(serialNumber) {
        // bluetooth!
        NSLog(@"[DEBUG] [TiZebraPrint] Connecting to Bluetooth SN:%@", serialNumber);
        connection = [[MfiBtPrinterConnection alloc] initWithSerialNumber:serialNumber];
    } else {
        // network!
        NSLog(@"[DEBUG] [TiZebraPrint] Connecting to IP:%@:%d", ip, port);
        connection = [[TcpPrinterConnection alloc] initWithAddress:ip andWithPort:port];
    }
    NSLog(@"[DEBUG] [TiZebraPrint] opening connection");
    BOOL success = [connection open];
    NSLog(@"[DEBUG] [TiZebraPrint] opening connection result: %d", success);
    callback(connection);
    NSLog(@"[DEBUG] [TiZebraPrint] closing connection");
    [connection close];
    [connection release];
}

-(void)connectToPrinter:(id)args withCallback:(void(^)(NSError *, id<ZebraPrinter,NSObject>))callback {
    [self openConnection:args withCallback:^(id<ZebraPrinterConnection, NSObject> connection) {
        NSError *error = nil;
        id<ZebraPrinter, NSObject> printer = [ZebraPrinterFactory getInstance:connection error:&error];
        if (error) {
            NSLog(@"[ERROR] [TiZebraPrint] printer factory error %@", error);
            callback(error, nil);
        } else {
            callback(nil, printer);
        }
    }];
}


-(UIImage *)imageFromPDF:(CGPDFDocumentRef)pdf
                    page:(NSUInteger)pageNumber {
    
    CGPDFPageRef page = CGPDFDocumentGetPage(pdf, pageNumber);
    
    CGRect rect = CGPDFPageGetBoxRect(page, kCGPDFArtBox);
    
    UIImage *resultingImage = nil;
    
    UIGraphicsBeginImageContext(rect.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    const CGFloat fillColors[] = {1, 1, 1, 1};
    
    CGColorRef colorRef = CGColorCreate(rgb, fillColors);
    CGContextSetFillColorWithColor(context, colorRef);
    CGContextFillRect(context, rect);
    CGColorSpaceRelease(rgb);
    CGColorRelease(colorRef);
    
    CGContextTranslateCTM(context, 0.0, rect.size.height);
    
    CGContextScaleCTM(context, 1.0, -1.0);
    
    if (page != NULL) {
        CGContextSaveGState(context);
        
        CGAffineTransform pdfTransform = CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, rect, 0, true);
        
        CGContextConcatCTM(context, pdfTransform);
        
        CGContextDrawPDFPage(context, page);
        
        CGContextRestoreGState(context);
        
        resultingImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    
    UIGraphicsEndImageContext();
    
    return resultingImage;
}

-(id)printImage:(CGImageRef)image
      toPrinter:(id<ZebraPrinter, NSObject>)printer
              x:(NSInteger)x
              y:(NSInteger)y
         height:(NSInteger)height
          width:(NSInteger)width
 isInsideFormat:(BOOL)isInsideFormat
          error:(NSError**)error {

    if(printer != nil) {
        NSLog(@"[INFO] [TiZebraPrint] printer instance created");
        id<GraphicsUtil, NSObject> graphicsUtil = [printer getGraphicsUtil];
        
        BOOL success = [graphicsUtil printImage:image atX:x atY:y withWidth:width withHeight:height andIsInsideFormat:isInsideFormat error:error];
        
        if (!success) {
            NSLog(@"[INFO] [TiZebraPrint] print failed %@",error);
            return NO;
        } else {
            NSLog(@"[INFO] [TiZebraPrint] print success");
            return YES;
        }
    } else {
        NSLog(@"[INFO] [TiZebraPrint] Could not detect printer language. Did you set properties in info.plist?");
        return NO;
    }
}

#pragma Public APIs

-(void)findBluetoothPrinters:(id)args
{
    ENSURE_SINGLE_ARG(args, NSDictionary); // WARNING! args now is NSDIctionary, not NSArray
    KrollCallback* callback = [self extractCallbackFrom:args];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *printers = [NSMutableArray array];

        NSLog(@"[INFO] [TiZebraPrint] getting bluetooth printers");
        NSArray *accessories = [[EAAccessoryManager sharedAccessoryManager] connectedAccessories];
        for (EAAccessory *accessory in accessories) {
            if([accessory.protocolStrings indexOfObject:@"com.zebra.rawport"] != NSNotFound){
                [printers addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"bluetooth",@"kind",accessory.name,@"name",accessory.serialNumber,@"serialNumber", nil]];
            }
        }
        [self performSuccessCallback:callback withKey:@"printers" andValue:printers];
    });
}

-(void)findNetworkPrinters:(id)args
{
    ENSURE_SINGLE_ARG(args, NSDictionary); // WARNING! args now is NSDIctionary, not NSArray
    KrollCallback* callback = [self extractCallbackFrom:args];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"[INFO] [TiZebraPrint] getting network printers");
        NSError *error = nil;
        NSArray *networkPrintersList = [NetworkDiscoverer localBroadcast:&error];
        if (error) {
            NSLog(@"[ERROR] [TiZebraPrint] NetworkDiscoverer ? %@",error);
            [self performErrorCallback:callback withError:error];
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
            [self performSuccessCallback:callback withKey:@"printers" andValue:printers];
        }
    });
}


-(void)print:(id)args
{
    NSLog(@"[DEBUG] [TiZebraPrint] print() args %@",args);
    ENSURE_SINGLE_ARG(args, NSDictionary); // WARNING! args now is NSDIctionary, not NSArray
    
    KrollCallback* callback = [self extractCallbackFrom:args];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        [self connectToPrinter:args withCallback:^(NSError *error, id<ZebraPrinter, NSObject> printer) {
            if (error) {
                [self performErrorCallback:callback withError:error];
            } else {
                // Images need a height/width to print, along with "isInsideFormat"
                TiBlob *image = [args objectForKey:@"image"];
                
                // PDFs need a page number to print
                NSString *pdf = [TiUtils stringValue:@"pdf" properties:args def:@""];
                NSInteger pdfPage = [TiUtils intValue:@"page" properties:args def:0];
                
                // everyone needs these properties but it will be rare to override defaults
                NSInteger x = [TiUtils intValue:@"x" properties:args def:0];
                NSInteger y = [TiUtils intValue:@"y" properties:args def:0];
                NSInteger width = [TiUtils intValue:@"width" properties:args def:-1];
                NSInteger height = [TiUtils intValue:@"height" properties:args def:-1];
                BOOL isInsideFormat = [TiUtils boolValue:@"isInsideFormat" properties:args def:NO];
                
                NSError *error = nil;
                BOOL success = NO;
                
                if (pdf) {
                    CFURLRef url = (CFURLRef)CFBridgingRetain([[NSURL alloc] initFileURLWithPath:pdf]);
                    CGPDFDocumentRef thisPDF = CGPDFDocumentCreateWithURL(url);
                    
                    if (pdfPage > 0) {
                        size_t pageNum = pdfPage;
                        CGImageRef img = [[self imageFromPDF:thisPDF page:pageNum] CGImage];
                        success = [self printImage:img toPrinter:printer x:x y:y height:height width:width isInsideFormat:isInsideFormat error:&error];
                    } else {
                        size_t nPages = CGPDFDocumentGetNumberOfPages(thisPDF);
                        size_t pageNum;
                        for (pageNum = 1; pageNum <= nPages; pageNum++) {
                            CGImageRef img = [[self imageFromPDF:thisPDF page:pageNum] CGImage];
                            success = [self printImage:img toPrinter:printer x:x y:y height:height width:width isInsideFormat:isInsideFormat error:&error];
                            if (!success) {
                                break;
                            }
                        }
                    }
                    
                    CGPDFDocumentRelease(thisPDF);
                    CFRelease(url);
                } else {
                    success = [self printImage:[image.image CGImage] toPrinter:printer x:x y:y height:height width:width isInsideFormat:isInsideFormat error:&error];
                }
                if(success) {
                    [self performSuccessCallback:callback];
                } else {
                    [self performErrorCallback:callback withCode:-1 andMessage:@"Printing failed"];
                }
            }
        }];
    });
}
@end
