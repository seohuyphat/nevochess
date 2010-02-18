/***************************************************************************
 *  Copyright 2009-2010 Nevo Hua  <nevo.hua@playxiangqi.com>               *
 *                                                                         * 
 *  This file is part of NevoChess.                                        *
 *                                                                         *
 *  NevoChess is free software: you can redistribute it and/or modify      *
 *  it under the terms of the GNU General Public License as published by   *
 *  the Free Software Foundation, either version 3 of the License, or      *
 *  (at your option) any later version.                                    *
 *                                                                         *
 *  NevoChess is distributed in the hope that it will be useful,           *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of         *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          *
 *  GNU General Public License for more details.                           *
 *                                                                         *
 *  You should have received a copy of the GNU General Public License      *
 *  along with NevoChess.  If not, see <http://www.gnu.org/licenses/>.     *
 ***************************************************************************/

#import "NevoChessAppDelegate.h"
#import "Enums.h"
#import "AIBoardViewController.h"

@implementation NevoChessAppDelegate

@synthesize window;
@synthesize navigationController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {    

    // Override point for customization after application launch
    //set default preferences
    int nDifficulty = [[NSUserDefaults standardUserDefaults] integerForKey:@"difficulty_setting"];
    if (nDifficulty < 1 || nDifficulty > 10) {
        [[NSUserDefaults standardUserDefaults] setInteger:NC_AI_DIFFICULTY_DEFAULT forKey:@"difficulty_setting"];
    }
    int nGameTime = [[NSUserDefaults standardUserDefaults] integerForKey:@"time_setting"];
    if (nGameTime < 5 || nGameTime > 90) {
        [[NSUserDefaults standardUserDefaults] setInteger:NC_GAME_TIME_DEFAULT forKey:@"time_setting"];
        //this might be the first time run
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"toggle_sound"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"toggle_western"];
        [[NSUserDefaults standardUserDefaults] setObject:@"XQWLight" forKey:@"AI"];
    }

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"network_autoConnect"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"network_autoConnect"];
    }

    [window addSubview:[navigationController view]];
    navigationController.navigationBarHidden = YES;
    [window makeKeyAndVisible];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    UIViewController *topController = [navigationController topViewController];
    if ([topController isKindOfClass:[AIBoardViewController class]]) {
        AIBoardViewController* chessController = (AIBoardViewController*)topController;
        [chessController saveGame];
    }
}

- (void)dealloc {
    [window release];
    [super dealloc];
}


@end
