#import "WOLManager.h"
#import <net/if.h>
#import <arpa/inet.h>
#import <sys/socket.h>

@implementation WOLManager

+ (instancetype)sharedManager {
    static WOLManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

// MAC adresini byte dizisine çevir (yardımcı fonksiyon)
- (NSData *)dataFromHexString:(NSString *)string {
    string = [string stringByReplacingOccurrencesOfString:@":" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"-" withString:@""];
    NSMutableData *data = [[NSMutableData alloc] init];
    unsigned char byte;
    char chars[3];
    chars[2] = '\0';
    for (int i = 0; i < [string length] / 2; i++) {
        chars[0] = [string characterAtIndex:i * 2];
        chars[1] = [string characterAtIndex:i * 2 + 1];
        byte = strtol(chars, NULL, 16);
        [data appendBytes:&byte length:1];
    }
    return data;
}

// Bilgisayarı açma (Wake-on-LAN)
- (void)wakeComputer:(WOLDevice *)device completion:(void (^)(BOOL success, NSString *message))completion {
    // Veri kontrolü
    if (device.macAddress.length == 0 || device.ipAddress.length == 0 || device.port == 0) {
        completion(NO, @"MAC, IP ve Port adresi girin.");
        return;
    }

    NSData *macData = [self dataFromHexString:device.macAddress];
    if (macData.length != 6) {
        completion(NO, @"Geçersiz MAC adresi formatı.");
        return;
    }

    NSMutableData *magicPacket = [NSMutableData dataWithBytes:"\xFF\xFF\xFF\xFF\xFF\xFF" length:6];
    for (int i = 0; i < 16; i++) {
        [magicPacket appendData:macData];
    }

    const char *cIP = [device.ipAddress UTF8String];

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(device.port); // Kullanıcının girdiği portu kullan
    inet_pton(AF_INET, cIP, &addr.sin_addr);

    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock < 0) {
        completion(NO, [NSString stringWithFormat:@"Soket hatası: %s", strerror(errno)]);
        return;
    }

    int broadcastEnable = 1;
    if (setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &broadcastEnable, sizeof(broadcastEnable)) < 0) {
        completion(NO, [NSString stringWithFormat:@"Broadcast hatası: %s", strerror(errno)]);
        close(sock);
        return;
    }

    ssize_t bytesSent = sendto(sock, [magicPacket bytes], [magicPacket length], 0, (struct sockaddr *)&addr, sizeof(addr));
    close(sock);

    if (bytesSent == [magicPacket length]) {
        completion(YES, @"Açma komutu gönderildi (Doğrudan)!");
    } else {
        completion(NO, [NSString stringWithFormat:@"Açma hatası: %s", strerror(errno)]);
    }
}

// Bilgisayarı kapatma (Python sunucusu üzerinden)
- (void)shutdownComputer:(WOLDevice *)device completion:(void (^)(BOOL success, NSString *message))completion {
    // Python sunucunuzun IP adresini cihazın kendi IP adresi olarak kullanıyoruz
    // Bu, Python sunucusunun o bilgisayar üzerinde çalıştığını varsayar.
    if (device.ipAddress.length == 0 || device.port == 0) {
        completion(NO, @"Cihaz IP adresi ve Port girin.");
        return;
    }

    // Python sunucusunun dinlediği portu kullanın (genellikle 5000)
    // Şunu unutmayın: Python sunucusu sadece kapatma komutu için, WOL için değil.
    // WOL için direk UDP paketi gönderiliyor.
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%ld/shutdown", device.ipAddress, (long)device.port];
    NSURL *url = [NSURL URLWithString:urlString];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            completion(NO, [NSString stringWithFormat:@"Kapatma Hatası: %@", error.localizedDescription]);
        } else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200) {
                completion(YES, @"Kapatma komutu gönderildi (Sunucu Üzerinden)!");
            } else {
                completion(NO, [NSString stringWithFormat:@"Sunucu Hatası: %ld", (long)httpResponse.statusCode]);
            }
        }
    }];
    [task resume];
}

@end