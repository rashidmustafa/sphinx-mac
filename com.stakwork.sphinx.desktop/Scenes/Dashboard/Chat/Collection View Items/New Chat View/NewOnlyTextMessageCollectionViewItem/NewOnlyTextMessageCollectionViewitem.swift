//
//  NewOnlyTextMessageCollectionViewitem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class NewOnlyTextMessageCollectionViewitem: CommonNewMessageCollectionViewitem, ChatCollectionViewItemProtocol {
    
    ///General views
    @IBOutlet weak var bubbleOnlyText: NSBox!
    @IBOutlet weak var receivedArrow: NSView!
    @IBOutlet weak var sentArrow: NSView!
    
    @IBOutlet weak var chatAvatarContainerView: NSView!
    @IBOutlet weak var chatAvatarView: ChatSmallAvatarView!
    @IBOutlet weak var sentMessageMargingView: NSView!
    @IBOutlet weak var receivedMessageMarginView: NSView!
    @IBOutlet weak var statusHeaderViewContainer: NSView!

    @IBOutlet weak var statusHeaderView: StatusHeaderView!
    
    ///Constraints
    @IBOutlet weak var bubbleWidthConstraint: NSLayoutConstraint!
    
    ///Thirs Container
    @IBOutlet weak var textMessageView: NSView!
    @IBOutlet weak var messageLabel: MessageTextField!
    @IBOutlet weak var messageLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLabelTrailingConstraint: NSLayoutConstraint!
    
    ///Invoice Lines
//    @IBOutlet weak var leftLineContainer: NSView!
//    @IBOutlet weak var rightLineContainer: NSView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.view.wantsLayer = true
//        self.view.layer?.setAffineTransform(
//            CGAffineTransform(scaleX: 1, y: -1)
//        )
        
        setupViews()
    }
    
    func setupViews() {
        receivedArrow.drawReceivedBubbleArrow(color: NSColor.Sphinx.ReceivedMsgBG)
        sentArrow.drawSentBubbleArrow(color: NSColor.Sphinx.SentMsgBG)
        
        messageLabel.setSelectionColor(color: NSColor.getTextSelectionColor())
        messageLabel.allowsEditingTextAttributes = true
        
//        let lineFrame = CGRect(
//            x: 0.0,
//            y: 0.0,
//            width: 3,
//            height: view.frame.size.height
//        )
        
//        let rightLineLayer = rightLineContainer.getVerticalDottedLine(
//            color: NSColor.Sphinx.WashedOutReceivedText,
//            frame: lineFrame
//        )
//        rightLineContainer.layer.addSublayer(rightLineLayer)
//
//        let leftLineLayer = leftLineContainer.getVerticalDottedLine(
//            color: NSColor.Sphinx.WashedOutReceivedText,
//            frame: lineFrame
//        )
//        leftLineContainer.layer.addSublayer(leftLineLayer)
    }
    
    func configureWith(
        messageCellState: MessageTableCellState,
        mediaData: MessageTableCellState.MediaData?,
        tribeData: MessageTableCellState.TribeData?,
        linkData: MessageTableCellState.LinkData?,
        botWebViewData: MessageTableCellState.BotWebViewData?,
        uploadProgressData: MessageTableCellState.UploadProgressData?,
        delegate: ChatCollectionViewItemDelegate?,
        searchingTerm: String?,
        indexPath: IndexPath,
        isPreload: Bool
    ) {
        var mutableMessageCellState = messageCellState
        
        guard let bubble = mutableMessageCellState.bubble else {
            return
        }
        
        self.delegate = delegate
        self.rowIndex = indexPath.item
        self.messageId = mutableMessageCellState.messageId
        
        if let statusHeader = mutableMessageCellState.statusHeader {
            configureWith(statusHeader: statusHeader)
        }
        
        ///Text message content
        configureWith(
            messageContent: mutableMessageCellState.messageContent,
            searchingTerm: searchingTerm
        )
        
        ///Header and avatar
        configureWith(
            avatarImage: mutableMessageCellState.avatarImage,
            isPreload: isPreload
        )
        configureWith(bubble: bubble)
        
        ///Invoice Lines
        configureWith(invoiceLines: mutableMessageCellState.invoicesLines)
    }

    override func getBubbleView() -> NSBox? {
        return bubbleOnlyText
    }
    
}
