/**
 * tizebraprint
 *
 * Created by Your Name
 * Copyright (c) 2015 Your Company. All rights reserved.
 */

#import "TiModule.h"

#import "ZebraPrinter.h"
#import "ZebraPrinterConnection.h"

@interface IoEventheroTizebraprintModule : TiModule
{
}

@property (nonatomic, retain) id<ZebraPrinterConnection, NSObject> connection;
@property (nonatomic, retain) id<ZebraPrinter, NSObject> printer;

@end
