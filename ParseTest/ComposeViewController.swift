//
//  ComposeViewController.swift
//  ParseTest
//
//  Created by Frankie Bagnardi on 9/24/14.
//  Copyright (c) 2014 Frankie. All rights reserved.
//

import UIKit

class ComposeViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var characterRemainingLabel: UILabel!
    
    @IBAction func sendMessage(sender: AnyObject) {
        var message = PFObject(className: "Messsage")
        message["content"] = messageTextView.text
        message["sweeter"] = PFUser.currentUser()
        
        message.saveInBackground()
        
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messageTextView.layer.borderColor = UIColor.blackColor().CGColor
        messageTextView.layer.borderWidth = 0.5
        messageTextView.becomeFirstResponder()
        messageTextView.delegate = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        let newLength = (textView.text as NSString).length + (text as NSString).length - range.length
        let remaining = 140 - newLength
        
        characterRemainingLabel.text = "\(remaining)"
        
        // show red if empty or full
        // yellow if almost full or almost empty
        // otherwise green
        // dissalow adding characters if full
        if remaining <= 0 {
            characterRemainingLabel.textColor = UIColor.redColor()
            return false
        }
        else if remaining >= 140 {
            characterRemainingLabel.textColor = UIColor.redColor()
            return true
        }
        else if remaining < 30 || remaining > 130 {
            characterRemainingLabel.textColor = UIColor.orangeColor()
            return true
        }
        else {
            characterRemainingLabel.textColor = UIColor.greenColor()
            return true
        }
    }
}
