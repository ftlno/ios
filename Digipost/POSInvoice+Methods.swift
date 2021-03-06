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

extension POSInvoice {
    
    func titleForInvoiceButtonLabel(_ isSending: Bool) -> String {
        var title : String? = nil

        if isSending {
            title = NSLocalizedString("LETTER_VIEW_CONTROLLER_INVOICE_BUTTON_SENDING_TITLE", comment:"Sending...");
        } else if (timePaid as Date? != nil) {
            title = NSLocalizedString("LETTER_VIEW_CONTROLLER_INVOICE_BUTTON_PAID_TITLE", comment:"Sent to bank");
        } else if (canBePaidByUser.boolValue)  {
            if (sendToBankUri as NSString? != nil) {
                title = NSLocalizedString("LETTER_VIEW_CONTROLLER_INVOICE_BUTTON_SEND_TITLE", comment:"Send to bank");
            } else {
                if InvoiceBankAgreement.hasAnyActiveAgreements() {
                    title = NSLocalizedString("LETTER_VIEW_CONTROLLER_INVOICE_POPUP_STATUS_AGREEMENT_TYPE_2_UNPROCESSED_POPUP_TITLE", comment:"Klar til betaling");
                }else{
                    title = NSLocalizedString("LETTER_VIEW_CONTROLLER_INVOICE_BUTTON_PAYMENT_TIPS_TITLE", comment:"Payment tips");
                }
            }
        }else {
            title = NSLocalizedString("LETTER_VIEW_CONTROLLER_INVOICE_BUTTON_PAYMENT_TIPS_TITLE", comment:"Payment tips");
        }
        return title!
    }
}
