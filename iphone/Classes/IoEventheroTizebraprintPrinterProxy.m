/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2012 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "IoEventheroTizebraprintPrinterProxy.h"
#import "TiUtils.h"

#import "MfiBtPrinterConnection.h"
#import "TcpPrinterConnection.h"
#import "ZebraPrinterFactory.h"
#import "GraphicsUtil.h"

#include "TiCallback.h"

@implementation IoEventheroTizebraprintPrinterProxy

-(void)_initWithProperties:(NSDictionary *)properties
{
    
    NSLog(@"[DEBUG] [TiZebraPrint] _initWithProperties %@", properties);
    [super _initWithProperties:properties];
    _connection = nil;
    _printer = nil;
}

-(void)_destroy
{
    RELEASE_TO_NIL(_printer);
    if (_connection!=nil) {
        [_connection close];
    }
    RELEASE_TO_NIL(_connection);
    NSLog(@"[DEBUG] [TiZebraPrint] closed connection");
    
    [super _destroy];
}

#pragma Helper Methods

#pragma Public APIs (available in javascript)
-(void)connect:(id)args
{
    NSLog(@"[INFO] [TiZebraPrint] connect() args %@",args);
    
    ENSURE_ARG_COUNT(args, 2);
    
    NSDictionary *connectArg = nil;
    ENSURE_ARG_AT_INDEX(connectArg, args, 0, NSDictionary)
    
    KrollCallback* callback = nil;
    ENSURE_ARG_AT_INDEX(callback, args, 1, KrollCallback)
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *serialNumber = [TiUtils stringValue:@"serialNumber" properties:connectArg];
        NSString *ip = [TiUtils stringValue:@"ip" properties:connectArg];
        NSInteger port = [TiUtils intValue:@"port" properties:connectArg];
        NSLog(@"[DEBUG] [TiZebraPrint] Connection params: %@, %@, %d", serialNumber, ip, port);
        
        if(serialNumber) {
            // bluetooth!
            NSLog(@"[DEBUG] [TiZebraPrint] Connecting to Bluetooth SN:%@", serialNumber);
            _connection = [[MfiBtPrinterConnection alloc] initWithSerialNumber:serialNumber];
        } else {
            // network!
            NSLog(@"[DEBUG] [TiZebraPrint] Connecting to IP:%@:%d", ip, port);
            _connection = [[TcpPrinterConnection alloc] initWithAddress:ip andWithPort:port];
        }
        NSLog(@"[DEBUG] [TiZebraPrint] opening connection");
        BOOL success = [_connection open];
        NSLog(@"[DEBUG] [TiZebraPrint] opening connection result: %d", success);
        
        NSError *error = nil;
        id<ZebraPrinter,NSObject> printer = [ZebraPrinterFactory getInstance:_connection error:&error];
        if (error!=nil) {
            NSLog(@"[ERROR] [TiZebraPrint] printer factory error %@", error);
            [TiCallback performErrorCallback:callback withError:error];
        } else {
            _printer = [printer retain];
            [TiCallback performSuccessCallback:callback];
        }
    });
}

-(void)getStatus:(id)args
{
    NSLog(@"[INFO] [TiZebraPrint] getStatus() args %@",args);
    ENSURE_ARG_COUNT(args, 1);
    
    KrollCallback* callback = nil;
    ENSURE_ARG_AT_INDEX(callback,args,0,KrollCallback)
    
    if (_connection==nil || _printer==nil) {
        [TiCallback performErrorCallback:callback withCode:-1 andMessage:@"Did you forget to call connect() ?"];
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSError *error = nil;
        PrinterStatus *printerStatus = [_printer getCurrentStatus:&error];
        if (error) {
            NSLog(@"[ERROR] [TiZebraPrint] Error getting printer status %@", error);
            [TiCallback performErrorCallback:callback withError:error];
        } else {
            NSLog(@"[DEBUG] [TiZebraPrint] specified printer status %@", printerStatus);
            if (printerStatus) {
                NSMutableDictionary *status = [NSMutableDictionary dictionary];
                [status setValue:NUMBOOL(printerStatus.isReadyToPrint) forKey:@"isReadyToPrint"];
                [status setValue:NUMBOOL(printerStatus.isHeadOpen) forKey:@"isHeadOpen"];
                [status setValue:NUMBOOL(printerStatus.isHeadCold) forKey:@"isHeadCold"];
                [status setValue:NUMBOOL(printerStatus.isHeadTooHot) forKey:@"isHeadTooHot"];
                [status setValue:NUMBOOL(printerStatus.isPaperOut) forKey:@"isPaperOut"];
                [status setValue:NUMBOOL(printerStatus.isRibbonOut) forKey:@"isRibbonOut"];
                [status setValue:NUMBOOL(printerStatus.isReceiveBufferFull) forKey:@"isReceiveBufferFull"];
                [status setValue:NUMBOOL(printerStatus.isPaused) forKey:@"isPaused"];
                [status setValue:NUMINTEGER(printerStatus.labelLengthInDots) forKey:@"labelLengthInDots"];
                [status setValue:NUMINTEGER(printerStatus.numberOfFormatsInReceiveBuffer) forKey:@"numberOfFormatsInReceiveBuffer"];
                [status setValue:NUMINTEGER(printerStatus.labelsRemainingInBatch) forKey:@"labelsRemainingInBatch"];
                [status setValue:NUMBOOL(printerStatus.isPartialFormatInProgress) forKey:@"isPartialFormatInProgress"];
                // TODO: Create printMode constants / Return printMode
                [TiCallback performSuccessCallback:callback withKey:@"status" andValue:status];
            } else {
                [TiCallback performErrorCallback:callback withCode:-1 andMessage:@"Did not get status yet."];
            }
        }
    });
}

-(void)print:(id)args
{
    NSLog(@"[DEBUG] [TiZebraPrint] print() args %@",args);
    
    ENSURE_ARG_COUNT(args, 2);
    
    NSDictionary *printArg = nil;
    ENSURE_ARG_AT_INDEX(printArg, args, 0, NSDictionary)
    
    KrollCallback *callback = nil;
    ENSURE_ARG_AT_INDEX(callback, args, 1, KrollCallback)
    
    // Images need a height/width to print
    TiBlob *image = [printArg objectForKey:@"image"];
    // everyone needs these properties but it will be rare to override defaults
    NSInteger x = [TiUtils intValue:@"x" properties:printArg def:0];
    NSInteger y = [TiUtils intValue:@"y" properties:printArg def:0];
    
    if (_connection==nil || _printer==nil) {
        [TiCallback performErrorCallback:callback withCode:-1 andMessage:@"Did you forget to call connect() ?"];
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSError *error = nil;
        
        id<GraphicsUtil, NSObject> graphicsUtil = [_printer getGraphicsUtil];
        
        BOOL success = [graphicsUtil printImage:[image.image CGImage] atX:x atY:y
                                      withWidth:image.width withHeight:image.height
                              andIsInsideFormat:NO error:&error];
        
        if(success) {
            [TiCallback performSuccessCallback:callback];
        } else {
            [TiCallback performErrorCallback:callback withError:error];
        }
    });
}

@end