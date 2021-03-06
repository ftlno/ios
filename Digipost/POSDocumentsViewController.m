//
// Copyright (C) Posten Norge AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//         http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <UIAlertView_Blocks/UIAlertView+Blocks.h>
#import "POSFolderIcon.h"
#import "UIColor+Convenience.h"
#import "POSDocumentsViewController.h"
#import "POSModelManager.h"
#import "POSDocument.h"
#import "POSDocumentTableViewCell.h"
#import "POSAttachment.h"
#import "UIColor+Convenience.h"
#import "POSMailbox.h"
#import "POSRootResource.h"
#import "POSFolder+Methods.h"
#import "POSReceipt.h"
#import "NSError+ExtraInfo.h"
#import "SHCAttachmentsViewController.h"
#import "POSLetterViewController.h"
#import "SHCAppDelegate.h"
#import <AHKActionSheet/AHKActionSheet.h>
#import "SHCDocumentsViewController+NavigationHierarchy.h"
#import "UIViewController+ValidateOpening.h"
#import "POSInvoice.h"
#import "POSFoldersViewController.h"
#import "NSPredicate+CommonPredicates.h"
#import "POSDocumentTableViewCell.h"
#import "POSUploadTableViewCell.h"
#import "UIViewController+BackButton.h"
#import "SHCOAuthViewController.h"
#import "POSOAuthManager.h"
#import "POSDocument+Methods.h"
#import "Digipost-Swift.h"

// Segue identifiers (to enable programmatic triggering of segues)
NSString *const kPushDocumentsIdentifier = @"PushDocuments";
NSString *const kDocumentsViewControllerIdentifier = @"documentsViewControllerIdentifier";
// Google Analytics screen name
NSString *const kDocumentsViewControllerScreenName = @"Documents";

NSString *const kRefreshDocumentsContentNotificationName = @"refreshDocumentsContentNotificationName";

NSString *const kDocumentsViewEditingStatusChangedNotificationName = @"documentsViewEditingStatusChangedNotificationName";
//NSString *const kDocumentsViewDidMoveOrDeleteDocumentsLetterViewNeedsReloadNotificationName =@"documentsViewDidMoveOrDeleteDocumentsLetterViewNeedsReloadNotificationName";

NSString *const kEditingStatusKey = @"editingStatusKey";

@interface POSDocumentsViewController () <NSFetchedResultsControllerDelegate, SHCDocumentTableViewCellDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectionBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moveBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteBarButtonItem;
@property (weak, nonatomic) IBOutlet UIView *tableViewBackgroundView;
@property (weak, nonatomic) IBOutlet UILabel *noDocumentsLabel;
@property (copy, nonatomic) NSString *selectedDocumentUpdateUri;
@property (assign, nonatomic) BOOL shouldAnimateInsertAndDeletesToFetchedResultsController;

@end

@implementation POSDocumentsViewController

#pragma mark - UIViewController

- (void)viewDidLoad
{
    self.navigationItem.hidesBackButton = false;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:nil action:nil];

    [self.navigationController.toolbar setBarTintColor:[UIColor colorWithRed:64.0 / 255.0
                                                                       green:66.0 / 255.0
                                                                        blue:69.0 / 255.0
                                                                       alpha:0.95]];

    self.selectionBarButtonItem.title = NSLocalizedString(@"DOCUMENTS_VIEW_CONTROLLER_TOOLBAR_SELECT_ALL_TITLE", @"Select all");
    self.moveBarButtonItem.title = NSLocalizedString(@"DOCUMENTS_VIEW_CONTROLLER_TOOLBAR_MOVE_TITLE", @"Move");
    self.deleteBarButtonItem.title = NSLocalizedString(@"DOCUMENTS_VIEW_CONTROLLER_TOOLBAR_DELETE_TITLE", @"Delete");

    self.baseEntity = [[POSModelManager sharedManager] documentEntity];

    self.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(createdAt))
                                                            ascending:NO
                                                             selector:@selector(compare:)] ];

    self.predicate = [NSPredicate predicateWithDocumentsForMailBoxDigipostAddress:self.mailboxDigipostAddress
                                                                 inFolderWithName:self.folderName];
    self.screenName = kDocumentsViewControllerScreenName;

    [super viewDidLoad];
    [self addAccountsAnFoldersVCToDoucmentHierarchy];

    [self updateToolbarButtonItems];
    self.shouldAnimateInsertAndDeletesToFetchedResultsController = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [self setupTableViewStyling];
}

