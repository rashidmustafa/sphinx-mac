//
//  DirectPaymentReceivedCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 01/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class DirectPaymentReceivedCollectionViewItem: CommonDirectPaymentCollectionViewItem {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, incoming: true, chatWidth: chatWidth)
    }
}
