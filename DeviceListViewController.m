#import "DeviceListViewController.h"
#import "DeviceSettingsViewController.h"
#import "DeveloperOptionsViewController.h"
#import "ThemeSelectionViewController.h" // Tema Seçim Ekranı
#import "WOLDevice.h"
#import "ThemeManager.h"

@interface DeviceListViewController ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<WOLDevice *> *devices; // Bu sekmeye ait cihazları tutacak dizi
@property (nonatomic, strong) UILabel *versionLabel; // Sürüm etiketi
@property (nonatomic, assign) NSInteger versionTapCount; // Geliştirici seçenekleri için sayaç
@end

@implementation DeviceListViewController

- (instancetype)initWithGroupID:(NSString *)groupID groupName:(NSString *)groupName {
    self = [super init];
    if (self) {
        _groupID = groupID;
        _groupName = groupName;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.groupName; // Sekmenin başlığını grup adından al

    // Tema değişikliği bildirimine abone ol
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleThemeChange:) name:ThemeChangedNotification object:nil];
    // Mevcut temayı uygula
    [[ThemeManager sharedManager] applyThemeToView:self.view];

    // Sağ üst köşeye "Ekle" butonu
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addDevice)];
    self.navigationItem.rightBarButtonItem = addButton;

    // Sol üst köşeye "Ayarlar" butonu (Tema Seçimi için)
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"gearshape.fill"] style:UIBarButtonItemStylePlain target:self action:@selector(showThemeSettings)];
    self.navigationItem.leftBarButtonItem = settingsButton;


    // TableView oluştur
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];

    // Cihazları yükle (sadece bu gruba ait olanları)
    [self loadDevices];

    // Sürüm Bilgisi Etiketi (Geliştirici seçenekleri için tıklanacak yer)
    self.versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 50, self.view.bounds.size.width, 30)];
    self.versionLabel.textAlignment = NSTextAlignmentCenter;
    // Tema yöneticisinden rengi al
    self.versionLabel.textColor = [[ThemeManager sharedManager] colorFromHexString:[[ThemeManager sharedManager] loadCurrentTheme][@"statusTextColor"]];
    self.versionLabel.text = [NSString stringWithFormat:@"Sürüm: %@", [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"]];
    self.versionLabel.userInteractionEnabled = YES; // Tıklama algılamak için
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(versionLabelTapped:)];
    tapGesture.numberOfTapsRequired = 5; // 5 kez tıklama
    [self.versionLabel addGestureRecognizer:tapGesture];
    [self.view addSubview:self.versionLabel];
}

// Görünüm her göründüğünde (cihaz ayarlarından geri dönüldüğünde de) listeyi yenile
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadDevices]; // Cihazları tekrar yükle (değişiklikler için)
    [self.tableView reloadData]; // TableView'ı yenile
    // Tema değişikliği bildirimine abone ol (her görünümde yenilenebilir)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleThemeChange:) name:ThemeChangedNotification object:nil];
    [[ThemeManager sharedManager] applyThemeToView:self.view]; // Temayı tekrar uygula
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // Görünüm kaybolduğunda bildirim aboneliğini kaldır
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ThemeChangedNotification object:nil];
}

- (void)dealloc {
    // ViewController silindiğinde bildirim aboneliğini kaldır
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Data Management

- (void)loadDevices {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *encodedDevicesData = [defaults objectForKey:@"allSavedDevices"];
    if (encodedDevicesData) {
        NSSet *classes = [NSSet setWithObjects:[NSMutableArray class], [WOLDevice class], nil];
        NSMutableArray<WOLDevice *> *allDevices = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:encodedDevicesData error:nil];
        if (allDevices) {
            // Sadece bu gruba ait cihazları filtrele
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"groupID == %@", self.groupID];
            self.devices = [[allDevices filteredArrayUsingPredicate:predicate] mutableCopy];
        } else {
            self.devices = [NSMutableArray array];
        }
    } else {
        self.devices = [NSMutableArray array];
    }
}

- (void)saveAllDevices:(NSMutableArray<WOLDevice *> *)allDevices {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSError *error = nil;
    NSData *encodedDevices = [NSKeyedArchiver archivedDataWithRootObject:allDevices requiringSecureCoding:YES error:&error];
    if (error) {
        NSLog(@"Tüm cihazlar kaydedilirken hata: %@", error.localizedDescription);
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hata" message:@"Cihazlar kaydedilemedi." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        [defaults setObject:encodedDevices forKey:@"allSavedDevices"];
        [defaults synchronize];
    }
}

