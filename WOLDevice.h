#import <Foundation/Foundation.h>

@interface WOLDevice : NSObject <NSCoding, NSSecureCoding> // NSSecureCoding de ekledik

@property (nonatomic, strong) NSString *deviceID;      // Benzersiz ID
@property (nonatomic, strong) NSString *name;          // Cihaz Adı (örn: Ev Bilgisayarı)
@property (nonatomic, strong) NSString *macAddress;
@property (nonatomic, strong) NSString *ipAddress;
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, strong) NSString *subnetMask;
@property (nonatomic, strong) NSString *groupID; // Cihazın ait olduğu grubun ID'si (sekme ID'si)

// Başlatıcı (initializer)
- (instancetype)initWithName:(NSString *)name mac:(NSString *)mac ip:(NSString *)ip port:(NSInteger)port subnetMask:(NSString *)subnetMask groupID:(NSString *)groupID;

@end