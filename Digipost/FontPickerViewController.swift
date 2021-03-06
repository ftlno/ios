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

protocol FontPickerViewControllerDelegate {
    func fontPickerViewController(_ fontPickerViewController : FontPickerViewController, didSelectFont font: UIFont)
}

class FontPickerViewController: UITableViewController {

    let fonts = UIFont.commonWebFonts()
    var delegate : FontPickerViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: "FontPickerTableViewCell", bundle: Bundle.main)
        tableView.register(nib, forCellReuseIdentifier: "cell")
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let font = fonts[indexPath.row]
        delegate?.fontPickerViewController(self, didSelectFont: font)
    }

}
