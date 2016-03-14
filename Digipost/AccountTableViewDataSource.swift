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

import UIKit

class AccountTableViewDataSource: NSObject, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    
    let tableView:UITableView
    
    lazy var fetchedResultsController : NSFetchedResultsController = {
        
        // Create and configure a fetch request with the Book entity.
        let fetchRequest = NSFetchRequest(entityName: "Mailbox")
        let managedObjectContext: NSManagedObjectContext = POSModelManager.sharedManager().managedObjectContext
        
        // Order the events by creation date, most recent first.
        let ownerDescriptor = NSSortDescriptor(key: "owner", ascending: false)
        let nameDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [ownerDescriptor,nameDescriptor]
        
        var controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext:managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try controller.performFetch()
        } catch let error {
            print(error)
        }
        
        return controller
    }()
    
    // MARK: - Class initialiser
    
    init(asDataSourceForTableView tableView: UITableView){
        self.tableView = tableView
        super.init()
        tableView.dataSource = self
        fetchedResultsController.delegate = self
    }
    
    func startListeningToCoreDataChanges() {
        self.fetchedResultsController.delegate = self
    }
    
    func stopListeningToCoreDataChanges() {
        self.fetchedResultsController.delegate = nil
    }
    // MARK: - UITableViewDataSource
    
    // Set number of sections in tableView
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let numOfSections = self.fetchedResultsController.sections?.count{
            return numOfSections
        } else {
            return 0
        }
    }
    
    // Set number of rows in section
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell?
        
        let mailBox = fetchMailBox(atIndexPath: indexPath)
        
        if mailBox.owner == 0 {
            cell = tableView.dequeueReusableCellWithIdentifier(Constants.Account.accountCellIdentifier, forIndexPath: indexPath) as! AccountTableViewCell
            
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier(Constants.Account.mainAccountCellIdentifier, forIndexPath: indexPath) as! MainAccountTableViewCell
        }
        
        self.configureCell(cell!, atIndexPath: indexPath, mailBox: mailBox)
        
        return cell!
        
    }
    
    // Customize the appearance of table view cells.
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath, mailBox: POSMailbox){
                
        var unreadItemsString = ""
        if let unreadItems = mailBox.unreadItemsInInbox {
            var str = ""
            if unreadItems == 1{
                str = NSLocalizedString("account view unread letter", comment: "Unread message")
                unreadItemsString = "\(unreadItems)\(str)"
            } else {
                str = NSLocalizedString("account view unread letters", comment: "Unread messages")
                unreadItemsString = "\(unreadItems) \(str)"
            }
        }
        
        if let accountCell = cell as? AccountTableViewCell {
            accountCell.accountNameLabel.text = mailBox.name
            accountCell.initialLabel.text = mailBox.name.initials()
            accountCell.unreadMessages.text = unreadItemsString
            accountCell.accountDescriptionLabel.text = NSLocalizedString("account description shared", comment: "Shared with you")
            
        } else if let mainAccountCell = cell as? MainAccountTableViewCell {
            mainAccountCell.accountNameLabel.text = mailBox.name
            mainAccountCell.initialLabel.text = mailBox.name.initials()
            mainAccountCell.unreadMessages.text = unreadItemsString
        }
    }
    
    // Convenience method for getteing the mailbox at an Indexpath in tableview
    func fetchMailBox(atIndexPath indexPath: NSIndexPath) -> POSMailbox{
        return self.fetchedResultsController.objectAtIndexPath(indexPath) as! POSMailbox
    }
    
    // convenience method for fetching objects at index path from the database
    func managedObjectAtIndexPath(indexPath: NSIndexPath) -> NSManagedObject{
        return self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
            
        case NSFetchedResultsChangeType.Insert:
            self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
        case NSFetchedResultsChangeType.Delete:
            self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
        case NSFetchedResultsChangeType.Update:
            let updateCell = self.tableView.cellForRowAtIndexPath(indexPath!)
            self.configureCell(updateCell!, atIndexPath: indexPath!, mailBox: self.fetchMailBox(atIndexPath: indexPath!))
        case NSFetchedResultsChangeType.Move:
            self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
        switch type{
        case NSFetchedResultsChangeType.Insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: UITableViewRowAnimation.Automatic)
        case NSFetchedResultsChangeType.Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: UITableViewRowAnimation.Automatic)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
}

