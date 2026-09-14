#import "DZFloatButton.h"
#import <QuartzCore/QuartzCore.h>

@interface DZFloatButton ()
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, assign) CGPoint panStartCenter;
@end

@implementation DZFloatButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.92];
    self.layer.cornerRadius = CGRectGetWidth(frame) * 0.5;
    self.layer.masksToBounds = YES;
    self.layer.borderWidth = 1.0;
    self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.18].CGColor;
    self.layer.zPosition = CGFLOAT_MAX;

    _label = [[UILabel alloc] initWithFrame:self.bounds];
    _label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _label.textAlignment = NSTextAlignmentCenter;
    _label.textColor = UIColor.whiteColor;
    _label.font = [UIFont boldSystemFontOfSize:15.0];
    _label.text = @"UI";
    _label.userInteractionEnabled = NO;
    [self addSubview:_label];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    pan.maximumNumberOfTouches = 1;
    [self addGestureRecognizer:pan];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [tap requireGestureRecognizerToFail:pan];
    [self addGestureRecognizer:tap];

    return self;
}

- (void)setDisplayText:(NSString *)text { self.label.text = text; }

- (void)handleTap:(UITapGestureRecognizer *)tap {
    if (tap.state == UIGestureRecognizerStateEnded && self.tapAction) self.tapAction();
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    UIView *superview = self.superview;
    if (!superview) return;

    if (pan.state == UIGestureRecognizerStateBegan) self.panStartCenter = self.center;
    CGPoint translation = [pan translationInView:superview];
    self.center = CGPointMake(self.panStartCenter.x + translation.x,
                              self.panStartCenter.y + translation.y);
    [self clampToSuperviewBounds];
}

- (void)clampToSuperviewBounds {
    UIView *superview = self.superview;
    if (!superview) return;
    CGRect bounds = superview.bounds;
    CGFloat halfW = CGRectGetWidth(self.bounds) * 0.5;
    CGFloat halfH = CGRectGetHeight(self.bounds) * 0.5;
    CGPoint center = self.center;
    center.x = MAX(halfW, MIN(CGRectGetWidth(bounds) - halfW, center.x));
    center.y = MAX(halfH, MIN(CGRectGetHeight(bounds) - halfH, center.y));
    self.center = center;
}

@end
