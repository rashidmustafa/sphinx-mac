//
//  MessageTableCellState.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

struct MessageTableCellState {
    
    ///Constants
    static let kBubbleCornerRadius: CGFloat = 8.0
    static let kRowLeftMargin: CGFloat = 15
    static let kRowRightMargin: CGFloat = 9
    ///Should match width constraint in xib
    static let kBubbleWidthPercentage: CGFloat = 0.4
    static let kPodcastClipBubbleWidthPercentage: CGFloat = 0.85
    static let kLabelMargin: CGFloat = 16.0
    static let kSmallBubbleDesiredWidth: CGFloat = 200
    static let kSendPaidContentButtonHeight: CGFloat = 50.0
    
    ///Messages Data
    var message: TransactionMessage? = nil
    var messageId: Int? = nil
    var messageString: String? = nil
    var messageType: Int? = nil
    var messageStatus: Int? = nil
    var chat: Chat
    var owner: UserContact
    var contact: UserContact? = nil
    var tribeAdmin: UserContact? = nil
    var bubbleState: MessageTableCellState.BubbleState? = nil
    var contactImage: NSImage? = nil
    var replyingMessage: TransactionMessage? = nil
    var boostMessages: [TransactionMessage] = []
    var purchaseMessages: [Int: TransactionMessage] = [:]
    var linkContact: LinkContact? = nil
    var linkTribe: LinkTribe? = nil
    var linkWeb: LinkWeb? = nil
    var invoiceData: (Bool, Bool) = (false, false)
    
    ///Generic rows Data
    var separatorDate: Date? = nil
    
    init(
        message: TransactionMessage? = nil,
        chat: Chat,
        owner: UserContact,
        contact: UserContact?,
        tribeAdmin: UserContact?,
        separatorDate: Date?,
        bubbleState: MessageTableCellState.BubbleState? = nil,
        contactImage: NSImage? = nil,
        replyingMessage: TransactionMessage? = nil,
        boostMessages: [TransactionMessage] = [],
        purchaseMessages: [Int: TransactionMessage] = [:],
        linkContact: LinkContact? = nil,
        linkTribe: LinkTribe? = nil,
        linkWeb: LinkWeb? = nil,
        invoiceData: (Bool, Bool)
    ) {
        self.message = message
        self.messageId = message?.id
        self.messageType = message?.type
        self.messageStatus = message?.status
        self.messageString = message?.messageContent
        
        self.chat = chat
        self.contact = contact
        self.owner = owner
        self.tribeAdmin = tribeAdmin
        self.separatorDate = separatorDate
        self.bubbleState = bubbleState
        self.contactImage = contactImage
        self.replyingMessage = replyingMessage
        self.boostMessages = boostMessages
        self.purchaseMessages = purchaseMessages
        self.linkContact = linkContact
        self.linkTribe = linkTribe
        self.linkWeb = linkWeb
        self.invoiceData = invoiceData
    }
    
    ///Reply
    lazy var swipeReply: BubbleMessageLayoutState.SwipeReply? = {
    
        guard let message = message, message.isReplyActionAllowed else {
            return nil
        }
        
        return BubbleMessageLayoutState.SwipeReply()
    }()
    
    ///Bubble States
    lazy var bubble: BubbleMessageLayoutState.Bubble? = {
        
        guard let message = message, let bubbleState = self.bubbleState else {
            return nil
        }
        
        var isSent = message.isOutgoing(ownerId: owner.id)
        
        if (message.isInvoice() && message.isPaid()) {
            isSent = !isSent
        }
        
        return BubbleMessageLayoutState.Bubble(
            direction: isSent ? .Outgoing : .Incoming,
            grouping: bubbleState
        )
    }()
    
    ///Invoice Lines State
    lazy var invoicesLines: BubbleMessageLayoutState.InvoiceLines = {
        
        var lineState = InvoiceLinesState.None
        
        if invoiceData.0 && invoiceData.1 {
            lineState = InvoiceLinesState.Both
        } else if invoiceData.0 {
            lineState = InvoiceLinesState.Left
        } else if invoiceData.1 {
            lineState = InvoiceLinesState.Right
        }
        
        return BubbleMessageLayoutState.InvoiceLines(
            linesState: lineState
        )
    }()
    
