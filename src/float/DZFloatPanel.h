#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DZFloatPanel : UIView
@property (nonatomic, copy, nullable) dispatch_block_t closeAction;
- (void)clampToSuperviewBounds;
@end

NS_ASSUME_NONNULL_END
