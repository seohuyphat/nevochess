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

#import "Types.h"


///////////////////////////////////////////////////////////////////////////////
//
//    BoardActionSheet
//
//////////////////////////////////////////////////////////////////////////////
@implementation BoardActionSheet

- (void) _clearAllIndices
{
    closeIndex  = -1;
    resignIndex = -1;
    drawIndex   = -1;
    resetIndex  = -1;
    logoutIndex = -1;
    cancelIndex = -1;
}

- (id)initWithTableState:(NSString *)state delegate:(id<UIActionSheetDelegate>)delegate
                   title:(NSString*)title
{
    [self _clearAllIndices];
    
    if ([state isEqualToString:@"play"]) {
        resignIndex = 0;
        drawIndex = 1;
        cancelIndex = 2;
        self = [super initWithTitle:title delegate:delegate
                  cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
             destructiveButtonTitle:NSLocalizedString(@"Resign", @"")
                  otherButtonTitles:NSLocalizedString(@"Draw", @""), nil];
    }
    else if ([state isEqualToString:@"ended"]) {
        closeIndex = 0;
        resetIndex = 1;
        cancelIndex = 2;
        self = [super initWithTitle:title delegate:delegate
                  cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
             destructiveButtonTitle:NSLocalizedString(@"Close Table", @"")
                  otherButtonTitles:NSLocalizedString(@"Reset Table", @""), nil];
    }
    else if ([state isEqualToString:@"view"] || [state isEqualToString:@"ready"]) {
        closeIndex = 0;
        cancelIndex = 1;
        self = [super initWithTitle:title delegate:delegate
                  cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
             destructiveButtonTitle:NSLocalizedString(@"Close Table", @"")
                  otherButtonTitles:nil];
    }
    else if ([state isEqualToString:@"logout"]) {
        logoutIndex = 0;
        cancelIndex = 1;
        self = [super initWithTitle:title delegate:delegate
                  cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
             destructiveButtonTitle:NSLocalizedString(@"Logout", @"")
                  otherButtonTitles:nil];
    }
    else {
        cancelIndex = 0;
        self = [super initWithTitle:title delegate:delegate
                  cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
             destructiveButtonTitle:nil
                  otherButtonTitles:nil];
    }
    
    self.actionSheetStyle = UIActionSheetStyleAutomatic;
    return self;
}

- (NSInteger) valueOfClickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == closeIndex) { return ACTION_INDEX_CLOSE; }
    if (buttonIndex == resignIndex) { return ACTION_INDEX_RESIGN; }
    if (buttonIndex == drawIndex) { return ACTION_INDEX_DRAW; }
    if (buttonIndex == resetIndex) { return ACTION_INDEX_RESET; }
    if (buttonIndex == logoutIndex) { return ACTION_INDEX_LOGOUT; }
    return ACTION_INDEX_CANCEL;
}

@end