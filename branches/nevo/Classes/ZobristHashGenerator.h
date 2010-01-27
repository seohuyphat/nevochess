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

#import <Foundation/Foundation.h>

//
// Generate Zobrish Hash Value for indexing transitional table
//
@class RC4Generator;

@interface ZobristHashGenerator : NSObject {
    unsigned int dwKey;
    unsigned int dwLock0;
    unsigned int dwLock1;
}

@property(nonatomic) unsigned int dwKey;
@property(nonatomic) unsigned int dwLock0;
@property(nonatomic) unsigned int dwLock1;

- (void)initZero;
- (void)initRC4:(RC4Generator *)rc4;
- (void)Xor:(ZobristHashGenerator*)zobr;
- (void)Xor:(ZobristHashGenerator*)zobr1 zobr2:(ZobristHashGenerator*)zobr2;

@end

//
// RC4 key generator
//
@interface RC4Generator : NSObject {
    unsigned char s[256];
    int x, y;
    
}

- (void)initZero;
- (unsigned char)nextByte;
- (unsigned int)nextLong;

@end