    lazy var avatarImage: BubbleMessageLayoutState.AvatarImage? = {
        
        guard let message = message else {
            return nil
        }
        
        if chat.isPublicGroup() {
            return BubbleMessageLayoutState.AvatarImage(
                imageUrl: message.senderPic,
                color: ChatHelper.getSenderColorFor(message: message),
                alias: message.senderAlias ?? "Unknown"
            )
        } else if let contact = contact {
            if (message.isInvoice() && message.isPaid() && message.isOutgoing(ownerId: owner.id)) {
                return BubbleMessageLayoutState.AvatarImage(
                    imageUrl: owner.avatarUrl,
                    color: owner.getColor(),
                    alias: owner.nickname ?? "Unknown"
                )
            } else {
                return BubbleMessageLayoutState.AvatarImage(
                    imageUrl: contact.avatarUrl,
                    color: contact.getColor(),
                    alias: contact.nickname ?? "Unknown",
                    image: contactImage
                )
            }
        }
        
        return nil
    }()
    
    lazy var statusHeader: BubbleMessageLayoutState.StatusHeader? = {
        
        guard let message = message else {
            return nil
        }
        
        var isSent = message.isOutgoing(ownerId: owner.id)
        
        var expirationTimestamp: String? = nil
        
        if let expiryDate = message.expirationDate, Date().timeIntervalSince1970 < expiryDate.timeIntervalSince1970 {
            let secondsDiff = expiryDate.timeIntervalSince1970 - Date().timeIntervalSince1970
            let minutes = (Int(secondsDiff) % 3600) / 60
            expirationTimestamp = String(format: "expires.in".localized, minutes)
        }
        
        var statusHeader = BubbleMessageLayoutState.StatusHeader(
            senderName: (chat.isConversation() ? nil : message.senderAlias),
            color: ChatHelper.getSenderColorFor(message: message),
            showSent: isSent,
            showSendingIcon: isSent && message.pending() && message.isProvisional(),
            showBoltIcon: isSent && message.isConfirmedAsReceived(),
            showFailedContainer: isSent && message.failed(),
            showLockIcon: true,
            showExpiredSent: message.isInvoice() && !message.isPaid() && !isSent,
            showExpiredReceived: message.isInvoice() && !message.isPaid() && isSent,
            expirationTimestamp: expirationTimestamp,
            timestamp: (message.date ?? Date()).getStringDate(format: "hh:mm a")
        )
        
        return statusHeader
    }()
    
    lazy var messageReply: BubbleMessageLayoutState.MessageReply? = {
        
        guard let message = message, let replyingMessage = replyingMessage else {
            return nil
        }
        
        let senderInfo: (NSColor, String, String?) = getSenderInfo(message: replyingMessage)
        
        return BubbleMessageLayoutState.MessageReply(
            messageId: replyingMessage.id,
            color: senderInfo.0,
            alias: senderInfo.1,
            message: replyingMessage.bubbleMessageContentString,
            mediaType: replyingMessage.getMediaType()
        )
    }()
    
    lazy var messageContent: BubbleMessageLayoutState.MessageContent? = {
        guard let message = message else {
            return nil
        }
        
        if message.isBotHTMLResponse() || message.isPayment() || message.isInvoice() {
            return nil
        }
        
        if let messageContent = message.bubbleMessageContentString, messageContent.isNotEmpty {
            return BubbleMessageLayoutState.MessageContent(
                text: messageContent,
                font: NSFont.getMessageFont(),
                linkMatches: messageContent.stringLinks + messageContent.pubKeyMatches + messageContent.mentionMatches,
                shouldLoadPaidText: false
            )
        } else if message.isPaidMessage() {
            return BubbleMessageLayoutState.MessageContent(
                text: paidMessageContent,
                font: NSFont.getEncryptionErrorFont(),
                linkMatches: [],
                shouldLoadPaidText: message.messageContent == nil && (paidContent?.isPurchaseAccepted() == true || bubble?.direction.isOutgoing() == true)
            )
        }
        
        return nil
    }()
    
    lazy var paidMessageContent: String? = {
        guard let message = message else {
            return nil
        }
        
        if paidContent?.isPurchaseAccepted() == true || bubble?.direction.isOutgoing() == true {
            return "loading.paid.message".localized.uppercased()
        } else if paidContent?.isPurchaseDenied() == true {
            return "cannot.load.message.data".localized.uppercased()
        } else {
            return "pay.to.unlock.msg".localized.uppercased()
        }
    }()
    
