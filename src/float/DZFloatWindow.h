#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class DZFloatButton;
@class DZFloatPanel;

@interface DZFloatWindow : UIWindow
@property (nonatomic, weak, nullable) DZFloatButton *floatButton;
@property (nonatomic, weak, nullable) DZFloatPanel *floatPanel;
@end

@interface DZFloatRootController : UIViewController
@property (nonatomic, weak, nullable) UIWindow *hostWindow;
@property (nonatomic, copy, nullable) void (^layoutChanged)(CGSize size);
@end

FOUNDATION_EXPORT UIWindowScene * _Nullable DZActiveWindowScene(void) API_AVAILABLE(ios(13.0));
FOUNDATION_EXPORT UIWindow * _Nullable DZHostWindowForScene(UIWindowScene * _Nullable scene);

NS_ASSUME_NONNULL_END