-(void)setupTableViewStyling{
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 160;
    [self.tableView setBackgroundView:nil];
    [self.tableView setSeparatorColor:[UIColor digipostDocumentListDivider]];
    [self.tableView setBackgroundColor:[UIColor digipostDocumentListBackground]];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell     forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if ([tableView respondsToSelector:@selector(setSeparatorInset:)])
    {
        [tableView setSeparatorInset:UIEdgeInsetsZero];
    } 
    
    if ([tableView respondsToSelector:@selector(setLayoutMargins:)])
    {
        [tableView setLayoutMargins:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)])
    {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)appWillEnterForeground:(NSNotification *)notification {
    [self updateContentsFromServerUserInitiatedRequest:@NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.navigationController setToolbarHidden:YES
                                       animated:NO];

    if ([self.navigationController isNavigationBarHidden]) {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(uploadProgressDidChange:)
                                                 name:kAPIManagerUploadProgressChangedNotificationName
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(uploadProgressDidFinish:)
                                                 name:kAPIManagerUploadProgressFinishedNotificationName
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshContent)
                                                 name:kRefreshDocumentsContentNotificationName
                                               object:nil];
    if (self.folderUri == nil) {
        POSFolder *folder = [POSFolder existingFolderWithName:self.folderName
                                       mailboxDigipostAddress:self.mailboxDigipostAddress
                                       inManagedObjectContext:[POSModelManager sharedManager].managedObjectContext];
        self.folderUri = folder.uri;
        self.folderDisplayName = folder.displayName;
    }
    [self.tableView reloadData];

    self.predicate = [NSPredicate predicateWithDocumentsForMailBoxDigipostAddress:self.mailboxDigipostAddress
                                                                 inFolderWithName:self.folderName];
    [self updateContentsFromServerUserInitiatedRequest:@NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navigationController.toolbar setBarTintColor:[UIColor digipostSpaceGrey]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.isEditing == YES) {
        [self setEditing:NO animated:YES];
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kAPIManagerUploadProgressChangedNotificationName
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kAPIManagerUploadProgressFinishedNotificationName
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kRefreshDocumentsContentNotificationName
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];

    [self programmaticallyEndRefresh];

    [super viewWillDisappear:animated];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kPushAttachmentsIdentifier]) {
        POSDocument *document = (POSDocument *)sender;
        self.selectedDocumentUpdateUri = document.updateUri;
        SHCAttachmentsViewController *attachmentsViewController = (SHCAttachmentsViewController *)segue.destinationViewController;
        attachmentsViewController.documentsViewController = self;
        attachmentsViewController.currentDocumentUpdateURI = document.updateUri;
    } else if ([segue.identifier isEqualToString:kPushLetterIdentifier]) {
        POSAttachment *attachment = (POSAttachment *)sender;
        POSLetterViewController *letterViewController = (POSLetterViewController *)segue.destinationViewController;
        letterViewController.documentsViewController = self;
        letterViewController.attachment = attachment;
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing
             animated:animated];
    [self.navigationController setToolbarHidden:!editing
                                       animated:animated];
    [self updateNavbar];
    self.navigationController.interactivePopGestureRecognizer.enabled = !editing;
    [[NSNotificationCenter defaultCenter] postNotificationName:kDocumentsViewEditingStatusChangedNotificationName
                                                        object:self
                                                      userInfo:@{kEditingStatusKey : [NSNumber numberWithBool:editing]}];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger number = [super tableView:tableView
                  numberOfRowsInSection:section];

    if ([APIClient sharedClient].isUploadingFile && [APIClient sharedClient].uploadFolderName == self.folderName) {
        number++;
    }

    return number;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([APIClient sharedClient].isUploadingFile && [APIClient sharedClient].uploadFolderName == self.folderName) {
        if (indexPath.row == 0) {
            POSUploadTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kUploadTableViewCellIdentifier
                                                                           forIndexPath:indexPath];
            cell.progressView.progress = [APIClient sharedClient].uploadProgress.fractionCompleted;
            cell.dateLabel.text = [POSDocument stringForDocumentDate:[NSDate date]];
            NSString *fileName = [[APIClient sharedClient].uploadProgress userInfo][@"fileName"];
            fileName = [fileName stringByRemovingPercentEncoding];
            cell.fileNameLabel.text = fileName;
            cell.dateLabel.text = @"";
            return cell;
        }

        // If we have a cell displaying the upload progress, adjust the indexPath accordingly.
        indexPath = [NSIndexPath indexPathForRow:indexPath.row - 1
                                       inSection:indexPath.section];
    }
    POSDocumentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kDocumentTableViewCellIdentifier
                                                                     forIndexPath:indexPath];
    [self configureCell:cell
            atIndexPath:indexPath];

    return cell;
}

