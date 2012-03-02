#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

#import "XCFixin.h"

static IMP gOriginalInsertScopeBar = nil;
static IMP gOriginalAdjustViewsForHeightOffset = nil;
static IMP gOriginalSetFinderMode = nil;
static IMP gOriginalViewDidInstall = nil;

@interface XCFixin_FindFix : NSObject
@end

@implementation XCFixin_FindFix

static void overrideInsertScopeBar(id self, SEL _cmd, id arg1, unsigned long long arg2, BOOL arg3)
{
    /* -(void)[DVTScopeBarsManager insertScopeBar:(id)arg1 atIndex:(unsigned long long)arg2 animate:(BOOL)arg3] */
    ((void (*)(id, SEL, id, unsigned long long, BOOL))gOriginalInsertScopeBar)(self, _cmd, arg1, arg2, NO);
}

static void overrideAdjustViewsForHeightOffset(id self, SEL _cmd, double arg1, BOOL arg2, id arg3)
{
    /* -(void)[DVTScopeBarsManager _adjustViewsForHeightOffset:(double)arg1 animate:(BOOL)arg2 extraAnimations:(id)arg3] */
    ((void (*)(id, SEL, double, BOOL, id))gOriginalAdjustViewsForHeightOffset)(self, _cmd, arg1, NO, nil);
}

static void overrideSetFinderMode(id self, SEL _cmd, unsigned long long arg1)
{
    /* -(void)[DVTFindBar setFinderMode:(unsigned long long)arg1] */
    
    if (!arg1 && [[self valueForKey: @"supportsReplace"] boolValue])
        arg1 = 1;
    
    ((void (*)(id, SEL, unsigned long long))gOriginalSetFinderMode)(self, _cmd, arg1);
}

static void overrideViewDidInstall(id self, SEL _cmd)
{
    /* -(void)[DVTFindBar viewDidInstall] */
    
    if ([[self valueForKey: @"supportsReplace"] boolValue])
    {
        [self setValue: [NSNumber numberWithUnsignedLongLong: 1] forKey: @"finderMode"];
        [self setValue: [NSNumber numberWithDouble: 45.0] forKey: @"preferredViewHeight"];
    }
    
    ((void (*)(id, SEL))gOriginalViewDidInstall)(self, _cmd);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.0), dispatch_get_main_queue(),
    ^{
        [self setValue: [NSNumber numberWithBool: YES] forKey: @"showsOptions"];
    });
}

+ (void)pluginDidLoad: (NSBundle *)plugin
{
    XCFixinPreflight();
    
    Class class = nil;
    Method originalMethod = nil;
    
    /* Override -(void)[DVTScopeBarsManager insertScopeBar:(id)arg1 atIndex:(unsigned long long)arg2 animate:(BOOL)arg3] */
    XCFixinAssertOrPerform(class = NSClassFromString(@"DVTScopeBarsManager"), goto failed);
    XCFixinAssertOrPerform(originalMethod = class_getInstanceMethod(class, @selector(insertScopeBar: atIndex: animate:)), goto failed);
    XCFixinAssertOrPerform(gOriginalInsertScopeBar = method_setImplementation(originalMethod, (IMP)&overrideInsertScopeBar), goto failed);
    
    /* Override -(void)[DVTScopeBarsManager _adjustViewsForHeightOffset:(double)arg1 animate:(BOOL)arg2 extraAnimations:(id)arg3] */
    XCFixinAssertOrPerform(class = NSClassFromString(@"DVTScopeBarsManager"), goto failed);
    XCFixinAssertOrPerform(originalMethod = class_getInstanceMethod(class, @selector(_adjustViewsForHeightOffset: animate: extraAnimations:)), goto failed);
    XCFixinAssertOrPerform(gOriginalAdjustViewsForHeightOffset = method_setImplementation(originalMethod, (IMP)&overrideAdjustViewsForHeightOffset), goto failed);
    
    /* Override -(void)[DVTFindBar setFinderMode:(unsigned long long)arg1] */
    XCFixinAssertOrPerform(class = NSClassFromString(@"DVTFindBar"), goto failed);
    XCFixinAssertOrPerform(originalMethod = class_getInstanceMethod(class, @selector(setFinderMode:)), goto failed);
    XCFixinAssertOrPerform(gOriginalSetFinderMode = method_setImplementation(originalMethod, (IMP)&overrideSetFinderMode), goto failed);
    
    /* Override -(void)[DVTFindBar viewDidInstall] */
    XCFixinAssertOrPerform(class = NSClassFromString(@"DVTFindBar"), goto failed);
    XCFixinAssertOrPerform(originalMethod = class_getInstanceMethod(class, @selector(viewDidInstall)), goto failed);
    XCFixinAssertOrPerform(gOriginalViewDidInstall = method_setImplementation(originalMethod, (IMP)&overrideViewDidInstall), goto failed);
    
    XCFixinPostflight();
}

@end