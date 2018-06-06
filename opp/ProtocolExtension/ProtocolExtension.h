//
//  ProtocolExtensition.h
//  opp
//
//  Created by DouKing on 2018/6/6.
//  Copyright © 2018年 DouKing. All rights reserved.
//

#import <Foundation/Foundation.h>

#define defs _pex_extension

// Interface
#define _pex_extension($protocol) _pex_extension_imp($protocol, _pex_get_container_class($protocol))

// Implementation
#define _pex_extension_imp($protocol, $container_class) \
        protocol $protocol; \
        @interface $container_class : NSObject <$protocol> @end \
        @implementation $container_class \
        + (void)load { \
            _pex_extension_load(@protocol($protocol), $container_class.class); \
        } \

// Get container class name by counter
#define _pex_get_container_class($protocol) _pex_get_container_class_imp($protocol, __COUNTER__)
#define _pex_get_container_class_imp($protocol, $counter) _pex_get_container_class_imp_concat(__PKContainer_, $protocol, $counter)
#define _pex_get_container_class_imp_concat($a, $b, $c) $a ## $b ## _ ## $c

void _pex_extension_load(Protocol *protocol, Class cls);