- (void)configureCell:(POSDocumentTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    POSDocument *document = [self.fetchedResultsController objectAtIndexPath:indexPath];
    POSAttachment *attachment = [document mainDocumentAttachment];

    if ([attachment.authenticationLevel isEqualToString:kAttachmentOpeningValidAuthenticationLevel]) {
        cell.lockedImageView.hidden = YES;
    } else {
        cell.unreadImageView.hidden = YES;
        cell.lockedImageView.hidden = NO;
    }
    if ([attachment.read boolValue]) {
        cell.senderLabel.font = [UIFont digipostRegularFont];
        cell.subjectLabel.font = [UIFont digipostRegularFont];
        cell.backgroundColor = [UIColor digipostDocumentListBackground];
    } else {
        cell.senderLabel.font = [UIFont digipostBoldFont];
        cell.subjectLabel.font = [UIFont digipostBoldFont];
        cell.backgroundColor = [UIColor whiteColor];
    }
    
    [cell.senderLabel setFont: [cell.senderLabel.font fontWithSize: 14]];
    cell.senderLabel.text = [NSString stringWithFormat:@"%@", attachment.document.creatorName];

    cell.delegate = self;
    cell.editingAccessoryType = UITableViewCellAccessoryNone;
    cell.attachmentImageView.hidden = [document.attachments count] > 1 ? NO : YES;
    cell.attachmentImageView.image = [UIImage imageNamed:@"list-icon-attachment"];
    cell.dateLabel.text = [POSDocument stringForDocumentDate:attachment.document.createdAt];
    cell.dateLabel.accessibilityLabel = [NSDateFormatter localizedStringFromDate:attachment.document.createdAt dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];
    cell.subjectLabel.text = attachment.subject;
    cell.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"%@  Received %@ From %@", @"Accessibilitylabel on document cell"), cell.subjectLabel.accessibilityLabel, cell.dateLabel.accessibilityLabel, cell.senderLabel.accessibilityLabel];
    cell.multipleSelectionBackgroundView = [UIView new];

    NSArray *metadataArray = [attachment getMetadataArray];
    for(POSMetadataObject *metadataObject in metadataArray) {
        if([metadataObject isKindOfClass:[POSAppointment class]]) {
            cell.attachmentImageView.hidden = NO;
            cell.attachmentImageView.image = [UIImage imageNamed:@"Kalender-listeikon"];
        }
    }
    
    if([document.invoice intValue] == YES) {
        cell.typeImage.hidden = NO;
        if ([document.collectionNotice intValue] == YES) {
            cell.typeImage.image = [UIImage imageNamed:@"invoice-list-icon-unpaid"];
            cell.typeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"settlement","")];
        }else if([document.paid intValue] == YES) {
            cell.typeImage.image = [UIImage imageNamed:@"invoice-list-icon-added-to-payments"];
            cell.typeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"invoice_paid","")];
        }else {
            cell.typeImage.image = [UIImage imageNamed:@"invoice-list-icon-unpaid"];
            cell.typeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"invoice_unpaid","")];
        }
    }else {
        cell.typeImage.hidden = YES;
        cell.typeLabel.text = @"";
    }
}

