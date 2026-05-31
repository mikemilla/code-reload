#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(BunbuModule, RCTEventEmitter)

RCT_EXTERN_METHOD(initialize)
RCT_EXTERN_METHOD(showSheet)
RCT_EXTERN_METHOD(hideSheet)
RCT_EXTERN_METHOD(bootstrap:(NSDictionary *)files hash:(NSString *)hash)
RCT_EXTERN_METHOD(configureAgent:(NSDictionary *)config)
RCT_EXTERN_METHOD(configureGitHub:(NSString *)clientId)
RCT_EXTERN_METHOD(onRuntimeError:(NSString *)message)

@end
