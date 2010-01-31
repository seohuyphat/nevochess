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
@synthesize redId, redRating;
@synthesize blackId, blackRating;

@end

//------------------------------------------------
@implementation TableListViewController

@synthesize delegate;

- (void) _parseTablesStr:(NSString *)tablesStr
{
    NSLog(@"%s: ENTER. [%@]", __FUNCTION__, tablesStr);
    [_tables removeAllObjects];
    NSArray* entries = [tablesStr componentsSeparatedByString:@"\n"];
    for (NSString *entry in entries) {
        TableInfo* newTable = [TableInfo new];
        NSArray* components = [entry componentsSeparatedByString:@";"];
        newTable.tableId = [components objectAtIndex:0];
        newTable.redId = [components objectAtIndex:6];
        newTable.redRating = [components objectAtIndex:7];
        newTable.blackId = [components objectAtIndex:8];
        newTable.blackRating = [components objectAtIndex:9];
        [_tables addObject:newTable];
        [newTable release];
    }
}

- (id)initWithList:(NSString *)tablesStr
{
    NSLog(@"%s: ENTER.", __FUNCTION__);
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        _tables = [[NSMutableArray alloc] init];
        [self _parseTablesStr:tablesStr];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect titleRect = CGRectMake(0, 0, 300, 40);
    UILabel *tableTitle = [[UILabel alloc] initWithFrame:titleRect];
    tableTitle.textColor = [UIColor blueColor];
    tableTitle.backgroundColor = [self.tableView backgroundColor];
    tableTitle.opaque = YES;
    tableTitle.font = [UIFont boldSystemFontOfSize:18];
    tableTitle.text = NSLocalizedString(@"List of Tables", @"");
    self.tableView.tableHeaderView = tableTitle;
    [self.tableView reloadData];
    [tableTitle release];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"%s: ENTER. section = [%d]", __FUNCTION__, section);
    return [_tables count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ////////////
    NSLog(@"%s: ENTER. indexPath.row = [%d]", __FUNCTION__, indexPath.row);
    ////////////
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.textLabel.font = [UIFont systemFontOfSize:12];
    }
    
    // Set up the cell...
    TableInfo* table = [_tables objectAtIndex:indexPath.row];
    NSString* redInfo = ([table.redId length] == 0 ? @"*"
                         : [NSString stringWithFormat:@"%@(%@)", table.redId, table.redRating]);
    NSString* blackInfo = ([table.blackId length] == 0 ? @"*"
                         : [NSString stringWithFormat:@"%@(%@)", table.blackId, table.blackRating]); 
    cell.textLabel.text = [NSString stringWithFormat:@"#%@: %@ vs. %@", table.tableId, redInfo, blackInfo];
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%s: ENTER. indexPath.row = [%d]", __FUNCTION__, indexPath.row);
    TableInfo* table = [_tables objectAtIndex:indexPath.row];

    NSString* joinColor = @"None"; // Default: an observer.
    if ([table.redId length] == 0) { joinColor = @"Red"; }
    else if ([table.blackId length] == 0) { joinColor = @"Black"; }
    [delegate handeTableJoin:table color:joinColor];
}


- (void)dealloc {
    [_tables release];
    [super dealloc];
}


@end