    lazy var directPayment: BubbleMessageLayoutState.DirectPayment? = {
        guard let message = message, message.isDirectPayment() else {
            return nil
        }
        
        return BubbleMessageLayoutState.DirectPayment(
            amount: message.amount?.intValue ?? 0,
            isTribePmt: chat.isPublicGroup(),
            recipientPic: message.recipientPic,
            recipientAlias: message.recipientAlias,
            recipientColor: ChatHelper.getRecipientColorFor(message: message)
        )
    }()
    
    lazy var callLink: BubbleMessageLayoutState.CallLink? = {
        guard let message = message, message.isCallLink() else {
            return nil
        }
        
        if let messageContent = message.messageContent, messageContent.isNotEmpty {
            
            let link = VoIPRequestMessage.getFromString(messageContent)?.link ?? messageContent
            
            return BubbleMessageLayoutState.CallLink(
                link: link,
                callMode: VideoCallHelper.getCallMode(link: link)
            )
        }
        
        return nil
    }()
    
    lazy var messageMedia: BubbleMessageLayoutState.MessageMedia? = {
        guard let message = message, message.isImageVideoOrPdf() || message.isDirectPayment() || message.isGiphy() else {
            return nil
        }
        
        if message.isDirectPayment() && message.getTemplateURL() == nil {
            return nil
        }
        
        var urlAndKey = messageMediaUrlAndKey
        
        return BubbleMessageLayoutState.MessageMedia(
            url: urlAndKey.0,
            mediaKey: urlAndKey.1,
            isImage: message.isImage() || message.isDirectPayment(),
            isVideo: message.isVideo(),
            isGif: message.isGif(),
            isPdf: message.isPDF(),
            isGiphy: message.isGiphy(),
            isPaid: message.isPaidAttachment(),
            isPaymentTemplate: message.isDirectPayment()
        )
    }()
    
    lazy var audio: BubbleMessageLayoutState.Audio? = {
        guard let message = message, message.isAudio() else {
            return nil
        }
        
        let bubbleWidth: CGFloat = 300
        
        return BubbleMessageLayoutState.Audio(
            url: message.getMediaUrlFromMediaToken(),
            mediaKey: message.mediaKey,
            bubbleWidth: bubbleWidth
        )
    }()
    
    lazy var messageMediaUrlAndKey: (URL?, String?) = {
        guard let message = message else {
            return (nil, nil)
        }
        
        var urlAndKey: (URL?, String?) = (nil, nil)
        
        if message.isMediaAttachment() || message.isPaidMessage() {
            if message.isPaidAttachment() && bubble?.direction.isIncoming() == true {
                if let purchaseAccept = purchaseMessages[TransactionMessage.TransactionMessageType.purchaseAccept.rawValue] {
                    urlAndKey = (purchaseAccept.getMediaUrlFromMediaToken(), purchaseAccept.mediaKey)
                }
            } else {
                urlAndKey = (message.getMediaUrlFromMediaToken(), message.mediaKey)
            }
        } else if message.isDirectPayment() {
            urlAndKey = (message.getTemplateURL(), nil)
        } else if message.isGiphy() {
            urlAndKey = (message.getGiphyUrl(), nil)
        }
        
        return urlAndKey
    }()
    
    lazy var genericFile: BubbleMessageLayoutState.GenericFile? = {
        guard let message = message, message.isFileAttachment() else {
            return nil
        }
        
        return BubbleMessageLayoutState.GenericFile(
            url: message.getMediaUrlFromMediaToken(),
            mediaKey: message.mediaKey
        )
    }()
    
    lazy var botHTMLContent: BubbleMessageLayoutState.BotHTMLContent? = {
        guard let message = message, message.isBotHTMLResponse() else {
            return nil
        }
        
        if let messageContent = message.bubbleMessageContentString, messageContent.isNotEmpty {
            
            var botContent = BubbleMessageLayoutState.BotHTMLContent(
                html: messageContent
            )
            
            return botContent
        } else {
            return nil
        }
    }()
    
