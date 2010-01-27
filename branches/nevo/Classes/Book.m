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

#import "Book.h"

@implementation Book

@synthesize BookTable;
@synthesize nBookSize;

- (void)dealloc
{
    free(BookTable);
    [super dealloc];
}

- (void)loadBook:(NSString*)bookfile
{
    NSString *path;
    NSData *bookdata;
    path = [[NSBundle mainBundle] pathForResource:bookfile ofType:nil inDirectory:@"books/xqwlight"];
    NSFileHandle *f = [NSFileHandle fileHandleForReadingAtPath:path];
    bookdata = [f readDataToEndOfFile];
    char *bytes = (char*)[bookdata bytes];
    BookTable = (BookItem*)malloc(BOOK_SIZE * sizeof(BookItem));
    bzero(BookTable, sizeof(BookItem) * BOOK_SIZE);
    nBookSize = [bookdata length] / sizeof(BookItem);
    if (nBookSize > BOOK_SIZE) {
        nBookSize = BOOK_SIZE;
    }
    memcpy(BookTable, bytes,nBookSize * sizeof(BookItem));   
}

- (id)initWithBook:(NSString*)bookfile
{
    self = [super init];
    [self loadBook:bookfile];
    return self;
}


@end