// Yeni cihaz eklemek veya mevcut cihazı güncellemek için
- (void)updateDevice:(WOLDevice *)device {
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

    BOOL found = NO;
    for (int i = 0; i < allDevices.count; i++) {
        if ([allDevices[i].deviceID isEqualToString:device.deviceID]) {
            [allDevices replaceObjectAtIndex:i withObject:device];
            found = YES;
            break;
        }
    }
    if (!found) {
        [allDevices addObject:device]; // Yeni cihaz ekle
    }
    [self saveAllDevices:allDevices];
    [self loadDevices]; // Bu gruba ait olanları tekrar yükle
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.devices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"DeviceCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    WOLDevice *device = self.devices[indexPath.row];
    cell.textLabel.text = device.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"MAC: %@ - IP: %@", device.macAddress, device.ipAddress];

    // Hücrenin arka plan ve metin renklerini temaya göre ayarla
    NSDictionary *currentTheme = [[ThemeManager sharedManager] loadCurrentTheme];
    cell.backgroundColor = [[ThemeManager sharedManager] colorFromHexString:currentTheme[@"fieldBackgroundColor"]]; // Genellikle giriş alanı arka plan rengi gibi
    cell.textLabel.textColor = [[ThemeManager sharedManager] colorFromHexString:currentTheme[@"textColor"]];
    cell.detailTextLabel.textColor = [[ThemeManager sharedManager] colorFromHexString:currentTheme[@"statusTextColor"]]; // Daha açık renk

    return cell;
}

// Swipe ile silme özelliği
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Silme onayı iste
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cihazı Sil" message:@"Bu cihazı silmek istediğinizden emin misiniz?" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Sil" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            // Tüm cihazlar listesinden sil
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
            
            // Silinecek cihazı tüm cihazlar listesinde bul ve kaldır
            WOLDevice *deviceToDelete = self.devices[indexPath.row];
            for (int i = 0; i < allDevices.count; i++) {
                if ([allDevices[i].deviceID isEqualToString:deviceToDelete.deviceID]) {
                    [allDevices removeObjectAtIndex:i];
                    break;
                }
            }
            [self saveAllDevices:allDevices]; // Tüm cihaz listesini kaydet

            [self.devices removeObjectAtIndex:indexPath.row]; // Sadece bu gruptan kaldır
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"İptal" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES]; // Seçimi kaldır

    WOLDevice *selectedDevice = self.devices[indexPath.row];
    DeviceSettingsViewController *settingsVC = [[DeviceSettingsViewController alloc] initWithDevice:selectedDevice groupID:self.groupID];
    [self.navigationController pushViewController:settingsVC animated:YES]; // Ayar ekranına geç
}

#pragma mark - Actions

- (void)addDevice {
    // Yeni cihaz eklemek için ayar ekranına yönlendir
    // Yeni cihazın hangi gruba ait olacağını da gönderiyoruz
    DeviceSettingsViewController *settingsVC = [[DeviceSettingsViewController alloc] initWithDevice:nil groupID:self.groupID];
    [self.navigationController pushViewController:settingsVC animated:YES];
}

// Sürüm etiketine tıklama algılayıcısı
- (void)versionLabelTapped:(UITapGestureRecognizer *)sender {
    self.versionTapCount++;
    if (self.versionTapCount >= 5) {
        self.versionTapCount = 0; // Sayacı sıfırla
        [self showDeveloperOptions]; // Geliştirici seçeneklerini göster
    }
}

// Tema Seçim Ekranını Gösterme Metodu (Ana Menüden erişilebilir)
- (void)showThemeSettings {
    ThemeSelectionViewController *themeVC = [[ThemeSelectionViewController alloc] init];
    [self.navigationController pushViewController:themeVC animated:YES]; // Tema seçim ekranına geç
}

// Geliştirici Seçenekleri ekranını gösterme metodu
- (void)showDeveloperOptions {
    DeveloperOptionsViewController *devOptionsVC = [[DeveloperOptionsViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:devOptionsVC];
    [self presentViewController:navController animated:YES completion:nil];
}

// Tema değişikliği bildirimi geldiğinde
- (void)handleThemeChange:(NSNotification *)notification {
    [[ThemeManager sharedManager] applyThemeToView:self.view]; // Tüm görünüme temayı uygula
    // TableView'ın görünümünü güncellemek için reload yap
    [self.tableView reloadData];
    // Sürüm etiketi rengini güncelle (eğer değiştiyse)
    self.versionLabel.textColor = [[ThemeManager sharedManager] colorFromHexString:[[ThemeManager sharedManager] loadCurrentTheme][@"statusTextColor"]];
}

@end