    lazy var boosts: BubbleMessageLayoutState.Boosts? = {
        
        guard let message = message, boostMessages.count > 0 else {
            return nil
        }
        
        var boosts: [BubbleMessageLayoutState.Boost] = []
        var boostedByMe = false
        var totalAmount = 0

        for boostMessage in boostMessages {
            let senderInfo: (NSColor, String, String?) = getSenderInfo(message: boostMessage)

            totalAmount += boostMessage.amount?.intValue ?? 0

            boosts.append(
                BubbleMessageLayoutState.Boost(
                    amount: boostMessage.amount?.intValue ?? 0,
                    senderPic: senderInfo.2,
                    senderAlias: senderInfo.1,
                    senderColor: senderInfo.0
                )
            )
            
            if !boostedByMe {
                boostedByMe = boostMessage.senderId == owner.id
            }
        }
        
        return BubbleMessageLayoutState.Boosts(
            boosts: boosts,
            totalAmount: totalAmount,
            boostedByMe: boostedByMe
        )
    }()
    
    lazy var podcastBoost: BubbleMessageLayoutState.PodcastBoost? = {
        guard let message = message, message.isPodcastBoost() else {
            return nil
        }
        
        let amount = message.getBoostAmount()
        
        guard amount > 0 else {
            return nil
        }
        
        return BubbleMessageLayoutState.PodcastBoost(amount: amount)
    }()
    
    lazy var contactLink: BubbleMessageLayoutState.ContactLink? = {
        guard let linkContact = linkContact else {
            return nil
        }
        
        let bubbleWidth: CGFloat = CommonNewMessageCollectionViewitem.kMaximumLinksBubbleWidth
        
        return BubbleMessageLayoutState.ContactLink(
            pubkey: linkContact.pubkey,
            imageUrl: linkContact.contact?.avatarUrl,
            alias: linkContact.contact?.nickname,
            color: linkContact.contact?.getColor(),
            isContact: linkContact.contact != nil,
            bubbleWidth: bubbleWidth,
            roundedBottom: true
        )
    }()
    
    lazy var tribeLink: BubbleMessageLayoutState.TribeLink? = {
        guard let linkTribe = linkTribe else {
            return nil
        }
        
        return BubbleMessageLayoutState.TribeLink(
            link: linkTribe.link
        )
    }()
    
    lazy var webLink: BubbleMessageLayoutState.WebLink? = {
        guard let linkWeb = linkWeb else {
            return nil
        }

        return BubbleMessageLayoutState.WebLink(
            link: linkWeb.link
        )
    }()
    
    lazy var paidContent: BubbleMessageLayoutState.PaidContent? = {
        guard let message = message, message.isPaidAttachment() else {
            return nil
        }
        
        var statusAndLabel: (TransactionMessage.TransactionMessageType, String)
        
        if let _ = purchaseMessages[TransactionMessage.TransactionMessageType.purchaseAccept.rawValue] {
            statusAndLabel = (TransactionMessage.TransactionMessageType.purchaseAccept, "purchase.succeeded".localized)
        } else if let _ = purchaseMessages[TransactionMessage.TransactionMessageType.purchaseDeny.rawValue] {
            statusAndLabel = (TransactionMessage.TransactionMessageType.purchaseDeny, "purchase.succeeded".localized)
        } else if let _ = purchaseMessages[TransactionMessage.TransactionMessageType.purchase.rawValue] {
            statusAndLabel = (TransactionMessage.TransactionMessageType.purchase, "processing".localized)
        } else {
            statusAndLabel = (TransactionMessage.TransactionMessageType(fromRawValue: message.type), "pending".localized)
        }
        
        return BubbleMessageLayoutState.PaidContent(
            price: message.getAttachmentPrice() ?? 0,
            statusTitle: statusAndLabel.1,
            status: statusAndLabel.0,
            shouldAddPadding: (message.isPaidMessage() || message.isPaidGenericFile()) && bubble?.direction.isOutgoing() == true
        )
    }()
    
    lazy var podcastComment: BubbleMessageLayoutState.PodcastComment? = {
        guard let message = message, let podcastComment = message.getPodcastComment(), podcastComment.isValid() else {
            return nil
        }
        
        guard let urlString = podcastComment.url, let url = URL(string: urlString) else {
            return nil
        }
        
        let podcastClipBubbleWidth: CGFloat = 500
        
        return BubbleMessageLayoutState.PodcastComment(
            title: podcastComment.title!,
            timestamp: podcastComment.timestamp!,
            url: url,
            bubbleWidth: podcastClipBubbleWidth
        )
    }()
    
