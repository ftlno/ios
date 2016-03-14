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

extension NSAttributedString {



    func symbolicTraits() -> UIFontDescriptorSymbolicTraits {
        var symbolicTraits = UIFontDescriptorSymbolicTraits()

        self.enumerateAttribute(NSFontAttributeName, inRange: NSMakeRange(0, self.length), options: NSAttributedStringEnumerationOptions.LongestEffectiveRangeNotRequired) { (attribute, range, stop) -> Void in
            if let font = attribute as? UIFont {
                symbolicTraits = font.fontDescriptor().symbolicTraits
                stop.memory = true
            }
        }
        return symbolicTraits
    }

    func isBold() -> Bool {
        let symbolicTraits = self.symbolicTraits()
        
        if symbolicTraits.intersect(.TraitBold) == .TraitBold {
            return true
        }
        return false
    }

    func isItalic() -> Bool {
        let symbolicTraits = self.symbolicTraits()
        if symbolicTraits.intersect(.TraitItalic) == .TraitItalic {
            return true
        }
        return false
    }
 
}
