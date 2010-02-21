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

#import <UIKit/UIKit.h>
#import "SingleSelectionController.h"

@interface OptionsViewController : UITableViewController <SingleSelectionDelegate>
{
    IBOutlet UITableViewCell* _soundCell;
    IBOutlet UISwitch*        _soundSwitch;

    UITableViewCell*   _pieceCell;
    UITableViewCell*   _boardCell;
    UITableViewCell*   _aiLevelCell;
    UITableViewCell*   _aiTypeCell;

    // --- Piece Style.
    NSArray*           _pieceChoices;
    NSUInteger         _pieceType;

    // --- Board Style.
    NSArray*           _boardChoices;
    NSUInteger         _boardType;

    // --- AI Level and Type.
    NSArray*           _aiLevelChoices;
    NSUInteger         _aiLevel;

    NSArray*           _aiTypeChoices;
    NSUInteger         _aiType;
}

- (IBAction) autoConnectValueChanged:(id)sender;

@end
