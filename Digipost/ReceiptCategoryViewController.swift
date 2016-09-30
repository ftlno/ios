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

class ReceiptCategoriesViewController: UIViewController, UITableViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
    
    @IBOutlet weak var tableView: UITableView!
    var receiptsTableViewDataSource: ReceiptCategoriesTableViewDataSource!;
    
    var mailboxDigipostAddress: String = ""
    var receiptsUri: String = ""
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.pullToRefresh), forControlEvents: UIControlEvents.ValueChanged)
        return refreshControl
    }()
    
    var lockForFetchingCategories: NSLock = NSLock()
    var isFetchingCategories: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = NSLocalizedString("RECEIPTS_VIEW_CONTROLLER_NAVBAR_TITLE", comment: "Receipts")
        self.receiptsTableViewDataSource = ReceiptCategoriesTableViewDataSource.init(asDataSourceForTableView: self.tableView)
        self.tableView.delegate = self
        
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        
        self.refreshControl.initializeRefreshControlText()
        self.refreshControl.attributedTitle = NSAttributedString(string: "placeholder", attributes: [NSForegroundColorAttributeName : UIColor(white: 0.4, alpha: 1.0)])
        self.refreshControl.updateRefreshControlTextRefreshing(false)  // false to get the last updated label
        self.refreshControl.tintColor = UIColor(white: 0.4, alpha: 1.0)
        
        self.refreshControl.beginRefreshing()
        self.refreshControl.endRefreshing()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        trySynchronized(self.lockForFetchingCategories, criticalSection: self.fetchAndSetCategories)
        self.setupTableViewStyling()
    }
    
    func setupTableViewStyling(){
        self.tableView.addSubview(self.refreshControl)
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 160;
        self.tableView.backgroundView = nil
        self.tableView.separatorColor = UIColor.digipostDocumentListDivider()
        self.tableView.backgroundColor = UIColor.digipostDocumentListBackground()
    }
    
    func pullToRefresh(){
        trySynchronized(self.lockForFetchingCategories, criticalSection: fetchAndSetCategories)
    }
    
    func fetchAndSetCategories(){
        if(!self.isFetchingCategories){
            self.isFetchingCategories = true
            func updateCategoriesAndViewUponSuccess(APICallResult: Dictionary<String,AnyObject>){
                self.receiptsTableViewDataSource.categories = parseAndBuildCategoryTableViewCellArrayFrom(APICallResult["chains"]!)
                self.tableView.reloadData()
                
                self.isFetchingCategories = false
            }
            func f(e: APIError){
                print("APIError: ", e)
                self.isFetchingCategories = false
            }
            
            APIClient.sharedClient.fetchReceiptCategoriesInMailbox(self.mailboxDigipostAddress, uri: self.receiptsUri + "/chains", success: updateCategoriesAndViewUponSuccess, failure: f)
        }
    }
    
    func parseAndBuildCategoryTableViewCellArrayFrom(APICallReceiptResult: AnyObject) -> Array<ReceiptCategory>{
        if(APICallReceiptResult.count == 0) {
            return []
        }
        
        var categoryList:Array<ReceiptCategory> = []
        
        for index in 0..<APICallReceiptResult.count /* 0-indexed */ {
            let count = APICallReceiptResult[index]["count"] as! Int
            let category = APICallReceiptResult[index]["name"] as! String
            categoryList.append(ReceiptCategory(count: count, category: category))
        }
        
        return categoryList
    }

}
