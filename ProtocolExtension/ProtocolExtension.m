//
//  ProtocolExtensition.m
//  opp
//
//  Created by DouKing on 2018/6/6.
//  Copyright © 2018年 DouKing. All rights reserved.
//

#import "ProtocolExtension.h"
#import <objc/runtime.h>
#import <pthread/pthread.h>

#define _pex_get_first_container_class($protocol) _pex_get_container_class_imp($protocol, 0)

static NSMutableDictionary<NSString *, NSMutableArray<Class> *> *ext_protocol;
static pthread_mutex_t protocolsLoadingLock = PTHREAD_MUTEX_INITIALIZER;

void _pex_extension_load(Protocol *protocol, Class cls) {
  pthread_mutex_lock(&protocolsLoadingLock);

  if (!ext_protocol) {
    ext_protocol = [NSMutableDictionary dictionary];
  }
  NSString *protocolName = NSStringFromProtocol(protocol);
  NSMutableArray<Class> *clses = ext_protocol[protocolName];
  if (!clses) {
    clses = [NSMutableArray array];
  }
  [clses addObject:cls];
  ext_protocol[protocolName] = clses;

  pthread_mutex_unlock(&protocolsLoadingLock);
}

#pragma mark -
#pragma mark -

static inline void PEXSwizzMethod(Class aClass, SEL originSelector, SEL swizzSelector) {
  Method systemMethod = class_getInstanceMethod(aClass, originSelector);
  Method swizzMethod = class_getInstanceMethod(aClass, swizzSelector);
  BOOL isAdd = class_addMethod(aClass,
                               originSelector,
                               method_getImplementation(swizzMethod),
                               method_getTypeEncoding(swizzMethod));
  if (isAdd) {
    class_replaceMethod(aClass,
                        swizzSelector,
                        method_getImplementation(systemMethod),
                        method_getTypeEncoding(systemMethod));
  } else {
    method_exchangeImplementations(systemMethod, swizzMethod);
  }
}

@implementation NSObject (Forward)

+ (void)load {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    PEXSwizzMethod(self, @selector(forwardingTargetForSelector:), @selector(pex_forwardingTargetForSelector:));
    PEXSwizzMethod(object_getClass(self), @selector(forwardingTargetForSelector:), @selector(pex_forwardingTargetForSelector:));
  });
}

+ (id)pex_forwardingTargetForSelector:(SEL)aSelector {
  unsigned int count;
  __unsafe_unretained Protocol **protocols = class_copyProtocolList(self, &count);
  for (unsigned int i = 0; i < count; i++) {
    const char *name = protocol_getName(protocols[i]);
    NSString *protocolName = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];

    NSArray<Class> *clses = ext_protocol[protocolName];
    if (!clses.count) {
      continue;
    }

    for (Class cls in clses) {
      if ([cls respondsToSelector:aSelector]) {
        return cls;
      }
    }
  }

  return [self pex_forwardingTargetForSelector:aSelector];
}

- (id)pex_forwardingTargetForSelector:(SEL)aSelector {
  unsigned int count;
  __unsafe_unretained Protocol **protocols = class_copyProtocolList([self class], &count);
  for (unsigned int i = 0; i < count; i++) {
    const char *name = protocol_getName(protocols[i]);
    NSString *protocolName = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
    NSArray<Class> *clses = ext_protocol[protocolName];
    if (!clses.count) {
      continue;
    }

    for (Class cls in clses) {
      id target = [[cls alloc] init];
      if ([target respondsToSelector:aSelector]) {
        return target;
      }
    }
  }

  return [self pex_forwardingTargetForSelector:aSelector];
}

@end

