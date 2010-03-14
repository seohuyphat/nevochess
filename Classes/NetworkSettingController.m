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

#import "NetworkSettingController.h"

enum CellSubViewTagEnum
{
    VIEW_TAG_NAME = 1 
};

@interface NetworkSettingController (/* private interfaces */)
- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier;
@end

@implementation NetworkSettingController

@synthesize delegate=_delegate;

- (void)viewDidLoad 
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Network", @"");
    
    _usernameText.placeholder = NSLocalizedString(@"Required", @"");
    _passwordText.placeholder = NSLocalizedString(@"Required", @"");
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) { 
        case 1: return NSLocalizedString(@"Account", @"");
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0: return 1;
        case 1: return 2;
        case 2: return 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = nil;
    UILabel*         theLabel = nil;
    UIFont*          defaultFont = [UIFont boldSystemFontOfSize:17.0];

    cell = [tableView dequeueReusableCellWithIdentifier:@"OptionCell"];
    if (!cell) {
        cell = [self tableViewCellWithReuseIdentifier:@"OptionCell"];
    }
    
    switch (indexPath.section)
    {
        case 0:
            theLabel = (UILabel *)[cell viewWithTag:VIEW_TAG_NAME];
            theLabel.font = defaultFont;
            theLabel.text  = NSLocalizedString(@"Server", @"");
            UILabel *value = [[[UILabel alloc] init] autorelease];
            value.text = @"PlayXiangqi.com";
            value.font = defaultFont;
            value.adjustsFontSizeToFitWidth = YES;
            value.textColor = [UIColor blueColor];
            value.frame = CGRectMake(137, 4, 156, 31);
            [cell.contentView addSubview:value];
            break;
        case 1:
        {
            if (indexPath.row == 0) {
                theLabel = (UILabel *)[cell viewWithTag:VIEW_TAG_NAME];
                theLabel.font = defaultFont;
                theLabel.text  = NSLocalizedString(@"Username", @"");
                _usernameText.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"network_username"];
                _usernameText.frame = CGRectMake(136,  5, 158, 31);
                [cell.contentView addSubview:_usernameText];
            } else {
                theLabel = (UILabel *)[cell viewWithTag:VIEW_TAG_NAME];
                theLabel.font = defaultFont;
                theLabel.text  = NSLocalizedString(@"Password", @"");
                _passwordText.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"network_password"];
                _passwordText.frame = CGRectMake(136,  5, 158, 31);
                [cell.contentView addSubview:_passwordText];
            }
            break;
        }
        case 2:
            theLabel = (UILabel *)[cell viewWithTag:VIEW_TAG_NAME];
            theLabel.font = defaultFont;
            theLabel.text  = NSLocalizedString(@"Auto Connect", @"");
            _autoConnectSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"network_autoConnect"];
            _autoConnectSwitch.frame = CGRectMake(194, 8, 94, 27);
            [cell.contentView addSubview:_autoConnectSwitch];
            break;
    }

    return cell;
}

- (void)dealloc
{
    [_usernameText release];
    [_passwordText release];
    [_autoConnectSwitch release];
    [_delegate release];
    [super dealloc];
}

#pragma mark Event handlers

- (IBAction) textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == _usernameText) {
        NSString* username = textField.text;
        [[NSUserDefaults standardUserDefaults] setObject:username forKey:@"network_username"];
        [_delegate didChangeUsername:self username:username];
    } else if (textField == _passwordText) {
        [[NSUserDefaults standardUserDefaults] setObject:textField.text forKey:@"network_password"];
    }
}

- (IBAction) autoConnectValueChanged:(id)sender
{
    if ([_usernameText isFirstResponder]) { [_usernameText resignFirstResponder]; }
    if ([_passwordText isFirstResponder]) { [_passwordText resignFirstResponder]; }

    [[NSUserDefaults standardUserDefaults] setBool:_autoConnectSwitch.on forKey:@"network_autoConnect"];
}

#pragma mark Private methods
- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)identifier 
{
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
    
	UILabel *label;
	CGRect rect;
	
	rect = CGRectMake(10, 9, 100, 21);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = VIEW_TAG_NAME;
	label.font = [UIFont boldSystemFontOfSize:17];
	label.adjustsFontSizeToFitWidth = YES;
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor blackColor];
	[label release];
	
    cell.accessoryType = UITableViewCellAccessoryNone;
	
	return cell;
}

@end