#pragma mark - UITableViewDelegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([APIClient sharedClient].isUploadingFile && [APIClient sharedClient].uploadFolderName == self.folderName) {
        if (indexPath.row == 0) {
            return nil;
        }
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isEditing) {
        [self updateToolbarButtonItems];
        return;
    }

    NSIndexPath *actualIndexPathSelected = nil;
    //     adjust for index when uploading file
    if ([APIClient sharedClient].isUploadingFile && [APIClient sharedClient].uploadFolderName == self.folderName) {
        actualIndexPathSelected = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:0];
    } else {
        actualIndexPathSelected = indexPath;
    }

    POSDocument *document = [self.fetchedResultsController objectAtIndexPath:actualIndexPathSelected];
    POSAttachment *attachment = [document mainDocumentAttachment];
    if (attachment == nil) {
        [self updateFetchedResultsController];
    }

    if ([document.attachments count] > 1) {
        [self performSegueWithIdentifier:kPushAttachmentsIdentifier
                                  sender:document];
    } else {
        POSAttachment *attachment = [document mainDocumentAttachment];
        [self validateOpeningAttachment:attachment
            success:^{
                                    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                                        ((SHCAppDelegate *)[UIApplication sharedApplication].delegate).letterViewController.attachment = attachment;
                                    } else {
                                        [self performSegueWithIdentifier:kPushLetterIdentifier sender:attachment];
                                    }
            }
            failure:^(NSError *error) {

            }];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isEditing) {
        [self updateToolbarButtonItems];
        return;
    }
}

#pragma mark - IBActions

- (IBAction)didTapSelectionBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    if ([self someRowsSelected]) {
        [self deselectAllRows];
    } else {
        [self selectAllRows];
    }

    [self updateToolbarButtonItems];
}

- (IBAction)didTapMoveBarButtonItem:(UIBarButtonItem *)barButtonItem
{

    [self showBlurredActionSheetWithFolders];
    return;
}

