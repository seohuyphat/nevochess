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

#import "GenericSettingViewController.h"
#import "Enums.h"
#import "QuartzUtils.h"

@implementation SettingViewController

@synthesize difficulty_setting;
@synthesize time_setting;
@synthesize piece_style;
@synthesize sound_switch;

- (void)viewDidLoad 
{
    self.view.backgroundColor = [UIColor colorWithCGColor:GetCGPatternNamed(@"board_320x480.png")];
    ((UITableView*)self.view).rowHeight = 60;
    
    // make right navigation bar button to default
    UIBarButtonItem *defaultButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Default", @"")
                                                                          style:UIBarButtonItemStylePlain 
                                                                         target:self 
                                                                         action:@selector(defaultSettingPressed:)];
    self.navigationItem.rightBarButtonItem = defaultButtonItem;
    [defaultButtonItem release];
    
    time_setting.minimumValue = 5.0f;
    time_setting.maximumValue = 90.0f;
    difficulty_setting.minimumValue = 1.0f;
    difficulty_setting.maximumValue = 10.0f;
    time_setting.value = (float)[[NSUserDefaults standardUserDefaults] integerForKey:@"time_setting"];
    difficulty_setting.value = (float)[[NSUserDefaults standardUserDefaults] integerForKey:@"difficulty_setting"];
    
    sound_switch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"toggle_sound"];
    [piece_style setTitle:NSLocalizedString(@"Chinese_Key", @"") forSegmentAtIndex:0];
    [piece_style setTitle:NSLocalizedString(@"Western_Key", @"") forSegmentAtIndex:1];
    BOOL toggleWestern = [[NSUserDefaults standardUserDefaults] boolForKey:@"toggle_western"];
    piece_style.selectedSegmentIndex = (toggleWestern ? 1 : 0);
    self.title = NSLocalizedString(@"General", @"");
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning 
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload 
{
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)viewWillDisappear:(BOOL)animated 
{
    //save the setting before we leave setting page
    [[NSUserDefaults standardUserDefaults] setInteger:[difficulty_setting value] forKey:@"difficulty_setting"];
    [[NSUserDefaults standardUserDefaults] setInteger:[time_setting value] forKey:@"time_setting"];
    [[NSUserDefaults standardUserDefaults] setBool:sound_switch.on forKey:@"toggle_sound"];
    BOOL bToggleWestern = ( piece_style.selectedSegmentIndex == 1 );
    [[NSUserDefaults standardUserDefaults] setBool:bToggleWestern forKey:@"toggle_western"];
	[super viewWillDisappear:animated];
}

- (void)dealloc 
{
    [time_setting release];
    [difficulty_setting release];
    [piece_style release];
    [sound_switch release];
    [super dealloc];
}

#pragma mark button event
- (IBAction)defaultSettingPressed:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setInteger:NC_AI_DIFFICULTY_DEFAULT forKey:@"difficulty_setting"];
    [[NSUserDefaults standardUserDefaults] setInteger:NC_GAME_TIME_DEFAULT forKey:@"time_setting"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"toggle_sound"];
    difficulty_setting.value = (float) NC_AI_DIFFICULTY_DEFAULT;
    time_setting.value = (float) NC_GAME_TIME_DEFAULT;
    sound_switch.on = YES;
    piece_style.selectedSegmentIndex = 0;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 3;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    switch (section) {
        case 0: return 1; //difficulty
        case 1: return 1; //time
        case 2: return 2; //others
    }
    return 0;
}


// Customize the appearance of table view cells.
enum MinMaxLabelEnum { // Tags for elements in a Table-Cell.
    LABEL_TAG_MIN = 10,  // Have to be non-zero!
    LABEL_TAG_MAX = 11
};
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    CGRect f;
    UILabel* minLabel = nil;
    UILabel* maxLabel = nil;    
    UITableViewCell* cell = nil;

    if (indexPath.section == 0 || indexPath.section == 1) // difficulty or time?
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"slide_setting"];
        if (!cell) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"slide_setting"] autorelease];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            minLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 30, 60, 21)] autorelease];
            minLabel.tag = LABEL_TAG_MIN;
            minLabel.opaque = NO;
            minLabel.font = [UIFont systemFontOfSize:14.0f];
            minLabel.textAlignment = UITextAlignmentLeft;
            minLabel.textColor = [UIColor blackColor];
            [cell.contentView addSubview:minLabel];
            maxLabel = [[[UILabel alloc] initWithFrame:CGRectMake(230, 30, 60, 21)] autorelease];
            maxLabel.tag = LABEL_TAG_MAX;
            maxLabel.opaque = NO;
            maxLabel.font = [UIFont systemFontOfSize:14.0f];
            maxLabel.textAlignment = UITextAlignmentRight;
            maxLabel.textColor = [UIColor blackColor];       
            [cell.contentView addSubview:maxLabel];
        } else {
            minLabel = (UILabel*)[cell.contentView viewWithTag:LABEL_TAG_MIN];
            maxLabel = (UILabel*)[cell.contentView viewWithTag:LABEL_TAG_MAX];
        }
    }

    switch (indexPath.section)
    {
        case 0: // difficulty
        {
            difficulty_setting.frame = CGRectMake(9.0, 9.0, 284, 23);
            [cell.contentView addSubview:difficulty_setting];
            minLabel.text = NSLocalizedString(@"Easy_Key", @"");
            maxLabel.text = NSLocalizedString(@"Hard_Key", @"");
            break;
        }
        case 1: // time
        {
            time_setting.frame = CGRectMake(9.0, 9.0, 284, 23);
            [cell.contentView addSubview:time_setting];
            minLabel.text = @"5";
            maxLabel.text = @"90";
            break;
        }
        case 2: // sound/pieces setting
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"generic_setting"];
            if(!cell) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"generic_setting"] autorelease];
                f = cell.frame;
                cell.frame = CGRectMake(f.origin.x, f.origin.y, 320, 58);
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            switch (indexPath.row) {
                case 0: //sound
                {
                    f = sound_switch.frame;
                    sound_switch.frame = CGRectMake(130, f.origin.y + 16, f.size.width, f.size.height);
                    cell.textLabel.text = NSLocalizedString(@"Sound_Key", @"");
                    [cell.contentView addSubview:sound_switch];
                    break;
                }
                case 1: //time setting
                {
                    f = piece_style.frame;
                    piece_style.frame = CGRectMake(120, f.origin.y + 8, f.size.width, f.size.height);
                    cell.textLabel.text = NSLocalizedString(@"PieceStyle_Key", @"");
                    [cell.contentView addSubview:piece_style];
                    break;
                }
            }
            break;
        }
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section) {
        case 0:
            return [NSString stringWithString:NSLocalizedString(@"Difficulty_Key", @"")];
        case 1:
            return [NSString stringWithString:NSLocalizedString(@"Time_Key", @"")];
        case 2:
            return [NSString stringWithString:NSLocalizedString(@"General", @"")];
    }
    return [NSString stringWithString:@"Undefined"];
}


@end
