#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

#import "XCFixin.h"

static IMP gOriginalInitWithDuration = nil;
static IMP gOriginalSetDuration = nil;

@interface XCFixin_DisableAnimations : NSObject
@end

@implementation XCFixin_DisableAnimations

static void overrideInitWithDuration(id self, SEL _cmd, NSTimeInterval arg1, NSAnimationCurve arg2)
{
    /* -[NSAnimation initWithDuration:(NSTimeInterval)duration animationCurve:(NSAnimationCurve)animationCurve] */
    ((void (*)(id, SEL, NSTimeInterval, NSAnimationCurve))gOriginalInitWithDuration)(self, _cmd, 0.0, arg2);
}

static void overrideSetDuration(id self, SEL _cmd, NSTimeInterval arg1)
{
    /* -[NSAnimation setDuration:(NSTimeInterval)duration] */
    ((void (*)(id, SEL, NSTimeInterval))gOriginalSetDuration)(self, _cmd, 0.0);
}

+ (void)pluginDidLoad: (NSBundle *)plugin
{
    XCFixinPreflight();
    
    Class class = nil;
    Method originalMethod = nil;
    
    /* Override -[NSAnimation initWithDuration:(NSTimeInterval)duration animationCurve:(NSAnimationCurve)animationCurve] */
    XCFixinAssertOrPerform(class = NSClassFromString(@"NSAnimation"), goto failed);
    XCFixinAssertOrPerform(originalMethod = class_getInstanceMethod(class, @selector(initWithDuration: animationCurve:)), goto failed);
    XCFixinAssertOrPerform(gOriginalInitWithDuration = method_setImplementation(originalMethod, (IMP)&overrideInitWithDuration), goto failed);
    
    /* Override -[NSAnimation setDuration:(NSTimeInterval)duration] */
    XCFixinAssertOrPerform(class = NSClassFromString(@"NSAnimation"), goto failed);
    XCFixinAssertOrPerform(originalMethod = class_getInstanceMethod(class, @selector(setDuration:)), goto failed);
    XCFixinAssertOrPerform(gOriginalSetDuration = method_setImplementation(originalMethod, (IMP)&overrideSetDuration), goto failed);
    
    XCFixinPostflight();
}

@end