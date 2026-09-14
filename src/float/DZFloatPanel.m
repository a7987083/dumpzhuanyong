#import "DZFloatPanel.h"
#import <QuartzCore/QuartzCore.h>

@interface DZFloatPanel ()
@property (nonatomic, strong) UIView *titleBar;
@property (nonatomic, assign) CGPoint panStartCenter;
@end

@implementation DZFloatPanel

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.backgroundColor = [UIColor colorWithRed:0.055 green:0.06 blue:0.075 alpha:0.97];
    self.layer.cornerRadius = 14.0;
    self.layer.masksToBounds = YES;
    self.layer.borderWidth = 1.0;
    self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.10].CGColor;

    _titleBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), 48)];
    _titleBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _titleBar.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.035];
    [self addSubview:_titleBar];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, CGRectGetWidth(frame) - 70, 48)];
    title.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    title.text = @"DumpZhuanYong FloatUI";
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont boldSystemFontOfSize:16.0];
    [_titleBar addSubview:title];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame = CGRectMake(CGRectGetWidth(frame) - 52, 4, 44, 40);
    close.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [close setTitle:@"×" forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont systemFontOfSize:26.0 weight:UIFontWeightRegular];
    [close setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.85] forState:UIControlStateNormal];
    [close addTarget:self action:@selector(closeTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_titleBar addSubview:close];

    UILabel *body = [[UILabel alloc] initWithFrame:CGRectMake(16, 66, CGRectGetWidth(frame) - 32, 160)];
    body.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    body.numberOfLines = 0;
    body.textColor = [UIColor colorWithWhite:1.0 alpha:0.82];
    body.font = [UIFont systemFontOfSize:13.0];
    body.text = @"H5GG-style floating window baseline\n\n• independent transparent UIWindow\n• touch pass-through outside controls\n• draggable floating button\n• draggable panel\n• iOS 13+ UIWindowScene binding\n• no makeKeyAndVisible";
    [self addSubview:body];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    pan.maximumNumberOfTouches = 1;
    [_titleBar addGestureRecognizer:pan];

    return self;
}

- (void)closeTapped:(id)sender {
    (void)sender;
    if (self.closeAction) self.closeAction();
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
    CGRect frame = self.frame;
    const CGFloat visibleHeader = 56.0;

    CGFloat minX = -CGRectGetWidth(frame) + visibleHeader;
    CGFloat maxX = CGRectGetWidth(bounds) - visibleHeader;
    CGFloat minY = 0.0;
    CGFloat maxY = MAX(0.0, CGRectGetHeight(bounds) - visibleHeader);

    frame.origin.x = MAX(minX, MIN(maxX, frame.origin.x));
    frame.origin.y = MAX(minY, MIN(maxY, frame.origin.y));
    self.frame = frame;
}

@end
