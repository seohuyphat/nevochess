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

#import "TableListViewController.h"

//------------------------------------------------
@implementation TableInfo

@synthesize tableId;
@synthesize rated;
@synthesize itimes;
@synthesize redId, redRating;
@synthesize blackId, blackRating;

@end

//------------------------------------------------
@interface TableListViewController (PrivateMethods)

- (void) _parseTablesStr:(NSString *)tablesStr;
- (void) _addNewTable;

@end

//------------------------------------------------
@implementation TableListViewController

@synthesize addButton;
@synthesize listView;
@synthesize delegate;


- (id)initWithList:(NSString *)tablesStr
{
    if (self = [self initWithNibName:@"TableListView" bundle:nil]) {
        _tables = [[NSMutableArray alloc] init];
        [self _parseTablesStr:tablesStr];
    }
    return self;
}

- (void)reinitWithList:(NSString *)tablesStr
{
    [self _parseTablesStr:tablesStr];
    [self.listView reloadData];
    [self.listView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                         atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Tables", @"");

    // Create the Add button.
    self.addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                              target:self action:@selector(_addNewTable)];
    //addButton.enabled = NO;
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

#pragma mark Button methods

- (IBAction) refreshButtonPressed:(id)sender
{
    [delegate handeRefreshFromList];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"%s: ENTER. section = [%d]", __FUNCTION__, section);
    return [_tables count];
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
    TableInfo* table = [_tables objectAtIndex:indexPath.row];
    NSString* redInfo = ([table.redId length] == 0 ? @"*"
                         : [NSString stringWithFormat:@"%@(%@)", table.redId, table.redRating]);
    NSString* blackInfo = ([table.blackId length] == 0 ? @"*"
                         : [NSString stringWithFormat:@"%@(%@)", table.blackId, table.blackRating]); 
    cell.textLabel.text = [NSString stringWithFormat:@"#%@: %@ vs. %@", table.tableId, redInfo, blackInfo];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  %@", table.rated ? @"Rated" : @"Nonrated", table.itimes];
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"%s: ENTER. indexPath.row = [%d]", __FUNCTION__, indexPath.row);
    TableInfo* table = [_tables objectAtIndex:indexPath.row];

    NSString* joinColor = @"None"; // Default: an observer.
    if ([table.redId length] == 0) { joinColor = @"Red"; }
    else if ([table.blackId length] == 0) { joinColor = @"Black"; }
    [delegate handeTableJoin:table color:joinColor];
}

- (void)dealloc
{
    self.addButton = nil;
    self.listView = nil;
    [_tables release];
    [delegate release];
    [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////
//
//    Implementation of Private methods
//
///////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark Private methods

- (void) _parseTablesStr:(NSString *)tablesStr
{
    NSLog(@"%s: ENTER. [%@]", __FUNCTION__, tablesStr);
    [_tables removeAllObjects];
    NSArray* entries = [tablesStr componentsSeparatedByString:@"\n"];
    for (NSString *entry in entries) {
        TableInfo* newTable = [TableInfo new];
        NSArray* components = [entry componentsSeparatedByString:@";"];
        newTable.tableId = [components objectAtIndex:0];
        newTable.rated = [[components objectAtIndex:2] isEqualToString:@"0"];
        newTable.itimes = [components objectAtIndex:3];
        newTable.redId = [components objectAtIndex:6];
        newTable.redRating = [components objectAtIndex:7];
        newTable.blackId = [components objectAtIndex:8];
        newTable.blackRating = [components objectAtIndex:9];
        [_tables addObject:newTable];
        [newTable release];
    }
}

- (void) _addNewTable
{
    [delegate handeNewFromList];
}

@end

