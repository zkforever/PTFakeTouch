//
//  HJFakeMetaTouch.m
//  HJFakeTouch
//
//  Created by PugaTang on 16/4/20.
//  Copyright © 2016年 PugaTang. All rights reserved.
//

#import "PTFakeMetaTouch.h"
#import "UITouch-KIFAdditions.h"
#import "UIApplication-KIFAdditions.h"
#import "UIEvent+KIFAdditions.h"
static NSMutableArray *touchAry;
@implementation PTFakeMetaTouch

+ (void)load{
    KW_ENABLE_CATEGORY(UITouch_KIFAdditions);
    KW_ENABLE_CATEGORY(UIEvent_KIFAdditions);
    touchAry = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i<100; i++) {
        UITouch *touch = [[UITouch alloc] initTouch];
        [touch setPhaseAndUpdateTimestamp:UITouchPhaseEnded];
        [touchAry addObject:touch];
    }
}

+ (NSInteger)fakeTouchId:(NSInteger)pointId AtPoint:(CGPoint)point withTouchPhase:(UITouchPhase)phase{
    //DLog(@"4. fakeTouchId , phase : %ld ",(long)phase);
    if (pointId==0) {
        //随机一个没有使用的pointId
        pointId = [self getAvailablePointId];
        if (pointId==0) {
            DLog(@"PTFakeTouch ERROR! pointId all used");
            return 0;
        }
    }
    pointId = pointId - 1;
    UITouch *touch = [touchAry objectAtIndex:pointId];
    
    UIWindow *window = [[UIApplication sharedApplication].windows lastObject];
    if ([window isKindOfClass:NSClassFromString(@"UITextEffectsWindow")] && ![window isKindOfClass:NSClassFromString(@"UIRemoteKeyboardWindow")]) {
        DLog(@"class==%@",NSStringFromClass(window.class));
        window = [UIApplication sharedApplication].keyWindow;
    }else {
        UIView *keyboardView = [PTFakeMetaTouch findKeyboard];
        if ([window isKindOfClass:NSClassFromString(@"UIRemoteKeyboardWindow")] && keyboardView) {
            if (point.y < window.bounds.size.height - keyboardView.bounds.size.height) {
                DLog(@"click view");
                window = [UIApplication sharedApplication].keyWindow;
            }
        }else if ([window isKindOfClass:NSClassFromString(@"UIRemoteKeyboardWindow")] && keyboardView == nil) {
            window = [UIApplication sharedApplication].keyWindow;
        }
    }
    DLog(@"window class==%@",NSStringFromClass(window.class));
    if (phase == UITouchPhaseBegan) {
        touch = nil;
        touch = [[UITouch alloc] initAtPoint:point inWindow:window];
        [touchAry replaceObjectAtIndex:pointId withObject:touch];
        [touch setLocationInWindow:point];
    }else{
        [touch setLocationInWindow:point];
        [touch setPhaseAndUpdateTimestamp:phase];
    }
    
    
    
//    UIEvent *event = [self eventWithTouches:touchAry];
    UIEvent *event = [self eventWithTouches:touchAry andPointId:pointId];
    [[UIApplication sharedApplication] sendEvent:event];
    if ((touch.phase==UITouchPhaseBegan)||touch.phase==UITouchPhaseMoved) {
        [touch setPhaseAndUpdateTimestamp:UITouchPhaseStationary];
    }
    return (pointId+1);
}


+ (UIView *)findKeyboard
{
    UIView *keyboardView = nil;
    NSArray *windows = [[UIApplication sharedApplication] windows];
    for (UIWindow *window in [windows reverseObjectEnumerator])//逆序效率更高，因为键盘总在上方
    {
        keyboardView = [PTFakeMetaTouch findKeyboardInView:window];
        if (keyboardView)
        {
            return keyboardView;
        }
    }
    return nil;
}

+ (UIView *)findKeyboardInView:(UIView *)view
{
    for (UIView *subView in [view subviews])
    {
        if (strstr(object_getClassName(subView), "UIKeyboard"))
        {
            return subView;
        }
        else
        {
            UIView *tempView = [PTFakeMetaTouch findKeyboardInView:subView];
            if (tempView)
            {
                return tempView;
            }
        }
    }
    return nil;
}

+ (UIEvent *)eventWithTouches:(NSArray *)touches andPointId:(NSInteger)pointId {
    UIEvent *event = [[UIApplication sharedApplication] _touchesEvent];
    [event _clearTouches];
    UITouch *touch = [touches objectAtIndex:pointId];
    NSArray *usefulTouchs = [NSArray arrayWithObject:touch];
    [event kif_setEventWithTouches:usefulTouchs];
    for (UITouch *aTouch in usefulTouchs) {
        [event _addTouch:aTouch forDelayedDelivery:NO];
    }
    return event;
}


+ (UIEvent *)eventWithTouches:(NSArray *)touches
{
    // _touchesEvent is a private selector, interface is exposed in UIApplication(KIFAdditionsPrivate)
    UIEvent *event = [[UIApplication sharedApplication] _touchesEvent];
    [event _clearTouches];
    [event kif_setEventWithTouches:touches];
    for (UITouch *aTouch in touches) {
        [event _addTouch:aTouch forDelayedDelivery:NO];
    }
    
    return event;
}

+ (NSInteger)getAvailablePointId{
    NSInteger availablePointId=0;
    NSMutableArray *availableIds = [[NSMutableArray alloc]init];
    for (NSInteger i=0; i<touchAry.count-50; i++) {
        UITouch *touch = [touchAry objectAtIndex:i];
        if (touch.phase==UITouchPhaseEnded||touch.phase==UITouchPhaseStationary) {
            [availableIds addObject:@(i+1)];
        }
    }
    availablePointId = availableIds.count==0 ? 0 : [[availableIds objectAtIndex:(arc4random() % availableIds.count)] integerValue];
    return availablePointId;
}
@end
