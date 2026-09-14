#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DZFloatButton : UIControl
@property (nonatomic, copy, nullable) dispatch_block_t tapAction;
- (void)setDisplayText:(NSString *)text;
- (void)clampToSuperviewBounds;
@end

NS_ASSUME_NONNULL_END