- (void)showBlurredActionSheetWithFolders
{
    AHKActionSheet *actionSheet = [[AHKActionSheet alloc] initWithTitle:NSLocalizedString(@"navbar title upload folder", @"Choose folder")];

    NSArray *folders = [POSFolder foldersForUserWithMailboxDigipostAddress:self.mailboxDigipostAddress
                                                    inManagedObjectContext:[POSModelManager sharedManager].managedObjectContext];
    [actionSheet setBlurTintColor:[UIColor pos_colorWithR:64
                                                        G:66
                                                        B:69
                                                    alpha:0.80]];
    actionSheet.automaticallyTintButtonImages = @YES;
    [actionSheet setButtonHeight:50];

    actionSheet.separatorColor = [UIColor pos_colorWithR:255
                                                       G:255
                                                       B:255
                                                   alpha:0.30f];

    [actionSheet setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    [actionSheet setButtonTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    [actionSheet setCancelButtonTitle: NSLocalizedString(@"GENERIC_CANCEL_BUTTON_TITLE", @"Cancel")];
    [actionSheet setCancelButtonTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];

    for (POSFolder *folder in folders) {

        UIImage *image = [POSFolderIcon folderIconWithName:folder.iconName].smallImage;
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

        if ([self.folderName isEqualToString:folder.name] == NO) {
            image = [image scaleToSize:CGSizeMake(18, 18)];
            if (image == nil) {
                image = [UIImage imageNamed:@"list-icon-inbox"];
            }

            [actionSheet addButtonWithTitle:folder.displayName
                                      image:image
                                       type:AHKActionSheetButtonTypeDefault
                                    handler:^(AHKActionSheet *actionSheet) {
                                        [self moveSelectedDocumentsToFolder:folder];
                                    }];
        }
    }

    [actionSheet show];
}

- (void)moveSelectedDocumentsToFolder:(POSFolder *)folder
{
    self.shouldAnimateInsertAndDeletesToFetchedResultsController = YES;
    __block NSInteger numberOfDocumentsRemaining = [self.tableView indexPathsForSelectedRows].count;
    for (NSIndexPath *indexPathOfSelectedRow in [self.tableView indexPathsForSelectedRows]) {
        POSDocument *document = [self.fetchedResultsController objectAtIndexPath:indexPathOfSelectedRow];

        [self moveDocument:document
                  toFolder:folder
                   success:^{
                      numberOfDocumentsRemaining = numberOfDocumentsRemaining - 1;
                      if (numberOfDocumentsRemaining == 0) {
                          [self updateContentsFromServerUserInitiatedRequest:@NO];
                      }
                   }];
    }

    [self deselectAllRows];
    [self updateToolbarButtonItems];
    [self setEditing:NO
            animated:YES];
}

- (IBAction)didTapDeleteBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    NSUInteger numberOfLetters = [[self.tableView indexPathsForSelectedRows] count];
    NSUInteger numberOfInvoices = [self numberOfInvoices];

    NSString *letterWord = numberOfLetters == 1 ? NSLocalizedString(@"invoice delete dialog files singular", @"file") : NSLocalizedString(@"invoice delete dialog files plural", @"files");
    
    NSString *deleteTitle = NSLocalizedString(@"dialog delete multiple title", @"Delete");
    NSString *deleteMessage = @"";
    
    if(numberOfInvoices > 0){
        NSString *invoiceWord = numberOfInvoices == 1 ? NSLocalizedString(@"invoice delete dialog invoice singular", @"invoice") : NSLocalizedString(@"invoice delete dialog invoice plural", @"invoices");

        if([InvoiceBankAgreement hasActiveType1Agreement]){
            deleteMessage = [NSString stringWithFormat:NSLocalizedString(@"invoice delete dialog multiple message 20 agreement", @"delete files, including invoices"),(unsigned long) numberOfLetters, letterWord, (unsigned long) numberOfInvoices, invoiceWord];
        }else{
            deleteMessage = [NSString stringWithFormat:NSLocalizedString(@"invoice delete dialog multiple message", @"delete files, including invoices"),(unsigned long) numberOfLetters, letterWord, (unsigned long) numberOfInvoices, invoiceWord];
        }
        
    }else{
        NSString *letterWord = numberOfLetters == 1 ? NSLocalizedString(@"invoice delete dialog files singular", @"fil") : NSLocalizedString(@"invoice delete dialog files plural", @"files");        
        deleteMessage = [NSString stringWithFormat:@"%@ %lu %@", NSLocalizedString(@"DOCUMENTS_VIEW_CONTROLLER_DELETE_CONFIRMATION_ONE", @"Delete"),(unsigned long)numberOfLetters,letterWord];
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:deleteTitle message:deleteMessage preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"DOCUMENTS_VIEW_CONTROLLER_DELETE_CONFIRMATION_ONE", @"Delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self deleteDocuments];
        [self setEditing:NO animated:YES];
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"GENERIC_CANCEL_BUTTON_TITLE", @"Cancel") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self setEditing:NO animated:YES];
    }];
    
    [alertController addAction:deleteAction];
    [alertController addAction:cancelAction];
    
    UIPopoverPresentationController *popPresenter = [alertController popoverPresentationController];
    popPresenter.sourceView = self.view;
    popPresenter.barButtonItem = barButtonItem;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (NSInteger) numberOfInvoices
{
    NSInteger numberOfInvoices = 0;
    for (NSIndexPath *indexPath in [self.tableView indexPathsForSelectedRows]) {
        POSDocument *document = [self.fetchedResultsController objectAtIndexPath:indexPath];
        for (POSAttachment *attachment in document.attachments) {
            if ([attachment.type  isEqual: @"INVOICE"]){
                numberOfInvoices++;
            }
        }
    }
    
    return numberOfInvoices;
}

- (void)refreshContent
{
    [self updateContentsFromServerUserInitiatedRequest:@YES];
}

#pragma mark - Private methods

