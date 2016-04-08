#include "TiCallback.h"

@implementation TiCallback

+(void) performErrorCallback:(KrollCallback *)callback withError:(NSError *)error {
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    [event setValue:NUMBOOL(NO) forKey:@"success"];
    [event setValue:NUMLONG(error.code) forKey:@"code"];
    [event setValue:error.localizedDescription forKey:@"message"];
    
    [callback call:[NSArray arrayWithObject:event] thisObject:self];
}

+(void) performErrorCallback:(KrollCallback *)callback withCode:(NSInteger)code andMessage:(NSString *)message {
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    [event setValue:NUMBOOL(NO) forKey:@"success"];
    [event setValue:NUMLONG(code) forKey:@"code"];
    [event setValue:message forKey:@"message"];
    
    [callback call:[NSArray arrayWithObject:event] thisObject:self];
}

+(void) performSuccessCallback:(KrollCallback *)callback {
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    [event setValue:NUMBOOL(YES) forKey:@"success"];
    
    [callback call:[NSArray arrayWithObject:event] thisObject:self];
}

+(void) performSuccessCallback:(KrollCallback *)callback withKey:(NSString *)key andValue:(id)value {
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    [event setValue:NUMBOOL(YES) forKey:@"success"];
    [event setObject:value forKey:key];
    
    [callback call:[NSArray arrayWithObject:event] thisObject:self];
}

@end