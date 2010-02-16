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
#import "NevoChessAppDelegate.h"

@implementation SettingViewController

@synthesize difficulty_setting;
@synthesize time_setting;
@synthesize default_setting;
@synthesize piece_style;
@synthesize sound_switch;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
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


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

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

- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
    [((NevoChessAppDelegate*)[[UIApplication sharedApplication] delegate]).navigationController setNavigationBarHidden:NO animated:YES];
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
    [default_setting release];
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
        case 0:
            //difficulty
            return 1;
            break;
        case 1:
            //time
            return 1;
            break;
        case 2:
            //others
            return 2;
            break;
    }
    return 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    CGRect f;
    UILabel *_min;
    UILabel *_max;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"slide_setting"];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"slide_setting"] autorelease];
        _min = [[[UILabel alloc] initWithFrame:CGRectMake(10, 26, 60, 21)] autorelease];
        _min.tag = 10;
        _min.opaque = NO;
        _min.font = [UIFont systemFontOfSize:16.0f];
        _min.textAlignment = UITextAlignmentLeft;
        _min.textColor = [UIColor blackColor];
        //_min.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
        _max = [[[UILabel alloc] initWithFrame:CGRectMake(240, 26, 60, 21)] autorelease];
        _max.tag = 11;
        _max.opaque = NO;
        _max.font = [UIFont systemFontOfSize:16.0f];
        _max.textAlignment = UITextAlignmentLeft;
        _max.textColor = [UIColor blackColor];
        //_max.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;       

        [cell.contentView addSubview:_min];
        [cell.contentView addSubview:_max];
    }
    switch (indexPath.section) {
        case 0:
            // difficulty
            difficulty_setting.frame = CGRectMake(9.0, 9.0, 284, 23);
            [cell.contentView addSubview:difficulty_setting];
            _min = (UILabel*)[cell.contentView viewWithTag:10];
            _max = (UILabel*)[cell.contentView viewWithTag:11];
            _min.text = NSLocalizedString(@"Easy_Key", @"");
            _max.text = NSLocalizedString(@"Hard_Key", @"");
            return cell;
            break;
        case 1:
            // time
            _min = (UILabel*)[cell.contentView viewWithTag:10];
            _max = (UILabel*)[cell.contentView viewWithTag:11];
            time_setting.frame = CGRectMake(9.0, 9.0, 284, 23);
            _max.frame = CGRectMake(270, 26, 30, 21);
            [cell.contentView addSubview:time_setting];
            _min.text = @"5";
            _max.text = @"90";
            return cell;
            break;
        case 2:
            // sound/pieces setting
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"generic_setting"];
            if(!cell) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"generic_setting"] autorelease];
                f = cell.frame;
                cell.frame = CGRectMake(f.origin.x, f.origin.y, 320, 58);
            }
            switch (indexPath.row) {
                case 0:
                    //sound
                    f = sound_switch.frame;
                    sound_switch.frame = CGRectMake(130, f.origin.y + 16, f.size.width, f.size.height);
                    cell.textLabel.text = NSLocalizedString(@"Sound_Key", @"");
                    [cell.contentView addSubview:sound_switch];
                    break;
                case 1:
                    //time setting
                    f = piece_style.frame;
                    piece_style.frame = CGRectMake(120, f.origin.y + 8, f.size.width, f.size.height);
                    cell.textLabel.text = NSLocalizedString(@"PieceStyle_Key", @"");
                    [cell.contentView addSubview:piece_style];
                    break;
            }
            return cell;
            
        }
            break;

    }
    return nil;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section) {
        case 0:
            return [NSString stringWithString:NSLocalizedString(@"Difficulty_Key", @"")];
            break;
        case 1:
            return [NSString stringWithString:NSLocalizedString(@"Time_Key", @"")];
            break;
        case 2:
            return [NSString stringWithString:NSLocalizedString(@"General", @"")];
            break;
    }
    return [NSString stringWithString:@"Undefined"];
}


@end
