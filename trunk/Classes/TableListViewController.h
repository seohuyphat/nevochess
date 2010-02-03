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

@interface TimeInfo : NSObject
{
    int  gameTime;  // Game-time (in seconds).
    int  moveTime;  // Move-time (in seconds).
    int  freeTime;  // Free-time (in seconds).
}

@property (nonatomic) int gameTime;
@property (nonatomic) int moveTime;
@property (nonatomic) int freeTime;

- (id)initWithTime:(TimeInfo*)other;
+ (id)allocTimeFromString:(NSString *)timeContent;

@end

@interface TableInfo : NSObject
{
    NSString* tableId;
    BOOL      rated;
    NSString* itimes;   // Initial times.
    NSString* redTimes;
    NSString* blackTimes;
    NSString* redId;
    NSString* redRating;
    NSString* blackId;
    NSString* blackRating;
}

@property (nonatomic, retain) NSString* tableId;
@property (nonatomic)         BOOL rated;
@property (nonatomic, retain) NSString* itimes;
@property (nonatomic, retain) NSString* redTimes;
@property (nonatomic, retain) NSString* blackTimes;
@property (nonatomic, retain) NSString* redId;
@property (nonatomic, retain) NSString* redRating;
@property (nonatomic, retain) NSString* blackId;
@property (nonatomic, retain) NSString* blackRating;

+ (id)allocTableFromString:(NSString *)tableContent;

@end

// --------------------------------------
@protocol TableListDelegate <NSObject>
- (void) handeNewFromList;
- (void) handeRefreshFromList;
- (void) handeTableJoin:(TableInfo *)table color:(NSString*)joinColor;
@end

// --------------------------------------
@interface TableListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
    UIBarButtonItem*      addButton;
    IBOutlet UITableView* listView;

    NSMutableArray* _tables;
    id <TableListDelegate> delegate;
}

@property (nonatomic, retain) IBOutlet UIBarButtonItem* addButton;
@property (nonatomic, retain) IBOutlet UITableView* listView;
@property (nonatomic, retain) id <TableListDelegate> delegate;

- (IBAction) refreshButtonPressed:(id)sender;

- (id)initWithList:(NSString *)tablesStr;
- (void)reinitWithList:(NSString *)tablesStr;

@end
