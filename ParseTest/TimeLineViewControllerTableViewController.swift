//
//  TimeLineViewControllerTableViewController.swift
//  ParseTest
//
//  Created by Frankie Bagnardi on 9/24/14.
//  Copyright (c) 2014 Frankie. All rights reserved.
//

import UIKit

class TimeLineViewControllerTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var timelineData = NSMutableArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    @IBAction func refreshButton(sender: AnyObject) {
        loadData()
    }
    
    @IBAction func logoutButton(sender: AnyObject) {
        PFUser.logOut()
        openLoginDialogIfNeeded()
    }
    
    @IBAction func loadData(){
        timelineData.removeAllObjects()
        
        var findData = PFQuery(className: "Messsage")
        
        findData.findObjectsInBackgroundWithBlock {
            objects, error in
            if let newItems = objects {
                self.timelineData.addObjectsFromArray(newItems)
            }
            
            let reversed:NSArray = self.timelineData.reverseObjectEnumerator().allObjects as NSArray
            self.timelineData = reversed.mutableCopy() as NSMutableArray
            self.tableView.reloadData()
        }
    }
    
    func openLoginDialogIfNeeded(){
        if PFUser.currentUser() == nil {
            var loginAlert = UIAlertController(title: "Signup / Login", message: "Please sign up or login", preferredStyle: UIAlertControllerStyle.Alert)
            
            loginAlert.addTextFieldWithConfigurationHandler {
                textfield in
                textfield.placeholder = "You username"
            }
            
            loginAlert.addTextFieldWithConfigurationHandler {
                textfield in
                textfield.placeholder = "You password"
                textfield.secureTextEntry = true
            }
            
            loginAlert.addAction(UIAlertAction(title: "Login",
                style: UIAlertActionStyle.Default,
                handler: {
                    alertAction in
                    if let textFields = loginAlert.textFields as? [UITextField] {
                        let usernameField = textFields[0] as UITextField
                        let passwordField = textFields[1] as UITextField
                        
                        PFUser.logInWithUsernameInBackground(usernameField.text, password: passwordField.text) {
                            user, error in
                            if (user != nil) {
                                println("Login success")
                            }
                            else {
                                self.openLoginDialogIfNeeded()
                            }
                        }
                    }
            }))
            
            loginAlert.addAction(UIAlertAction(title: "Signup",
                style: UIAlertActionStyle.Default,
                handler: {
                    alertAction in
                    if let textFields = loginAlert.textFields as? [UITextField] {
                        let usernameField = textFields[0] as UITextField
                        let passwordField = textFields[1] as UITextField
                        
                        var user = PFUser()
                        user.username = usernameField.text
                        user.password = passwordField.text
                        user.signUpInBackgroundWithBlock {
                            success, error in
                            if error == nil {
                                var imagePicker = UIImagePickerController()
                                imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
                                imagePicker.delegate = self
                                
                                self.presentViewController(imagePicker, animated: true, completion: nil)
                            }
                            else {
                                self.openLoginDialogIfNeeded()
                            }
                        }
                    }
            }))
            
            self.presentViewController(loginAlert, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        let pickedImage = info[UIImagePickerControllerOriginalImage] as UIImage
        
        let scaledImage = self.scaleImageWith(pickedImage, newSize: CGSizeMake(75, 75))
        
        let imageData = UIImagePNGRepresentation(scaledImage)
        let file = PFFile(data: imageData)
        PFUser.currentUser().setObject(file, forKey: "profileImage")
        PFUser.currentUser().saveInBackground()
        picker.dismissViewControllerAnimated(true, nil)
    }
    
    func scaleImageWith(image:UIImage, newSize:CGSize)->UIImage {
        UIGraphicsBeginImageContext(newSize)
        image.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    override func viewDidAppear(animated: Bool) {
        self.loadData()
        self.openLoginDialogIfNeeded()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timelineData.count
    }
    
    func transitionAlpha(view: UIView) -> (Void -> Void) {
        view.alpha = 0
        
        return {
            UIView.animateWithDuration(0.5, animations: {
                view.alpha = 1
            })
        }
    }
    
    func animateCellAlpha(cell: MessageTableViewCell) -> (Void -> Void){
        let animUsername = transitionAlpha(cell.usernameLabel)
        let animTime = transitionAlpha(cell.timeLabel)
        let animMessage = transitionAlpha(cell.messageText)
        
        return {
            animUsername()
            animTime()
            animMessage()
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as MessageTableViewCell

        let message = self.timelineData.objectAtIndex(indexPath.row) as PFObject
        
        let fadeIn = animateCellAlpha(cell)
        let fadeInImage = transitionAlpha(cell.profileImageView)
        
        
        cell.messageText.text = message["content"] as String
        
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        cell.timeLabel.text = dateFormatter.stringFromDate(message.createdAt)
        
        var findUser = PFUser.query()
        findUser.whereKey("objectId", equalTo: message["sweeter"].objectId)
        
        findUser.findObjectsInBackgroundWithBlock{ (objects, error) in
            if !(error != nil) {
                let users = objects as NSArray
                let user = (users.lastObject as PFUser)
                
                // profile image
                if let profileImage = user["profileImage"] as? PFFile {
                    profileImage.getDataInBackgroundWithBlock {
                        imageData, error in
                        if error != nil { return }
                        
                        let image = UIImage(data: imageData)
                        cell.profileImageView.image = image
                        fadeInImage()
                    }
                }
                
                
                cell.usernameLabel.text = user.username
            }
            fadeIn()
        }

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView!, canEditRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView!, moveRowAtIndexPath fromIndexPath: NSIndexPath!, toIndexPath: NSIndexPath!) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView!, canMoveRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
