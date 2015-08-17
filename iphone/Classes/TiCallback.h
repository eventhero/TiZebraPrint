#include "TiProxy.h"

@interface TiCallback: NSObject
{
}
+(void) performErrorCallback:(KrollCallback *)callback withError:(NSError *)error;
+(void) performErrorCallback:(KrollCallback *)callback withCode:(NSInteger)code andMessage:(NSString *)message;
+(void) performSuccessCallback:(KrollCallback *)callback;
+(void) performSuccessCallback:(KrollCallback *)callback withKey:(NSString *)key andValue:(id)value;
@end