    lazy var payment: BubbleMessageLayoutState.Payment? = {
        
        guard let message = message, message.isPayment(), let date = message.date, let amount = message.amount?.intValue else {
            return nil
        }
        
        return BubbleMessageLayoutState.Payment(
            date: date,
            amount: amount
        )
    }()
    
    lazy var invoice: BubbleMessageLayoutState.Invoice? = {
        
        guard let message = message, message.isInvoice(), let date = message.date, let amount = message.amount?.intValue else {
            return nil
        }
        
        let bubbleWidth: CGFloat = 300
        
        return BubbleMessageLayoutState.Invoice(
            date: date,
            amount: amount,
            memo: message.messageContent,
            font: NSFont.getMessageFont(),
            isPaid: message.isPaid(),
            isExpired: message.isExpired(),
            bubbleWidth: bubbleWidth
        )
    }()
    
    
    ///No Bubble States
    lazy var noBubble: NoBubbleMessageLayoutState.NoBubble? = {
        
        guard let message = message, bubbleState == nil else {
            return nil
        }
        
        let isSent = message.isOutgoing(ownerId: owner.id)
        
        return NoBubbleMessageLayoutState.NoBubble(
            direction: isSent ? .Outgoing : .Incoming
        )
    }()
    
    lazy var deleted: NoBubbleMessageLayoutState.Deleted? = {
        
        guard let message = message, message.isDeleted() else {
            return nil
        }
        
        return NoBubbleMessageLayoutState.Deleted(
            timestamp: (message.date ?? Date()).getStringDate(format: "hh:mm a")
        )
    }()
    
    lazy var dateSeparator: NoBubbleMessageLayoutState.DateSeparator? = {
        
        guard let separatorDate = separatorDate else {
            return nil
        }
        
        let (shouldShowMonth, shouldShowYear) = separatorDate.shouldShowMonthAndYear()
        var timestamp = ""
        
        if separatorDate.isToday() {
            timestamp = "today".localized
        } else if shouldShowMonth && shouldShowYear {
            timestamp = separatorDate.getStringDate(format: "EEEE MMMM dd, yyyy")
        } else if shouldShowMonth {
            timestamp = separatorDate.getStringDate(format: "EEEE MMMM dd")
        } else {
            timestamp = separatorDate.getStringDate(format: "EEEE dd")
        }
        
        return NoBubbleMessageLayoutState.DateSeparator(
            timestamp: timestamp
        )
    }()
    
    lazy var groupMemberNotification: NoBubbleMessageLayoutState.GroupMemberNotification? = {
        
        guard let message = message, let ownerPubKey = owner.publicKey,
                message.isGroupLeaveOrJoinMessage() ||
                (message.isApprovedRequest() && !chat.isMyPublicGroup(ownerPubKey: ownerPubKey)) else {
            
            return nil
        }
        
        let senderInfo: (NSColor, String, String?) = getSenderInfo(message: message)
        
        var messageString = ""
        
        if message.isGroupJoinMessage() {
            messageString = message.getGroupJoinMessageText(senderAlias: senderInfo.1)
        } else if message.isGroupLeaveMessage() {
            messageString = message.getGroupLeaveMessageText(senderAlias: senderInfo.1)
        } else if message.isApprovedRequest() {
            messageString = "member.request.approved".localized
        }
        
        return NoBubbleMessageLayoutState.GroupMemberNotification(message: messageString)
    }()
    
    lazy var groupKickRemovedOrDeclined: NoBubbleMessageLayoutState.GroupKickRemovedOrDeclined? = {
        
        guard let message = message, let ownerPubKey = owner.publicKey,
                message.isGroupKickMessage() ||
                message.isGroupDeletedMessage() ||
                (message.isDeclinedRequest() && !chat.isMyPublicGroup(ownerPubKey: ownerPubKey)) else {
            
            return nil
        }
        
        var messageString = ""
        
        if message.isGroupKickMessage() {
            messageString = "tribe.kick".localized
        } else if message.isGroupDeletedMessage() {
            messageString = "tribe.deleted".localized
        } else if message.isDeclinedRequest() {
            messageString = "member.request.rejected".localized
        }
        
        return NoBubbleMessageLayoutState.GroupKickRemovedOrDeclined(message: messageString)
    }()
    
