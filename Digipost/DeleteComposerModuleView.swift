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

class DeleteComposerModuleView: UIView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    func addToView(_ view: UIView) {
        self.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: 71)
        view.addSubview(self)
    }

    func show() {
        
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.frame.origin.y -= self.frame.height
            }, completion: { (Bool) -> Void in
                
        }) 
    }
    
    func hide() {
        
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.frame.origin.y += self.frame.height
            }, completion: { (Bool) -> Void in
                self.removeFromSuperview()
        }) 
    }
}