- (void)updateContentsFromServerUserInitiatedRequest:(NSNumber *)userDidInititateRequest
{
    //    if ([POSAPIManager sharedManager].isUpdatingDocuments) {
    //        return;
    //    }
    self.shouldAnimateInsertAndDeletesToFetchedResultsController = [userDidInititateRequest boolValue];
    // Saving uri for the open document in case we need to re fetch it later
    SHCAppDelegate *appDelegate = (id)[UIApplication sharedApplication].delegate;
    POSLetterViewController *letterViewConctroller = appDelegate.letterViewController;
    NSString *openedAttachmentURI;
    if ([letterViewConctroller isViewLoaded]) {
        openedAttachmentURI = letterViewConctroller.attachment.uri;
        if (openedAttachmentURI == nil) {
        }
    }

    // since all documents are deleted from database regularly, this ensures users won't get buggy data if between "updates" of all content
    [self updateFetchedResultsController];
    [[APIClient sharedClient] updateDocumentsInFolderWithName:self.folderName mailboxDigipostAdress:self.mailboxDigipostAddress folderUri:self.folderUri token:[OAuthToken oAuthTokenWithHighestScopeInStorage] success:^(NSDictionary *responseDictionary) {
        
        [[POSModelManager sharedManager] updateDocumentsInFolderWithName:self.folderName
                                                  mailboxDigipostAddress:self.mailboxDigipostAddress
                                                              attributes:responseDictionary];
        
        [self updateFetchedResultsController];
        [self programmaticallyEndRefresh];
        [self updateNavbar];
        [self showTableViewBackgroundView:([self numberOfRows] == 0)];
        // If the user has just managed to enter a document with attachments _after_ the API call finished,
        // but _before_ the Core Data stuff has finished, tapping an attachment will cause the app to crash.
        // To avoid this, let's check if the attachment vc is on top of the nav stack, and if it is - repopulate its data.
        if ([self.navigationController.topViewController isKindOfClass:[SHCAttachmentsViewController class]]) {
            SHCAttachmentsViewController *attachmentsViewController = (SHCAttachmentsViewController *)self.navigationController.topViewController;
            
            POSDocument *selectedDocument = [POSDocument existingDocumentWithUpdateUri:self.selectedDocumentUpdateUri inManagedObjectContext:[POSModelManager sharedManager].managedObjectContext];
            attachmentsViewController.currentDocumentUpdateURI = selectedDocument.updateUri;
            
        }
        
        // quickfix for a bug that causes attachments document to become nil
        // Refetches the showing attachment that lost its link to its document
        SHCAppDelegate *appDelegate = (id) [UIApplication sharedApplication].delegate;
        POSLetterViewController *letterViewConctroller = (id)appDelegate.letterViewController;
        if (letterViewConctroller.attachment) {
            if (letterViewConctroller.attachment.uri == nil ) {
                POSAttachment *refetchedObject = [POSAttachment existingAttachmentWithUri:openedAttachmentURI inManagedObjectContext:[POSModelManager sharedManager].managedObjectContext];
                [letterViewConctroller setAttachmentDoNotDismissPopover:refetchedObject];
            }
        }
        
        POSRootResource *rootResource = [POSRootResource existingRootResourceInManagedObjectContext:[POSModelManager sharedManager].managedObjectContext];
        
        if([self folderContainsInvoice]){
            [InvoiceBankAgreement updateActiveBankAgreementStatus];
            [self updateCurrentBankAccountWithUri:rootResource.currentBankAccountUri];
        }
        
        //Update badge with unread letters
        if ([self.folderName isEqualToString:@"Inbox"]) {
            NSNumber *unread = [[POSModelManager sharedManager] numberOfUnreadDocumentsInfolder:self.folderName mailboxDigipostAddress:self.mailboxDigipostAddress];
            [UIApplication sharedApplication].applicationIconBadgeNumber = [unread integerValue];
        }
        
    } failure:^(APIError *error) {
        [self programmaticallyEndRefresh];
        
        [self showTableViewBackgroundView:([self numberOfRows] == 0)];
        if ([userDidInititateRequest boolValue]){
            [UIAlertController presentAlertControllerWithAPIError:error presentingViewController:self];
        }
    }];
}

- (void)updateNavbar
{

    UINavigationBar *navBar = [self.navigationController navigationBar];

    UIBarButtonItem *rightBarButtonItem = nil;
    if ([self numberOfRows] > 0) {
        rightBarButtonItem = self.editButtonItem;
        navBar.topItem.rightBarButtonItem = self.editButtonItem;
    }

    UIBarButtonItem *backBarButtonItem = self.navigationItem.leftBarButtonItem;

    navBar.topItem.title = self.folderDisplayName;
    navBar.topItem.leftBarButtonItem = backBarButtonItem;
}

