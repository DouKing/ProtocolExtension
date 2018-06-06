//
//  main.m
//  opp
//
//  Created by DouKing on 2018/6/6.
//

#import <Foundation/Foundation.h>
#import "ProtocolExtension.h"

#pragma mark - Protocol

@protocol Eatable<NSObject>

@optional
+ (BOOL)canEat;
- (void)run;

@required
- (NSString *)eat;

@end

#pragma mark - Protocol Extension

@defs(Eatable)

+ (BOOL)canEat {
  return YES;
}

- (void)run {
  NSLog(@"I am running!");
}

- (NSString *)eat {
  return @"";
}

@end

@interface Person : NSObject<Eatable>

@end

@implementation Person

- (NSString *)eat {
  NSString *food = @"noodle";
  return food;
}

@end

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    Person *person = [[Person alloc] init];
    NSLog(@"person can eat? %@", [Person canEat] ? @"YES" : @"NO");
    NSLog(@"eat %@", [person eat]);
    [person run];
  }
  return 0;
}
