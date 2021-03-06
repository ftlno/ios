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
import Foundation

extension UINavigationController {
    @objc func documentsViewControllerInHierarchy() -> POSDocumentsViewController? {
        for (_, obj) in viewControllers.enumerated() {
            if let documentsViewController = obj as? POSDocumentsViewController {
                return documentsViewController
            }
        }
        return nil
    }
    
    @objc func foldersViewControllerInHierarchy() -> POSFoldersViewController? {
        for (_, obj)  in viewControllers.enumerated() {
            if let foldersViewController = obj as? POSFoldersViewController {
                return foldersViewController
            }
        }
        return nil
    }
}
