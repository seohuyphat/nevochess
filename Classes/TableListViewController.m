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
@synthesize itimes, redTimes, blackTimes;
@synthesize redId, redRating;
@synthesize blackId, blackRating;

+ (id)allocTableFromString:(NSString *)tableContent
{
    TableInfo* newTable = [TableInfo new];
    NSArray* components = [tableContent componentsSeparatedByString:@";"];

    newTable.tableId = [components objectAtIndex:0];
    newTable.rated = [[components objectAtIndex:2] isEqualToString:@"0"];
    newTable.itimes = [components objectAtIndex:3];
    newTable.redTimes = [components objectAtIndex:4];
    newTable.blackTimes = [components objectAtIndex:5];
    newTable.redId = [components objectAtIndex:6];
    newTable.redRating = [components objectAtIndex:7];
    newTable.blackId = [components objectAtIndex:8];
    newTable.blackRating = [components objectAtIndex:9];

    return newTable;
}

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
@synthesize _delegate;
@synthesize viewOnly=_viewOnly;

- (id)initWithDelegate:(id<TableListDelegate>)delegate
{
    if (self = [self initWithNibName:@"TableListView" bundle:nil]) {
        _tables = [[NSMutableArray alloc] init];
        self._delegate = delegate;
    }
    return self;
}

- (void)reinitWithList:(NSString *)tablesStr
{
    [self _parseTablesStr:tablesStr];
    [self.listView reloadData];
    if ([_tables count]) {
        [self.listView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                             atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    [_activity stopAnimating];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Tables", @"");

    // Create the Add button.
    self.addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                              target:self action:@selector(_addNewTable)];
    self.navigationItem.rightBarButtonItem = addButton;
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [_activity setHidden:NO];
    [_activity startAnimating];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    [_activity stopAnimating];
}

- (void) setViewOnly:(BOOL)value
{
    _viewOnly = value;
    addButton.enabled = !_viewOnly;
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
    [_activity setHidden:NO];
    [_activity startAnimating];
    [_delegate handeRefreshFromList];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_tables count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"%s: ENTER. indexPath.row = [%d]", __FUNCTION__, indexPath.row);
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
    cell.accessoryType = (_viewOnly ? UITableViewCellAccessoryNone
                                    : UITableViewCellAccessoryDetailDisclosureButton);
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"%s: ENTER. indexPath.row = [%d]", __FUNCTION__, indexPath.row);
    if (_viewOnly) {
        return;
    }
    TableInfo* table = [_tables objectAtIndex:indexPath.row];

    NSString* joinColor = @"None"; // Default: an observer.
    if ([table.redId length] == 0) { joinColor = @"Red"; }
    else if ([table.blackId length] == 0) { joinColor = @"Black"; }
    [_delegate handeTableJoin:table color:joinColor];
}

- (void)dealloc
{
    self.addButton = nil;
    self.listView = nil;
    [_tables release];
    self._delegate = nil;
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
    if (!tablesStr || [tablesStr length] == 0) {
        return;
    }
    [_tables removeAllObjects];
    NSArray* entries = [tablesStr componentsSeparatedByString:@"\n"];
    for (NSString *entry in entries) {
        TableInfo* newTable = [TableInfo allocTableFromString:entry];
        [_tables addObject:newTable];
        [newTable release];
    }
}

- (void) _addNewTable
{
    [_delegate handeNewFromList];
}

@end

