#import <UIKit/UIKit.h>

@interface DeviceListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSString *groupID;   // Bu cihaz listesinin ait olduğu grup ID'si
@property (nonatomic, strong) NSString *groupName; // Bu cihaz listesinin görünen adı

- (instancetype)initWithGroupID:(NSString *)groupID groupName:(NSString *)groupName;

@end