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

@interface TableInfo : NSObject
{
    NSString* tableId;
    NSString* redId;
    NSString* redRating;
    NSString* blackId;
    NSString* blackRating;
}

@property (nonatomic, retain) NSString* tableId;
@property (nonatomic, retain) NSString* redId;
@property (nonatomic, retain) NSString* redRating;
@property (nonatomic, retain) NSString* blackId;
@property (nonatomic, retain) NSString* blackRating;

@end

// --------------------------------------
@protocol TableListDelegate <NSObject>
- (void) handeTableJoin:(TableInfo *)table color:(NSString*)joinColor;
@end

// --------------------------------------
@interface TableListViewController : UITableViewController
{
    NSMutableArray* _tables;
    id <TableListDelegate> delegate;
}

@property (nonatomic, retain) id <TableListDelegate> delegate;

- (id)initWithList:(NSString *)tablesStr;

@end
