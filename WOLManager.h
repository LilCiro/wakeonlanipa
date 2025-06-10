#import <Foundation/Foundation.h>
#import "WOLDevice.h" // WOLDevice modeline ihtiyacımız var

@interface WOLManager : NSObject

+ (instancetype)sharedManager; // Tekil örnek

// Bilgisayarı açma (Wake-on-LAN)
- (void)wakeComputer:(WOLDevice *)device completion:(void (^)(BOOL success, NSString *message))completion;

// Bilgisayarı kapatma (Python sunucusu üzerinden)
- (void)shutdownComputer:(WOLDevice *)device completion:(void (^)(BOOL success, NSString *message))completion;

@end