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

#import "ZobristHashGenerator.h"


@implementation ZobristHashGenerator
@synthesize dwKey;
@synthesize dwLock0;
@synthesize dwLock1;

- (void)dealloc
{
    [super dealloc];
}

- (id)init
{
    return [super init];
}

- (void)initZero
{
    dwKey = dwLock0 = dwLock1 = 0;   
}

- (void)initRC4:(RC4Generator *)rc4
{
    dwKey = [rc4 nextLong];
    dwLock0 = [rc4 nextLong];
    dwLock1 = [rc4 nextLong];
}

- (void)Xor:(ZobristHashGenerator*)zobr
{
    dwKey ^= zobr.dwKey;
    dwLock0 ^= zobr.dwLock0;
    dwLock1 ^= zobr.dwLock1;
}

- (void)Xor:(ZobristHashGenerator*)zobr1 zobr2:(ZobristHashGenerator*)zobr2
{
    dwKey ^= zobr1.dwKey ^ zobr2.dwKey;
    dwLock0 ^= zobr1.dwLock0 ^ zobr2.dwLock0;
    dwLock1 ^= zobr1.dwLock1 ^ zobr2.dwLock1;
}

@end

@implementation RC4Generator

- (void)dealloc
{
    [super dealloc];
}

- (id)init
{
    return [super init];
}

- (void)initZero
{
    int i, j;
    unsigned char uc;
    
    x = y = j = 0;
    for (i = 0; i < 256; i ++) {
        s[i] = i;
    }
    for (i = 0; i < 256; i ++) {
        j = (j + s[i]) & 255;
        uc = s[i];
        s[i] = s[j];
        s[j] = uc;
    }    
}

- (unsigned char)nextByte
{
    unsigned char uc;
    x = (x + 1) & 255;
    y = (y + s[x]) & 255;
    uc = s[x];
    s[x] = s[y];
    s[y] = uc;
    return s[(s[x] + s[y]) & 255];
}

- (unsigned int)nextLong
{
    unsigned char uc0, uc1, uc2, uc3;
    uc0 = [self nextByte];
    uc1 = [self nextByte];
    uc2 = [self nextByte];
    uc3 = [self nextByte];
    return (unsigned int)uc0 + ((unsigned int)uc1 << 8) + ((unsigned int)uc2 << 16) + ((unsigned int)uc3 << 24);   
}

@end
