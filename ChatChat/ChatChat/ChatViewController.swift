/*
* Copyright (c) 2015 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit

class ChatViewController: JSQMessagesViewController {

  // MARK: Properties
  var messages = [JSQMessage]()
  var outgoingBubbleImageView: JSQMessagesBubbleImage!
  var incomingBubbleImageView: JSQMessagesBubbleImage!
  
  let rootRef = FIRDatabase.database().reference(fromURL: "https://chatchat-bd7e3.firebaseio.com/messages/")
  var messageRef:FIRDatabaseReference!
  
  
  var userIsTypingRef:FIRDatabaseReference! //1
  private var localTyping = false //2
  var isTyping: Bool {
    set{
        //3
        localTyping = newValue
        userIsTypingRef.setValue(newValue)
    }
    get{
        return localTyping
    }
  }
  
  var userTypingQuery:FIRDatabaseQuery!
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupBubbles()
    messageRef = rootRef.child("messages")
    // No avatars
    collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
    collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    observeMessages()
    observeIsTyping()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
  }
  
  override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
    return messages[indexPath.item]
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return messages.count
  }
  
  override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
    let message = messages[indexPath.item] // 1
    if message.senderId == senderId { // 2
      return outgoingBubbleImageView
    } else { // 3
      return incomingBubbleImageView
    }
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
    
    let message = messages[indexPath.item]
    
    if message.senderId == senderId { // 1
      cell.textView!.textColor = UIColor.white // 2
    } else {
      cell.textView!.textColor = UIColor.black // 3
    }
    
    return cell
  }
  
  override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
    return nil
  }
  
    func observeMessages() {
        //1
        let messagesQuery = messageRef.queryLimited(toLast: 25)
        //2
        messagesQuery.observe(FIRDataEventType.childAdded, with: { [weak self] (snpaShot:FIRDataSnapshot) in
            //3
            guard let dict = snpaShot.value as? [String:AnyObject] else { return }
            guard let id = dict["senderId"] as? String else { return }
            guard let text = dict["text"] as? String else { return }
            //4
            self?.addMessage(id, text: text)
            //5
            self?.finishReceivingMessage()
        })
        
    }
  
    func observeIsTyping() {
        let typingIndicatorRef = rootRef.child("typingIndicator")
        userIsTypingRef = typingIndicatorRef.child(senderId)
        userIsTypingRef.onDisconnectRemoveValue()
        
        //1
        userTypingQuery = typingIndicatorRef.queryOrderedByValue().queryEqual(toValue: true)
        //2
        userTypingQuery.observeSingleEvent(of: .value, with: { [weak self] (snapShot:FIRDataSnapshot) in
            if let weakself = self {
                
                //3 You're the only typing, don't show the indicator
                if snapShot.childrenCount == 1 && weakself.isTyping { return }
                
                // 4 Are there others typing?
                weakself.showTypingIndicator = snapShot.childrenCount > 1
                weakself.scrollToBottom(animated: true)
            }
        })
        
    }
  
  func addMessage(_ id: String, text: String) {
    let message = JSQMessage(senderId: id, displayName: "", text: text)
    messages.append(message!)
  }
  
  override func textViewDidChange(_ textView: UITextView) {
    super.textViewDidChange(textView)
    // If the text is not empty, the user is typing
    isTyping = textView.text != ""
  }
  
    //发送消息
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let itemRef = messageRef.childByAutoId()
        let messageItem = [
            "text":text,
            "senderId":senderId
        ]
        itemRef.setValue(messageItem)
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        finishSendingMessage()
        isTyping = false
    }
  
  fileprivate func setupBubbles() {
    let bubbleImageFactory = JSQMessagesBubbleImageFactory()
    outgoingBubbleImageView = bubbleImageFactory?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    incomingBubbleImageView = bubbleImageFactory?.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
  }
  
}
