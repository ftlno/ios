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
import UIKit

class ImageComposerModule: ComposerModule {
    
    var image: UIImage

    init(image: UIImage) {
        self.image = image
        super.init()
    }
    
    override func htmlRepresentation() -> NSString {
        let cssClass = "image"
        return "<img class=\"\(cssClass)\" src=\"data:image/png;base64,\(image.base64Representation)\" alt=\"html_inline_image.png\" title=\"html_inline_image.png\">" as NSString
    }
    
}
