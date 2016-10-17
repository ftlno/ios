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

class ReceiptCategoryTableViewDataSource: NSObject, UITableViewDataSource {

    let tableView: UITableView
    var categories: [ReceiptCategory] = []
    
    init(asDataSourceForTableView tableView: UITableView){
        self.tableView = tableView
        super.init()
        
        tableView.dataSource = self
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if categories.count == 0 {
            tableView.backgroundView?.hidden = false
        } else {
            tableView.backgroundView?.hidden = true
        }
        
        return categories.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = self.tableView.dequeueReusableCellWithIdentifier(ReceiptCategoryTableViewCell.identifier)
        
        if(cell == nil){
            cell = ReceiptCategoryTableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: ReceiptCategoryTableViewCell.identifier)
        }
        
        self.configureCell(cell as! ReceiptCategoryTableViewCell, indexPath: indexPath)
        return cell!
    }
    
    func configureCell(receiptCategoryCell: ReceiptCategoryTableViewCell, indexPath: NSIndexPath){
        let category: ReceiptCategory = self.categories[indexPath.row]
        
        receiptCategoryCell.storeNameLabel.text = category.category
        receiptCategoryCell.amountLabel.text = String(category.count)
    }
    
    func categoryAtIndexPath(indexPath: NSIndexPath) -> ReceiptCategory {
        return self.categories[indexPath.row]
    }
}