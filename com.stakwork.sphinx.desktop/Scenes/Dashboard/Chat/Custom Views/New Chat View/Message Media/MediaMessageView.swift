//
//  MediaMessageView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 12/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol MediaMessageViewDelegate: AnyObject {
    func didTapMediaButton()
    func shouldLoadOriginalMessageMediaDataFrom(originalMessageMedia: BubbleMessageLayoutState.MessageMedia)
    func shouldLoadOriginalMessageFileDataFrom(originalMessageFile: BubbleMessageLayoutState.GenericFile)
}

class MediaMessageView: NSView, LoadableNib {
    
    weak var delegate: MediaMessageViewDelegate?
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var mediaContainer: NSView!
    
    @IBOutlet weak var mediaImageView: AspectFillNSImageView!
    @IBOutlet weak var paidContentOverlay: NSView!
    @IBOutlet weak var fileInfoView: FileInfoView!
    @IBOutlet weak var loadingContainer: NSView!
    @IBOutlet weak var loadingImageView: NSImageView!
    @IBOutlet weak var gifOverlay: GifOverlayView!
    @IBOutlet weak var videoOverlay: NSView!
    @IBOutlet weak var mediaNotAvailableView: NSView!
    @IBOutlet weak var mediaNotAvailableIcon: NSTextField!
    
    @IBOutlet weak var mediaButton: CustomButton!
    
    static let kViewHeight: CGFloat = 300

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
        setup()
    }
    
    func setup() {
        mediaButton.cursor = .pointingHand
        
        mediaContainer.wantsLayer = true
        mediaContainer.layer?.cornerRadius = 8.0
    }
    
    override func viewWillDraw() {
        super.viewWillDraw()
        
        loadingImageView.wantsLayer = true
        loadingImageView.setAnchorPoint(anchorPoint: CGPoint(x: 0.5, y: 0.5))
    }
    
    func removeMargin() {
        setMarginTo(0)
    }
    
    func setMarginTo(
        _ margin: CGFloat
    ) {
//        topMarginConstraint.constant = margin
//        trailingMarginConstraint.constant = margin
//        leadingMarginConstraint.constant = margin
//        bottomMarginConstraint.constant = margin
        
//        self.layoutIfNeeded()
    }
    
    func configureWith(
        messageMedia: BubbleMessageLayoutState.MessageMedia,
        mediaData: MessageTableCellState.MediaData?,
        bubble: BubbleMessageLayoutState.Bubble,
        and delegate: MediaMessageViewDelegate?
    ) {
        self.delegate = delegate
        
        configureMediaNotAvailableIconWith(messageMedia: messageMedia)
        
        if let mediaData = mediaData {
            fileInfoView.isHidden = !messageMedia.isPdf || mediaData.failed
            gifOverlay.isHidden = !messageMedia.isGif || mediaData.failed
            videoOverlay.isHidden = !messageMedia.isVideo || mediaData.failed
            
            mediaImageView.image = mediaData.image
            mediaImageView.gravity = messageMedia.isPaymentTemplate ? .resizeAspect : .resizeAspectFill
            
            if let fileInfo = mediaData.fileInfo {
                fileInfoView.configure(fileInfo: fileInfo)
                fileInfoView.isHidden = false
            } else {
                fileInfoView.isHidden = true
            }
            
            loadingContainer.isHidden = true
            loadingImageView.stopRotating()
            
            paidContentOverlay.isHidden = true
            
            mediaNotAvailableView.isHidden = !mediaData.failed
            mediaNotAvailableIcon.isHidden = !mediaData.failed
        } else {
            fileInfoView.isHidden = true
            videoOverlay.isHidden = true
            gifOverlay.isHidden = true
            
            if messageMedia.isPendingPayment() &&
                bubble.direction.isIncoming()
            {
                paidContentOverlay.isHidden = false
                loadingContainer.isHidden = true
                
                mediaImageView.image = NSImage(
                    named: messageMedia.isVideo ? "paidVideoBlurredPlaceholder" :  "paidImageBlurredPlaceholder"
                )
            } else {
                paidContentOverlay.isHidden = true
                loadingContainer.isHidden = false
                
                mediaImageView.image = nil
                
                loadingImageView.rotate()
            }
        }
    }
    
    func configureMediaNotAvailableIconWith(
        messageMedia: BubbleMessageLayoutState.MessageMedia
    ) {
        if messageMedia.isPdf {
            mediaNotAvailableIcon.stringValue = "picture_as_pdf"
        } else if messageMedia.isVideo {
            mediaNotAvailableIcon.stringValue = "videocam"
        } else {
            mediaNotAvailableIcon.stringValue = "photo_library"
        }
    }

    @IBAction func mediaButtonClicked(_ sender: Any) {
        delegate?.didTapMediaButton()
    }
}
