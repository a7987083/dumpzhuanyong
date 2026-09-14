#import "DZAdTrace.h"
#import <QuartzCore/QuartzCore.h>

static UIWindow *gWindow;
static UIButton *gFloatButton;
static UIView *gPanel;
static UILabel *gStatus;
static UILabel *gLastLabel;
static UIButton *gTraceButton;

@interface DZAdTraceCoordinator : NSObject
+ (instancetype)shared;
@end

@implementation DZAdTraceCoordinator
+ (instancetype)shared { static DZAdTraceCoordinator *x; static dispatch_once_t once; dispatch_once(&once, ^{ x=[self new]; }); return x; }
- (UILabel *)label:(CGRect)frame font:(CGFloat)size { UILabel *l=[[UILabel alloc]initWithFrame:frame]; l.textColor=UIColor.whiteColor; l.font=[UIFont systemFontOfSize:size]; l.numberOfLines=0; return l; }
- (UIButton *)button:(CGRect)frame title:(NSString *)title action:(SEL)action { UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem]; b.frame=frame; [b setTitle:title forState:UIControlStateNormal]; [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal]; b.backgroundColor=[UIColor colorWithRed:.18 green:.32 blue:.62 alpha:1]; b.layer.cornerRadius=7; [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside]; return b; }
- (void)refresh {
    [gTraceButton setTitle:(DZIsTraceEnabled()?@"Trace: ON":@"Trace: OFF") forState:UIControlStateNormal];
    gStatus.text=[NSString stringWithFormat:@"Hooks: %lu   Events: %llu\nState: %@   Target: AnyThink/TopOn bridge",(unsigned long)DZHookCount(),(unsigned long long)DZEventCount(),DZIsTraceEnabled()?@"recording":@"paused"];
    gLastLabel.text=[@"  " stringByAppendingString:DZLastEvent()?:@"waiting for ad events"];
}
- (void)attach:(UIWindow *)w {
    if(!w)return;
    if(!gFloatButton){ gFloatButton=[UIButton buttonWithType:UIButtonTypeCustom]; gFloatButton.frame=CGRectMake(18,165,52,52); [gFloatButton setTitle:@"AD" forState:UIControlStateNormal]; gFloatButton.titleLabel.font=[UIFont boldSystemFontOfSize:16]; gFloatButton.backgroundColor=[UIColor colorWithRed:.12 green:.12 blue:.15 alpha:.94]; gFloatButton.layer.cornerRadius=26; [gFloatButton addTarget:self action:@selector(floatTapped:) forControlEvents:UIControlEventTouchUpInside]; [gFloatButton addGestureRecognizer:[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(floatPanned:)]]; }
    if(!gPanel){
        CGFloat width=MIN(350.0,MAX(300.0,w.bounds.size.width-30.0)); gPanel=[[UIView alloc]initWithFrame:CGRectMake(70,90,width,360)]; gPanel.backgroundColor=[UIColor colorWithRed:.055 green:.06 blue:.075 alpha:.97]; gPanel.layer.cornerRadius=14;
        UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panelPanned:)]; pan.cancelsTouchesInView=NO; [gPanel addGestureRecognizer:pan];
        UILabel *title=[self label:CGRectMake(14,10,width-28,40) font:16]; title.font=[UIFont boldSystemFontOfSize:16]; title.text=[NSString stringWithFormat:@"DumpZhuanYong AD Trace v%@",DZVersion]; [gPanel addSubview:title];
        gStatus=[self label:CGRectMake(14,52,width-28,62) font:11]; [gPanel addSubview:gStatus];
        gTraceButton=[self button:CGRectMake(14,122,98,38) title:@"Trace: ON" action:@selector(toggleTrace:)]; [gPanel addSubview:gTraceButton];
        [gPanel addSubview:[self button:CGRectMake(121,122,98,38) title:@"Rescan" action:@selector(rescan:)]];
        [gPanel addSubview:[self button:CGRectMake(228,122,MAX(58,width-242),38) title:@"Clear Log" action:@selector(clearLog:)]];
        UILabel *last=[self label:CGRectMake(14,171,width-28,22) font:11]; last.text=@"Last event"; last.textColor=[UIColor colorWithWhite:1 alpha:.65]; [gPanel addSubview:last];
        gLastLabel=[self label:CGRectMake(14,195,width-28,105) font:11]; gLastLabel.backgroundColor=[UIColor colorWithWhite:0 alpha:.18]; gLastLabel.layer.cornerRadius=8; gLastLabel.layer.masksToBounds=YES; [gPanel addSubview:gLastLabel];
        UILabel *path=[self label:CGRectMake(14,310,width-28,38) font:10]; path.textColor=[UIColor colorWithWhite:1 alpha:.55]; path.text=@"Log: Documents/DumpZhuanYong_AdTrace.jsonl\nRead-only diagnostics; no ad/reward mutation."; [gPanel addSubview:path]; gPanel.hidden=YES;
    }
    if(gFloatButton.superview!=w){[gFloatButton removeFromSuperview];[w addSubview:gFloatButton];} if(gPanel.superview!=w){[gPanel removeFromSuperview];[w addSubview:gPanel];} gWindow=w; [w bringSubviewToFront:gPanel]; [w bringSubviewToFront:gFloatButton]; [self refresh];
}
- (void)floatTapped:(id)sender { (void)sender; gPanel.hidden=!gPanel.hidden; if(!gPanel.hidden&&gWindow)[gWindow bringSubviewToFront:gPanel]; if(gWindow)[gWindow bringSubviewToFront:gFloatButton]; }
- (void)floatPanned:(UIPanGestureRecognizer *)g { if(!gFloatButton||!gWindow)return; CGPoint t=[g translationInView:gWindow],c=gFloatButton.center; c.x+=t.x;c.y+=t.y;CGFloat h=26;CGRect b=gWindow.bounds;c.x=MAX(h,MIN(b.size.width-h,c.x));c.y=MAX(h,MIN(b.size.height-h,c.y));gFloatButton.center=c;[g setTranslation:CGPointZero inView:gWindow]; }
- (void)panelPanned:(UIPanGestureRecognizer *)g { if(!gPanel||!gWindow)return; CGPoint t=[g translationInView:gWindow],c=gPanel.center;c.x+=t.x;c.y+=t.y;gPanel.center=c;[g setTranslation:CGPointZero inView:gWindow]; }
- (void)toggleTrace:(id)sender { (void)sender; DZSetTraceEnabled(!DZIsTraceEnabled()); [self refresh]; }
- (void)rescan:(id)sender { (void)sender; DZInstallKnownHooks(); [self refresh]; }
- (void)clearLog:(id)sender { (void)sender; DZClearLog(); [self refresh]; }
- (void)tick:(NSTimer *)timer { (void)timer; static NSUInteger n=0; UIWindow *w=DZActiveWindow(); if(w&&(w!=gWindow||!gFloatButton.superview||!gPanel.superview))[self attach:w]; if(++n%3==0)DZInstallKnownHooks(); if(w){[w bringSubviewToFront:gPanel];[w bringSubviewToFront:gFloatButton];}[self refresh]; }
@end

__attribute__((constructor)) static void DZAdTraceInit(void) {
    @autoreleasepool { dispatch_async(dispatch_get_main_queue(), ^{ DZInstallKnownHooks(); UIWindow *w=DZActiveWindow(); if(w)[[DZAdTraceCoordinator shared] attach:w]; [NSTimer scheduledTimerWithTimeInterval:.75 target:[DZAdTraceCoordinator shared] selector:@selector(tick:) userInfo:nil repeats:YES]; }); }
}
