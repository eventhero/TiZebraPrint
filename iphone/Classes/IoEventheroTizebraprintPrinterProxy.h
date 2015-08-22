#import "TiProxy.h"
#import "ZebraPrinterConnection.h"
#import "ZebraPrinter.h"

@interface IoEventheroTizebraprintPrinterProxy : TiProxy
{
@private
    id<ZebraPrinterConnection, NSObject> _connection;
    id<ZebraPrinter, NSObject> _printer;
}
@end