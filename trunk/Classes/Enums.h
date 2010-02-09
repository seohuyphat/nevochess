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

/*
 *  Enums.h
 *  Created by Huy Phan on 9/27/09.
 *
 *  Containing the common constants that are used throughout the project.
 */

///////////////////////////////////////////////////////////////////////////////
//
//    Common constants
//
///////////////////////////////////////////////////////////////////////////////

#define POC_AI_DIFFICULTY_DEFAULT 5     /* Valid range [1, 10]                */
#define POC_GAME_TIME_DEFAULT     30    /* Game time (in minutes)             */
#define POC_MAX_MOVES_PER_GAME    200   /* Maximum number of moves per game   */

#define NC_GUEST_PREFIX           @"Guest#"

///////////////////////////////////////////////////////////////////////////////
//
//    Common Enums
//
///////////////////////////////////////////////////////////////////////////////

/**
 * Color for both Piece and Role.
 */
typedef enum
{
    NC_COLOR_UNKNOWN = -1,
        // This type indicates the absense of color or role.
        // For example, it is used to indicate the player is not even
        // at the table.

    NC_COLOR_RED,   // RED color.
    NC_COLOR_BLACK, // BLACK color.

    NC_COLOR_NONE
        // NOTE: This type actually does not make sense for 'Piece',
        //       only for "Player". It is used to indicate the role of a player
        //       who is currently only observing the game, not playing.

} ColorEnum;


////////////////////// END OF FILE ////////////////////////////////////////////