- (void)updateToolbarButtonItems
{
    if ([self.tableView indexPathsForSelectedRows] > 0) {
        self.moveBarButtonItem.enabled = YES;
        self.deleteBarButtonItem.enabled = YES;
    } else {
        self.moveBarButtonItem.enabled = NO;
        self.deleteBarButtonItem.enabled = NO;
    }

    if ([self someRowsSelected]) {
        self.selectionBarButtonItem.title = NSLocalizedString(@"DOCUMENTS_VIEW_CONTROLLER_TOOLBAR_SELECT_NONE_TITLE", @"Select none");
    } else {
        self.selectionBarButtonItem.title = NSLocalizedString(@"DOCUMENTS_VIEW_CONTROLLER_TOOLBAR_SELECT_ALL_TITLE", @"Select all");
    }
}

- (BOOL)someRowsSelected
{
    return [[self.tableView indexPathsForSelectedRows] count] > 0;
}

- (NSInteger)numberOfRows
{
    NSInteger numberOfRows = 0;
    for (NSInteger section = 0; section < [self.tableView numberOfSections]; section++) {
        numberOfRows += [self.tableView numberOfRowsInSection:section];
    }

    return numberOfRows;
}

- (void)selectAllRows
{
    for (NSInteger section = 0; section < [self.tableView numberOfSections]; section++) {
        for (NSInteger row = 0; row < [self.tableView numberOfRowsInSection:section]; row++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row
                                                        inSection:section];
            [self.tableView selectRowAtIndexPath:indexPath
                                        animated:NO
                                  scrollPosition:UITableViewScrollPositionNone];
        }
    }
}

- (void)deselectAllRows
{
    for (NSIndexPath *indexPath in [self.tableView indexPathsForVisibleRows]) {
        POSDocumentTableViewCell *cell = (POSDocumentTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }

    for (NSIndexPath *indexPath in [self.tableView indexPathsForSelectedRows]) {
        [self.tableView deselectRowAtIndexPath:indexPath
                                      animated:NO];
    }
}

- (void)moveDocument:(POSDocument *)document toFolder:(POSFolder *)folder success:(void (^)(void))success
{

    [[APIClient sharedClient] moveDocument:document toFolder:folder success:^{
//        document.folder = folder;

        [[POSModelManager sharedManager] logSavingManagedObjectContext];
        
        [self showTableViewBackgroundView:([self numberOfRows] == 0)];
//        [self updateFetchedResultsController];

        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            POSDocument *currentOpenDocument = ((SHCAppDelegate *)[UIApplication sharedApplication].delegate).letterViewController.attachment.document;
            if ([currentOpenDocument isEqual:document]){
                ((SHCAppDelegate *)[UIApplication sharedApplication].delegate).letterViewController.attachment = nil;
            }
        }
        success();
    } failure:^(APIError *error) {
        [self showTableViewBackgroundView:([self numberOfRows] == 0)];
        [UIAlertController presentAlertControllerWithAPIError:error presentingViewController:self];
    }];
}

- (void)deleteDocuments
{
    __block NSInteger numberOfDocumentsRemaining = [self.tableView indexPathsForSelectedRows].count;
    for (NSIndexPath *indexPathOfSelectedRow in [self.tableView indexPathsForSelectedRows]) {
        POSDocument *document = [self.fetchedResultsController objectAtIndexPath:indexPathOfSelectedRow];
        [self deleteDocument:document success:^{
            numberOfDocumentsRemaining = numberOfDocumentsRemaining - 1;
            if (numberOfDocumentsRemaining == 0) {
                [self updateContentsFromServerUserInitiatedRequest:@NO];
            }
        }];
    }
    [self deselectAllRows];
    [self updateToolbarButtonItems];
}

