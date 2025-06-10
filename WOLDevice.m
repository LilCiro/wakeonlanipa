#import "WOLDevice.h"

@implementation WOLDevice

// NSSecureCoding protokolü için gerekli
+ (BOOL)supportsSecureCoding {
    return YES;
}

// Başlatıcı
- (instancetype)initWithName:(NSString *)name mac:(NSString *)mac ip:(NSString *)ip port:(NSInteger)port subnetMask:(NSString *)subnetMask groupID:(NSString *)groupID {
    self = [super init];
    if (self) {
        _deviceID = [[NSUUID UUID] UUIDString]; // Benzersiz ID oluştur
        _name = name;
        _macAddress = mac;
        _ipAddress = ip;
        _port = port;
        _subnetMask = subnetMask;
        _groupID = groupID; // Grup ID'sini de ata
    }
    return self;
}

// NSCoding protokolü metotları (objeyi serileştirmek ve deseryalize etmek için)
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.deviceID forKey:@"deviceID"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.macAddress forKey:@"macAddress"];
    [coder encodeObject:self.ipAddress forKey:@"ipAddress"];
    [coder encodeInteger:self.port forKey:@"port"];
    [coder encodeObject:self.subnetMask forKey:@"subnetMask"];
    [coder encodeObject:self.groupID forKey:@"groupID"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        // decodeObjectOfClass: ile güvenli deserializasyon
        _deviceID = [coder decodeObjectOfClass:[NSString class] forKey:@"deviceID"];
        _name = [coder decodeObjectOfClass:[NSString class] forKey:@"name"];
        _macAddress = [coder decodeObjectOfClass:[NSString class] forKey:@"macAddress"];
        _ipAddress = [coder decodeObjectOfClass:[NSString class] forKey:@"ipAddress"];
        _port = [coder decodeIntegerForKey:@"port"];
        _subnetMask = [coder decodeObjectOfClass:[NSString class] forKey:@"subnetMask"];
        _groupID = [coder decodeObjectOfClass:[NSString class] forKey:@"groupID"];
    }
    return self;
}

@end