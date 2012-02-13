#import <UIKit/UIKit.h>
#import <SpringBoard/SpringBoard.h>
#import <notify.h>
#import <libactivator/libactivator.h>

%config(generator=internal);

#define kLeft "jp.r-plus.leftshiftcaret"
#define kRight "jp.r-plus.rightshiftcaret"

static UIView *tv = nil;
static BOOL isActive;

@interface UIView (Private) <UITextInput>
@end

@interface ActiShiftCaret : NSObject <LAListener>
@end

static void ShiftCaret(BOOL isLeftSwipe)
{
  UITextPosition *position;
  if ([tv respondsToSelector:@selector(positionFromPosition:inDirection:offset:)])
    position = isLeftSwipe ? [tv positionFromPosition:tv.selectedTextRange.start inDirection:UITextLayoutDirectionLeft offset:1]
      : [tv positionFromPosition:tv.selectedTextRange.end inDirection:UITextLayoutDirectionRight offset:1];
  // failsafe for over edge position crash.
  if (!position)
    return;
  UITextRange *range = [tv textRangeFromPosition:position toPosition:position];
  [tv setSelectedTextRange:range];
}

static void LeftShiftCaretNotificationReceived(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
  if (tv)
    ShiftCaret(YES);
}

static void RightShiftCaretNotificationReceived(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
  if (tv)
    ShiftCaret(NO);
}

static void WillEnterForegroundNotificationReceived(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
  if (!isActive) {
    isActive = YES;
    CFNotificationCenterRef darwin = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(darwin, LeftShiftCaretNotificationReceived, LeftShiftCaretNotificationReceived, CFSTR(kLeft), NULL, CFNotificationSuspensionBehaviorCoalesce);
    CFNotificationCenterAddObserver(darwin, RightShiftCaretNotificationReceived, RightShiftCaretNotificationReceived, CFSTR(kRight), NULL, CFNotificationSuspensionBehaviorCoalesce);
  }
}

static void DidEnterBackgroundNotificationReceived(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
  if (isActive) {
    isActive = NO;
    CFNotificationCenterRef darwin = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterRemoveObserver(darwin, LeftShiftCaretNotificationReceived, CFSTR(kLeft), NULL);
    CFNotificationCenterRemoveObserver(darwin, RightShiftCaretNotificationReceived, CFSTR(kRight), NULL);
  }
}

%hook UIView
- (BOOL)becomeFirstResponder
{
  if ([self respondsToSelector:@selector(setSelectedTextRange:)])
    tv = self;
  return %orig;
}
%end

@implementation ActiShiftCaret
+ (void)load
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  if (LASharedActivator.runningInsideSpringBoard) {
    ActiShiftCaret *shiftcaret = [[self alloc] init];
    if (![LASharedActivator hasSeenListenerWithName:@kLeft])
      [LASharedActivator assignEvent:[LAEvent eventWithName:LAEventNameVolumeUpPress mode:LAEventModeApplication] toListenerWithName:@kLeft];
    if (![LASharedActivator hasSeenListenerWithName:@kRight])
      [LASharedActivator assignEvent:[LAEvent eventWithName:LAEventNameVolumeDownPress mode:LAEventModeApplication] toListenerWithName:@kRight];
    [LASharedActivator registerListener:shiftcaret forName:@kLeft];
    [LASharedActivator registerListener:shiftcaret forName:@kRight];
    WillEnterForegroundNotificationReceived(nil, nil, nil, nil, nil);
  } else {
    CFNotificationCenterRef local = CFNotificationCenterGetLocalCenter();
    CFNotificationCenterAddObserver(local, WillEnterForegroundNotificationReceived, WillEnterForegroundNotificationReceived, (CFStringRef)UIApplicationDidFinishLaunchingNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
    CFNotificationCenterAddObserver(local, WillEnterForegroundNotificationReceived, WillEnterForegroundNotificationReceived, (CFStringRef)UIApplicationWillEnterForegroundNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
    CFNotificationCenterAddObserver(local, DidEnterBackgroundNotificationReceived, DidEnterBackgroundNotificationReceived, (CFStringRef)UIApplicationDidEnterBackgroundNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
  }
  [pool drain];
}

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event forListenerName:(NSString *)listenerName
{
  //if ([(SpringBoard *)UIApp _accessibilityFrontMostApplication]) {
    if ([listenerName isEqualToString:@kLeft])
      notify_post(kLeft);
    else
      notify_post(kRight);

    event.handled = YES;
  //}
}
@end
