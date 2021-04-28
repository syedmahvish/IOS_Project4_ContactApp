//
//  AddNewContactViewController.swift
//  ContactApp
//
//  Created by Mahvish Syed on 27/04/21.
//  Copyright © 2021 Mahvish Syed. All rights reserved.
//

import UIKit
import CoreData

class AddNewContactViewController: UIViewController {

    @IBOutlet weak var imageViewProfilePic: UIImageView!
    @IBOutlet weak var emailtextfield: UITextField!
    @IBOutlet weak var numbertextfield: UITextField!
    @IBOutlet weak var nametextfield: UITextField!
    
    var uploadedImage : UIImage?
    
    var imagePhotoLoader = UIImagePickerController()
    
    var contactTableView : ContactTableViewController?
    
    var newPerson = Person()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePhotoLoader.delegate = self
        emailtextfield.keyboardType = .emailAddress
        nametextfield.keyboardType = .namePhonePad
        numbertextfield.keyboardType = .numberPad
        
        var gesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        gesture.cancelsTouchesInView = true
        view.addGestureRecognizer(gesture)
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    @IBAction func uploadPhoto(_ sender: UIButton) {
         imagePhotoLoader.sourceType = .photoLibrary
         imagePhotoLoader.allowsEditing = true
         present(imagePhotoLoader, animated: true, completion: nil)
    }
    
    @IBAction func saveContact(_ sender: UIBarButtonItem) {
        if(checkMandatoryfield()){
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate
                else { return}
            
            let managedContext = appDelegate.persistentContainer.viewContext
            
            let entity = NSEntityDescription.entity(forEntityName: "Contact", in: managedContext)!
            
            let personContact = NSManagedObject(entity: entity , insertInto: managedContext)
            
            personContact.setValue(nametextfield.text, forKey: "name")
            newPerson.name = nametextfield.text
            
            personContact.setValue(numbertextfield.text, forKey: "cell")
            newPerson.number = numbertextfield.text
            
            if let email = emailtextfield.text as? String{
                personContact.setValue(emailtextfield.text, forKey: "email")
                newPerson.email = email
            }
            
            if let image = uploadedImage as? UIImage,
                let data = image.pngData() as? Data{
                personContact.setValue(data, forKey: "picture")
                newPerson.imageData = data
            }

            do{
                try managedContext.save()
                if let contactVC = self.contactTableView as? ContactTableViewController{
                    contactVC.loadNewData()
                }
                
                dismiss(animated: true, completion: { () in
                   
                });
            }catch{}
        }
    }
    
    func checkMandatoryfield() -> Bool{
        var mandatoryDone = true
        
        if let name = nametextfield.text as? String,
            name.count == 0{
            mandatoryDone = false
            nametextfield.layer.borderWidth = 2
            nametextfield.layer.borderColor = UIColor.red.cgColor
        }else{
            nametextfield.layer.borderColor = UIColor.black.cgColor
        }
        
        if let number = numbertextfield.text as? String,
            number.count == 0{
            mandatoryDone = false
            numbertextfield.layer.borderWidth = 2
            numbertextfield.layer.borderColor = UIColor.red.cgColor
        }else{
            numbertextfield.layer.borderColor = UIColor.black.cgColor
        }
        
        return mandatoryDone
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
         dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ContactTableViewController{
            vc.tableView.reloadData()
        }
    }
    

}
extension AddNewContactViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
            imageViewProfilePic.image = image
            uploadedImage = image
        }
        dismiss(animated: true, completion: nil)
    }
}



