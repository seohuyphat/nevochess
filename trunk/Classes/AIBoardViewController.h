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


#import "BoardViewController.h"
#import "AIEngine.h"

@interface AIBoardViewController : BoardViewController
{
    NSString*       _aiName;
    AIEngine*       _aiEngine;

    NSThread*     robot;
    NSPort*      _robotPort; // the port is used to instruct the robot to do works
    CFRunLoopRef _robotLoop; // the loop robot is on, used to control its lifecycle
}

- (IBAction)homePressed:(id)sender;
- (IBAction)resetPressed:(id)sender;

- (void) handleNewMove:(NSNumber *)pMove;
- (void) onLocalMoveMade:(int)move;
- (void) saveGame;
- (void) resetBoard;

@end
