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

#define NC_SETTINGS_VERSION      1     /* The Settings version               */
#define NC_AI_DIFFICULTY_DEFAULT 1     /* Valid range [0, 3]                 */
#define NC_MAX_MOVES_PER_GAME    200   /* Maximum number of moves per game   */

#define NC_SOUND_PATH            @"sounds/xqwizard-wave"

#define NC_TABLE_ANIMATION_DURATION 1.0 /* Table switching duration (sec)    */

///////////////////////////////////////////////////////////////////////////////
//
//    Network (PlayXiangqi server) constants
//
///////////////////////////////////////////////////////////////////////////////

#define NC_SERVER_IP              @"games.playxiangqi.com"
#define NC_SERVER_PORT            80
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

/**
 * Game's status.
 */
typedef enum 
{
    NC_GAME_STATUS_UNKNOWN = -1,

    NC_GAME_STATUS_IN_PROGRESS,
    NC_GAME_STATUS_RED_WIN,        // Game Over. Red won.
    NC_GAME_STATUS_BLACK_WIN,      // Game Over. Black won.
    NC_GAME_STATUS_DRAWN,          // Game Over. Drawn.
    NC_GAME_STATUS_TOO_MANY_MOVES  // Game Over. Too many moves.
} GameStatusEnum;

/**
 * Piece's Type.
 *
 *  King (K), Advisor (A), Elephant (E), chaRiot (R), Horse (H), 
 *  Cannons (C), Pawns (P).
 */
typedef enum
{
    NC_PIECE_INVALID = 0,
    NC_PIECE_KING,                 // King (or General)
    NC_PIECE_ADVISOR,              // Advisor (or Guard, or Mandarin)
    NC_PIECE_ELEPHANT,             // Elephant (or Ministers)
    NC_PIECE_CHARIOT,              // Chariot ( Rook, or Car)
    NC_PIECE_HORSE,                // Horse ( Knight )
    NC_PIECE_CANNON,               // Canon
    NC_PIECE_PAWN                  // Pawn (or Soldier)
} PieceEnum;

/**
 * Possible AI engines.
 */
typedef enum
{
    NC_AI_XQWLight,
    NC_AI_HaQiKiD,
    NC_AI_XQWLight_ObjC
} AIEnum;

/**
 * Highlight states of a Piece/Cell.
 */
typedef enum
{
    // !!!! *** DO NOT CHANGE THE NUMERIC VALUES  ***!!! //
    NC_HL_NONE     = 0,   // No highlight at all
    NC_HL_NORMAL   = 1,   // Normal highlight 
    NC_HL_ANIMATED = 2,   // Highlight after a piece has moved
    NC_HL_CHECKED  = 3    // Highlight while a King is checked (or threatened)
} HighlightEnum;

///////////////////////////////////////////////////////////////////////////////
//
//    Common Macros
//
///////////////////////////////////////////////////////////////////////////////

#define INVALID_MOVE         (-1)
#define TOSQUARE(row, col)   (16 * ((row) + 3) + ((col) + 3))
#define COLUMN(sq)           ((sq) % 16 - 3)
#define ROW(sq)              ((sq) / 16 - 3)

#define SRC(mv)              ((mv) & 255)
#define DST(mv)              ((mv) >> 8)
#define MOVE(sqSrc, sqDst)   ((sqSrc) + (sqDst) * 256)

////////////////////// END OF FILE ////////////////////////////////////////////
