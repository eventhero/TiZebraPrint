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
#import "TcpPrinterConnection.h"
#import "GraphicsUtil.h"
#import "ZebraPrinterFactory.h"
#import "MfiBtPrinterConnection.h"

@implementation IoEventheroTizebraprintModule

@synthesize networkPrintersList;
@synthesize bluetoothPrintersList;
@synthesize connection;
@synthesize printer;

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
    if(self.connection) {
        NSLog(@"[INFO] [TiZebraPrint] closing connection");
        [self.connection close];
    }
    [networkPrintersList release];
    [bluetoothPrintersList release];
    [connection release];
    [printer release];

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
              x:(NSInteger)x
              y:(NSInteger)y
         height:(NSInteger)height
          width:(NSInteger)width
 isInsideFormat:(BOOL)isInsideFormat
          error:(NSError**)error {

    if(self.printer != nil) {
        NSLog(@"[INFO] [TiZebraPrint] printer instance created");
        id<GraphicsUtil, NSObject> graphicsUtil = [self.printer getGraphicsUtil];
        
        BOOL success = [graphicsUtil printImage:image atX:x atY:y withWidth:width withHeight:height andIsInsideFormat:isInsideFormat error:error];
        
        if (!success) {
            NSLog(@"[INFO] [TiZebraPrint] print failed %@",error);
            return NO;
        } else {
            NSLog(@"[INFO] [TiZebraPrint] print success");
            return YES;
        }
    } else {
        NSLog(@"[INFO] [TiZebraPrint] Could not detect printer language. Did you set properties in info.plist? %@",error);
        return NO;
    }
}

#pragma Public APIs

-(id)findBluetoothPrinters:(id)args
{
    NSLog(@"[INFO] [TiZebraPrint] getting bluetooth printers");
    EAAccessoryManager *manager = [EAAccessoryManager sharedAccessoryManager];
    self.bluetoothPrintersList = [[NSMutableArray alloc] initWithArray:manager.connectedAccessories];
    
    NSMutableArray *printers = [[[NSMutableArray alloc]init] autorelease];
    for (EAAccessory *accessory in self.bluetoothPrintersList) {
        [printers addObject:[[NSDictionary dictionaryWithObjectsAndKeys:@"bluetooth",@"kind",accessory.name,@"name",accessory.serialNumber,@"serialNumber", nil] autorelease]];
    }
    
    return printers;
}

-(id)findNetworkPrinters:(id)args
{
    NSLog(@"[INFO] [TiZebraPrint] getting network printers");
    NSError *error = nil;
    NSMutableArray *printers = [[[NSMutableArray alloc]init] autorelease];
    self.networkPrintersList = [[NSMutableArray alloc] initWithArray:[NetworkDiscoverer localBroadcast:&error]];
    NSLog(@"[INFO] [TiZebraPrint] NetworkDiscoverer ? %@",error);
    
    for (DiscoveredPrinterNetwork *d in self.networkPrintersList) {
        NSLog(@"[INFO] [TiZebraPrint] address: %@ port: %i dnsName: %@",d.address,d.port,d.dnsName);
        NSString *address = d.address;
        NSNumber *port = [NSNumber numberWithInt:d.port];
        NSString *name = d.dnsName;

        NSMutableDictionary *thisPrinter = [NSMutableDictionary dictionary];
        [thisPrinter setValue:@"network" forKey:@"kind"];
        [thisPrinter setValue:name forKey:@"name"];
        [thisPrinter setValue:address forKey:@"address"];
        [thisPrinter setValue:port forKey:@"port"];

        [printers addObject:thisPrinter];
    }

    return printers;
}

-(id)selectPrinter:(id)args
{
    ENSURE_SINGLE_ARG_OR_NIL(args, NSDictionary);
    // we need either the Bluetooth serial number OR the network IP & Port
    NSString *serialNumber = [TiUtils stringValue:@"serialNumber" properties:args];
    
    NSString *ipAddress = [TiUtils stringValue:@"ipAddress" properties:args];
    NSInteger port = [TiUtils intValue:@"port" properties:args];
    
    // success/error callback
    KrollCallback* callback = [args objectForKey:@"callback"];
    
    NSLog(@"[INFO] [TiZebraPrint] args %@",args);
    
    if(self.connection) {
        NSLog(@"[INFO] [TiZebraPrint] closing connection");
        [self.connection close];
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if(serialNumber) {
            // bluetooth!
            self.connection = [[MfiBtPrinterConnection alloc] initWithSerialNumber:serialNumber];
        } else {
            // network!
            self.connection = [[TcpPrinterConnection alloc] initWithAddress:ipAddress andWithPort:port];
        }
        
        NSError *error = nil;
        [self.connection open];
        self.printer = [ZebraPrinterFactory getInstance:self.connection error:&error];
        NSLog(@"[INFO] [TiZebraPrint] testing printerfactory for errors %@",error);
        
        if(callback){
            NSMutableDictionary *event = [NSMutableDictionary dictionary];
            [event setValue:NUMBOOL(!error) forKey:@"success"];
            if (error) {
                [event setValue:error.code forKey:@"code"];
                [event setValue:error.localizedDescription forKey:@"message"];
            }
            [callback call:[NSArray arrayWithObjects:event, nil] thisObject:self];
        }
    });
}

-(id)print:(id)args
{
    ENSURE_SINGLE_ARG_OR_NIL(args, NSDictionary);
    
    NSLog(@"[INFO] [TiZebraPrint] args %@",args);
    
    // success/error callback
    KrollCallback* callback = [args objectForKey:@"callback"];
    
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
            success = [self printImage:img x:x y:y height:height width:width isInsideFormat:isInsideFormat error:&error];
        } else {
            size_t nPages = CGPDFDocumentGetNumberOfPages(thisPDF);
            size_t pageNum;
            for (pageNum = 1; pageNum <= nPages; pageNum++) {
                CGImageRef img = [[self imageFromPDF:thisPDF page:pageNum] CGImage];
                success = [self printImage:img x:x y:y height:height width:width isInsideFormat:isInsideFormat error:&error];
                if (!success) {
                    break;
                }
            }
        }
        
        CGPDFDocumentRelease(thisPDF);
    } else {
        success = [self printImage:[image.image CGImage] x:x y:y height:height width:width isInsideFormat:isInsideFormat error:&error];
    }
    
    if(callback){
        NSMutableDictionary *event = [NSMutableDictionary dictionary];
        [event setValue:NUMBOOL(success) forKey:@"success"];
        if (!success) {
            [event setValue:error.code forKey:@"code"];
            [event setValue:error.localizedDescription forKey:@"message"];
        }
        [callback call:[NSArray arrayWithObjects:event, nil] thisObject:self];
    }
}

@end
