//
//  Created by Akos Polster on 26/05/15.
//  Copyright (c) 2015 Akos Polster. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Persistent menu data model.
@interface Menu : NSObject

/// Singleton instance
+ (Menu *)instance;

/// All menu items
@property (nonatomic, strong) NSArray *allMenus;

/// Today's menu
- (NSDictionary *)todaysMenu;

@end