- (void)deleteDocument:(POSDocument *)document success:(void (^)(void))success
{
    [[APIClient sharedClient] deleteDocument:document.deleteUri success:^{
        [self updateFetchedResultsController];
        
        [self showTableViewBackgroundView:([self numberOfRows] == 0)];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            POSDocument *currentOpenDocument = ((SHCAppDelegate *)[UIApplication sharedApplication].delegate).letterViewController.attachment.document;
            if ([currentOpenDocument isEqual:document]){
                ((SHCAppDelegate *)[UIApplication sharedApplication].delegate).letterViewController.attachment = nil;
            }
        }
        success();
    } failure:^(APIError *error) {
        [UIAlertController presentAlertControllerWithAPIError:error presentingViewController:self];
        [self showTableViewBackgroundView:([self numberOfRows] == 0)];
    }];
}

- (BOOL)folderContainsInvoice
{
    NSManagedObjectContext *managedObjectContext = [POSModelManager sharedManager].managedObjectContext;

    NSArray *alldocuments = [POSDocument allDocumentsInFolderWithName:self.folderName
                                               mailboxDigipostAddress:self.mailboxDigipostAddress
                                               inManagedObjectContext:managedObjectContext];
    for (POSDocument *document in alldocuments) {
        for (POSAttachment *attachment in document.attachments) {
            if ([attachment.type  isEqual: @"INVOICE"]){
                return YES;
            }
        }
    }

    return NO;
}

- (void)updateCurrentBankAccountWithUri:(NSString *)uri
{
    [[APIClient sharedClient] updateBankAccountWithUri:uri success:^(NSDictionary *response) {
        [[POSModelManager sharedManager] updateBankAccountWithAttributes:response];
    }
    failure:^(APIError *error) {
        [UIAlertController presentAlertControllerWithAPIError:error presentingViewController:self];
    }];
}

- (void)uploadProgressDidChange:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Don't do anything if this view controller isn't visible
        if (!(self.isViewLoaded && self.view.window)) {
            return;
        }
        
        // Try to find our upload cell
        POSUploadTableViewCell *uploadCell = nil;
        
        for (UITableViewCell *cell in [self.tableView visibleCells]) {
            if ([cell isKindOfClass:[POSUploadTableViewCell class]]) {
                uploadCell = (POSUploadTableViewCell *)cell;
                break;
            }
        }
        
        if (uploadCell) {
            uploadCell.progressView.progress = [APIClient sharedClient].uploadProgress.fractionCompleted; //[POSAPIManager sharedManager].uploadProgress.fractionCompleted;
        } else {
            // We've not found the upload cell - let's check if the topmost cell is visible.
            // If it is, that means we're missing the upload cell and we need to insert it.
            NSIndexPath *firstIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            if ([[self.tableView indexPathsForVisibleRows] containsObject:firstIndexPath]) {
                [self.tableView reloadData];
            }
        }
    });
}

- (void)uploadProgressDidFinish:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // Don't do anything if this view controller isn't visible
        if (!(self.isViewLoaded && self.view.window)) {
            return;
        }
        [self updateContentsFromServerUserInitiatedRequest:@NO];
        [self.tableView reloadData];
    });
}

- (void)showTableViewBackgroundView:(BOOL)showTableViewBackgroundView
{
    if (!self.tableViewBackgroundView.superview && showTableViewBackgroundView) {
        self.tableView.backgroundView = self.tableViewBackgroundView;

        if([self.folderName  isEqual: @"Inbox"]){
            self.noDocumentsLabel.text = NSLocalizedString(@"DOCUMENTS_VIEW_CONTROLLER_NO_DOCUMENTS__MAILBOX_TITLE", @"Mail you receive in Digipost will appear here. You can also upload your own files i folders.");
        }else{
            self.noDocumentsLabel.text = NSLocalizedString(@"DOCUMENTS_VIEW_CONTROLLER_NO_DOCUMENTS_TITLE", @"You have no documents in this folder.");
        }
    }
    
    self.tableViewBackgroundView.hidden = !showTableViewBackgroundView;
}

- (void)OAuthViewControllerDidAuthenticate:(SHCOAuthViewController *)OAuthViewController
{
    // todo do stuff here when authenticated
}

-(void)documentTableViewCellDidTapEditingButton: (id)sender{
}

@end
