#import "DeviceSettingsViewController.h"
#import "WOLManager.h"
#import "ThemeManager.h" // Tema yönetimini kullanmak için

@interface DeviceSettingsViewController () <UITextFieldDelegate> // UITextFieldDelegate'i ekle
@property (nonatomic, strong) UITextField *nameField;
@property (nonatomic, strong) UITextField *macAddressField;
@property (nonatomic, strong) UITextField *ipAddressField;
@property (nonatomic, strong) UITextField *portField;
@property (nonatomic, strong) UITextField *subnetMaskField;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *wakeButton;
@property (nonatomic, strong) UIButton *shutdownButton;
@property (nonatomic, strong) UIButton *saveButton; // Kaydet butonu

@end

@implementation DeviceSettingsViewController

// Eski başlatıcıyı da destekleyelim ama yeniyle birleştirelim
- (instancetype)initWithDevice:(WOLDevice *)device {
    return [self initWithDevice:device groupID:nil]; // groupID'yi nil olarak gönder
}

- (instancetype)initWithDevice:(WOLDevice *)device groupID:(NSString *)groupID {
    self = [super init];
    if (self) {
        _device = device;
        _groupID = groupID;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.device ? @"Cihazı Düzenle" : @"Yeni Cihaz Ekle";

    // Tema değişikliği bildirimine abone ol
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleThemeChange:) name:ThemeChangedNotification object:nil];
    // Mevcut temayı uygula
    [[ThemeManager sharedManager] applyThemeToView:self.view];

    // Arayüz elemanlarını oluştur
    CGFloat yOffset = 100;
    CGFloat fieldWidth = self.view.bounds.size.width - 40;
    CGFloat fieldHeight = 40;
    CGFloat spacing = 20;

    // Cihaz Adı
    self.nameField = [[UITextField alloc] initWithFrame:CGRectMake(20, yOffset, fieldWidth, fieldHeight)];
    self.nameField.placeholder = @"Cihaz Adı (örn: Ev Bilgisayarı)";
    self.nameField.borderStyle = UITextBorderStyleRoundedRect;
    self.nameField.delegate = self; // Delegate atandı
    [self.view addSubview:self.nameField];
    yOffset += fieldHeight + spacing;

    // MAC Adresi
    self.macAddressField = [[UITextField alloc] initWithFrame:CGRectMake(20, yOffset, fieldWidth, fieldHeight)];
    self.macAddressField.placeholder = @"MAC Adresi (örn: 00:1A:2B:3C:4D:5E)";
    self.macAddressField.borderStyle = UITextBorderStyleRoundedRect;
    self.macAddressField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.macAddressField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.macAddressField.keyboardType = UIKeyboardTypeASCIICapable;
    self.macAddressField.delegate = self; // Delegate atandı
    [self.view addSubview:self.macAddressField];
    yOffset += fieldHeight + spacing;

    // IP Adresi
    self.ipAddressField = [[UITextField alloc] initWithFrame:CGRectMake(20, yOffset, fieldWidth, fieldHeight)];
    self.ipAddressField.placeholder = @"Hedef IP / Broadcast IP (örn: 192.168.1.255)";
    self.ipAddressField.borderStyle = UITextBorderStyleRoundedRect;
    self.ipAddressField.keyboardType = UIKeyboardTypeDecimalPad;
    self.ipAddressField.delegate = self; // Delegate atandı
    [self.view addSubview:self.ipAddressField];
    yOffset += fieldHeight + spacing;

    // Port
    self.portField = [[UITextField alloc] initWithFrame:CGRectMake(20, yOffset, (fieldWidth - spacing) / 2, fieldHeight)];
    self.portField.placeholder = @"Port (örn: 9)";
    self.portField.borderStyle = UITextBorderStyleRoundedRect;
    self.portField.keyboardType = UIKeyboardTypeNumberPad;
    self.portField.delegate = self; // Delegate atandı
    [self.view addSubview:self.portField];

    // Subnet Mask
    self.subnetMaskField = [[UITextField alloc] initWithFrame:CGRectMake(20 + (fieldWidth - spacing) / 2 + spacing, yOffset, (fieldWidth - spacing) / 2, fieldHeight)];
    self.subnetMaskField.placeholder = @"Subnet Mask (örn: 255.255.255.0)";
    self.subnetMaskField.borderStyle = UITextBorderStyleRoundedRect;
    self.subnetMaskField.keyboardType = UIKeyboardTypeDecimalPad;
    self.subnetMaskField.delegate = self; // Delegate atandı
    [self.view addSubview:self.subnetMaskField];
    yOffset += fieldHeight + spacing;

    // Durum Etiketi
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, yOffset, fieldWidth, 40)];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    // Tema yöneticisinden rengi al
    self.statusLabel.textColor = [[ThemeManager sharedManager] colorFromHexString:[[ThemeManager sharedManager] loadCurrentTheme][@"statusTextColor"]];
    [self.view addSubview:self.statusLabel];
    yOffset += 40 + spacing;

    // Kaydet Butonu
    self.saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.saveButton.frame = CGRectMake(20, yOffset, fieldWidth, 50);
    [self.saveButton setTitle:@"Cihazı Kaydet" forState:UIControlStateNormal];
    [self.saveButton addTarget:self action:@selector(saveDevice) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.saveButton];
    yOffset += 50 + spacing;

    // Sadece mevcut cihaz varsa Aç/Kapat butonlarını göster
    if (self.device) {
        self.wakeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.wakeButton.frame = CGRectMake(20, yOffset, (fieldWidth - spacing) / 2, 50);
        [self.wakeButton setTitle:@"Bilgisayarı Aç" forState:UIControlStateNormal];
        [self.wakeButton addTarget:self action:@selector(wakeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.wakeButton];

        self.shutdownButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.shutdownButton.frame = CGRectMake(20 + (fieldWidth - spacing) / 2 + spacing, yOffset, (fieldWidth - spacing) / 2, 50);
        [self.shutdownButton setTitle:@"Bilgisayarı Kapat" forState:UIControlStateNormal];
        [self.shutdownButton addTarget:self action:@selector(shutdownButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.shutdownButton];
    }

    // Cihaz mevcutsa verileri alanlara doldur, yoksa varsayılanları ayarla
    if (self.device) {
        self.nameField.text = self.device.name;
        self.macAddressField.text = self.device.macAddress;
        self.ipAddressField.text = self.device.ipAddress;
        self.portField.text = [NSString stringWithFormat:@"%ld", (long)self.device.port];
        self.subnetMaskField.text = self.device.subnetMask;
    } else {
        // Yeni cihaz için varsayılan değerler
        self.portField.text = @"9";
        self.subnetMaskField.text = @"255.255.255.0";
    }
}

- (void)dealloc {
    // ViewController silindiğinde bildirim aboneliğini kaldır
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Actions

- (void)saveDevice {
    NSString *name = self.nameField.text;
    NSString *mac = self.macAddressField.text;
    NSString *ip = self.ipAddressField.text;
    NSInteger port = [self.portField.text integerValue];
    NSString *subnet = self.subnetMaskField.text;

    // Temel doğrulama
    if (name.length == 0 || mac.length == 0 || ip.length == 0 || port == 0 || subnet.length == 0) {
        self.statusLabel.text = @"Tüm alanları doldurun.";
        return;
    }
    
    // MAC adresi format kontrolü (basit bir regex veya elle kontrol daha iyi olur)
    // Şimdilik sadece uzunluk kontrolü yapalım
    NSString *cleanedMac = [mac stringByReplacingOccurrencesOfString:@":" withString:@""];
    cleanedMac = [cleanedMac stringByReplacingOccurrencesOfString:@"-" withString:@""];
    if (cleanedMac.length != 12) {
        self.statusLabel.text = @"Geçersiz MAC adresi formatı. (Örn: 00:1A:2B:3C:4D:5E)";
        return;
    }

    // Cihazı güncelle veya yeni oluştur
    if (self.device) {
        self.device.name = name;
        self.device.macAddress = mac;
        self.device.ipAddress = ip;
        self.device.port = port;
        self.device.subnetMask = subnet;
        // groupID değişmeyecek, zaten atanmış
    } else {
        // Yeni cihaz oluştur ve groupID'yi ata
        self.device = [[WOLDevice alloc] initWithName:name mac:mac ip:ip port:port subnetMask:subnet groupID:self.groupID];
    }
    
    // Tüm cihazlar listesini NSUserDefaults'tan al
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *encodedDevicesData = [defaults objectForKey:@"allSavedDevices"];
    NSMutableArray<WOLDevice *> *allDevices = nil;
    if (encodedDevicesData) {
        NSSet *classes = [NSSet setWithObjects:[NSMutableArray class], [WOLDevice class], nil];
        allDevices = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:encodedDevicesData error:nil];
        if (!allDevices) allDevices = [NSMutableArray array];
    } else {
        allDevices = [NSMutableArray array];
    }

    // Cihazı tüm cihazlar listesinde güncelle veya ekle
    BOOL found = NO;
    for (int i = 0; i < allDevices.count; i++) {
        if ([allDevices[i].deviceID isEqualToString:self.device.deviceID]) {
            [allDevices replaceObjectAtIndex:i withObject:self.device];
            found = YES;
            break;
        }
    }
    if (!found) {
        [allDevices addObject:self.device];
    }

    // Güncellenmiş tüm cihazlar listesini kaydet
    NSError *error = nil;
    NSData *newEncodedDevices = [NSKeyedArchiver archivedDataWithRootObject:allDevices requiringSecureCoding:YES error:&error];
    if (error) {
        NSLog(@"Cihazlar kaydedilirken hata: %@", error.localizedDescription);
        self.statusLabel.text = @"Kaydetme hatası!";
        return;
    } else {
        [defaults setObject:newEncodedDevices forKey:@"allSavedDevices"];
        [defaults synchronize];
        self.statusLabel.text = @"Cihaz başarıyla kaydedildi!";
    }

    // Geri dön
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)wakeButtonPressed {
    self.statusLabel.text = @"Açma komutu gönderiliyor...";
    [[WOLManager sharedManager] wakeComputer:self.device completion:^(BOOL success, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.statusLabel.text = message;
        });
    }];
}

- (void)shutdownButtonPressed {
    self.statusLabel.text = @"Kapatma komutu gönderiliyor...";
    [[WOLManager sharedManager] shutdownComputer:self.device completion:^(BOOL success, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.statusLabel.text = message;
        });
    }];
}

#pragma mark - UITextFieldDelegate (Klavyeyi gizlemek için)
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder]; // Klavyeyi kapat
    return YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES]; // Ekrandaki herhangi bir yere dokunulduğunda klavyeyi kapat
}

// Tema değişikliği bildirimi geldiğinde
- (void)handleThemeChange:(NSNotification *)notification {
    [[ThemeManager sharedManager] applyThemeToView:self.view]; // Tüm görünüme temayı uygula
    // Durum etiketi rengini güncelle
    self.statusLabel.textColor = [[ThemeManager sharedManager] colorFromHexString:[[ThemeManager sharedManager] loadCurrentTheme][@"statusTextColor"]];
}

@end