    lazy var groupMemberRequest: NoBubbleMessageLayoutState.GroupMemberRequest? = {
        
        guard let message = message, let ownerPubKey = owner.publicKey,
                chat.isMyPublicGroup(ownerPubKey: ownerPubKey),
                message.isMemberRequest() || message.isApprovedRequest() || message.isDeclinedRequest() else {
            return nil
        }
        
        guard let memberRequestStatus = NoBubbleMessageLayoutState.GroupMemberRequest.MemberRequestStatus(rawValue: message.type) else {
            return nil
        }
        
        return NoBubbleMessageLayoutState.GroupMemberRequest(
            status: memberRequestStatus,
            isActiveMember: chat.isActiveMember(id: message.senderId),
            senderAlias: message.senderAlias ?? "unknown".localized
        )
    }()
    
    var isTextOnlyMessage: Bool {
        mutating get {
            return
                (self.messageContent != nil) &&
                (self.messageReply == nil) &&
                (self.callLink == nil) &&
                (self.directPayment == nil) &&
                (self.boosts == nil) &&
                (self.contactLink == nil) &&
                (self.tribeLink == nil) &&
                (self.messageMedia == nil) &&
//                (self.webLink == nil) &&
                (self.botHTMLContent == nil) &&
                (self.paidContent == nil) &&
                (self.podcastComment == nil) &&
                (self.genericFile == nil)
        }
    }
}

extension MessageTableCellState {
    func getSenderInfo(
        message: TransactionMessage
    ) -> (NSColor, String, String?) {
        
        var senderInfo: (NSColor, String, String?) = (
            NSColor.Sphinx.SecondaryText,
            "Unknow",
            nil
        )
        
        let isSent = message.isOutgoing(ownerId: owner.id)
        
        if isSent {
            senderInfo = (
                owner.getColor(),
                owner.nickname ?? "Unknow",
                owner.avatarUrl
            )
        } else if chat.isPublicGroup() {
            senderInfo = (
                ChatHelper.getSenderColorFor(message: message),
                message.senderAlias ?? "Unknow",
                message.senderPic
            )
        } else if let contact = contact {
            senderInfo = (
                contact.getColor(),
                contact.nickname ?? "Unknow",
                contact.avatarUrl
            )
        }
        
        return senderInfo
    }
}

extension MessageTableCellState : Hashable {

    static func == (lhs: MessageTableCellState, rhs: MessageTableCellState) -> Bool {
        var mutableLhs = lhs
        var mutableRhs = rhs
        
        return
            mutableLhs.messageId              == mutableRhs.messageId &&
            mutableLhs.messageStatus          == mutableRhs.messageStatus &&
            mutableLhs.messageType            == mutableRhs.messageType &&
            mutableLhs.bubbleState            == mutableRhs.bubbleState &&
            mutableLhs.messageString          == mutableRhs.messageString &&
            mutableLhs.boostMessages.count    == mutableRhs.boostMessages.count &&
            mutableLhs.isTextOnlyMessage      == mutableRhs.isTextOnlyMessage &&
            mutableLhs.separatorDate          == mutableRhs.separatorDate &&
            mutableLhs.paidContent?.status    == mutableRhs.paidContent?.status
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.messageId)
        hasher.combine(self.messageType)
        hasher.combine(self.messageStatus)
        hasher.combine(self.separatorDate)
    }
    
    func getUniqueIdentifier() -> Int {
        if let message = message {
            return message.id
        } else if let separatorDate = separatorDate {
            return Int(separatorDate.timeIntervalSince1970)
        }
        return 0
    }
}

extension MessageTableCellState {
    public enum MessageDirection {
        case Incoming
        case Outgoing
        
        func isIncoming() -> Bool {
            return self == MessageDirection.Incoming
        }
        
        func isOutgoing() -> Bool {
            return self == MessageDirection.Outgoing
        }
    }
    
    public enum BubbleState {
        case Isolated
        case First
        case Middle
        case Last
        case Empty
        
        public func isGroupedAtTop() -> Bool {
            return self == .Middle || self == .Last
        }
    }
    
    public enum InvoiceLinesState {
        case Left
        case Right
        case Both
        case None
    }
}
