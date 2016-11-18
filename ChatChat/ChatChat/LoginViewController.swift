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



class LoginViewController: UIViewController {
  
  // MARK: Properties
  var ref: FIRDatabaseReference!
  var user: FIRUser?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    ref = FIRDatabase.database().reference(fromURL: "https://chatchat-bd7e3.firebaseio.com/")
  }

  @IBAction func loginDidTouch(_ sender: AnyObject) {
    
    FIRAuth.auth()?.signInAnonymously(completion: { (user, error) in
        if error != nil {
            print ("Signed in with uid:", user!.uid)
            return
        } else {
            self.user = user
            self.performSegue(withIdentifier: "LoginToChat", sender: nil)
        }
    })
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    super.prepare(for: segue, sender: sender)
    let navVc = segue.destination as! UINavigationController
    let chatVc = navVc.viewControllers.first as! ChatViewController
    chatVc.senderId = self.user?.uid
    chatVc.senderDisplayName = ""
  }
  
}

