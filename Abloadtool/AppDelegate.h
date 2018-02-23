//
//  AppDelegate.h
//  Abloadtool
//
//  Created by Andreas Kreisl on 05.10.17.
//  Copyright © 2017 Andreas Kreisl. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NetworkManager.h"
#import "AT_TabBarController.h"


@interface AppDelegate : UIResponder <UIApplicationDelegate>
    @property (nonatomic) UIWindow *window;
    @property AT_TabBarController *tabBar;
@end
