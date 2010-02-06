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

#import "MessageListViewController.h"

//------------------------------------------------
@implementation MessageInfo
@synthesize sender, msg, time;

- (id)init
{
    if (self = [super init]) {
        self.time = [NSDate date];
    }
    return self;
}

@end

//------------------------------------------------
@interface MessageListViewController (PrivateMethods)

- (void) _addNewMessage;

@end

//------------------------------------------------
@implementation MessageListViewController

@synthesize addButton;
@synthesize listView;
@synthesize delegate;
@synthesize _dateFormatter;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _messages = [[NSMutableArray alloc] init];
        self._dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [_dateFormatter setTimeStyle:kCFDateFormatterMediumStyle];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Messages", @"");

    // Create the Add button.
    self.addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                              target:self action:@selector(_addNewMessage)];
    self.navigationItem.rightBarButtonItem = addButton;
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
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"%s: ENTER. section = [%d]", __FUNCTION__, section);
    return [_messages count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"%s: ENTER. indexPath.row = [%d]", __FUNCTION__, indexPath.row);
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        cell.textLabel.font = [UIFont systemFontOfSize:12];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:10];
    }
    
    // Set up the cell...
    MessageInfo* message = [_messages objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", message.sender, message.msg];
    cell.detailTextLabel.text = [_dateFormatter stringFromDate:message.time];
    cell.accessoryType = UITableViewCellAccessoryNone;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"%s: ENTER. indexPath.row = [%d]", __FUNCTION__, indexPath.row);
}

- (void)dealloc
{
    self.addButton = nil;
    self.listView = nil;
    [_messages release];
    [delegate release];
    [_dateFormatter release];
    [super dealloc];
}

- (void) addNewMessage:(MessageInfo*)message
{
    [_messages addObject:message];
    [self.listView reloadData];
    [self.listView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:([_messages count]-1) inSection:0]
                         atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

///////////////////////////////////////////////////////////////////////////////
//
//    Implementation of Private methods
//
///////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark Private methods

- (void) _addNewMessage
{
    [delegate handeNewMessageFromList];
}

@end

