//
//  ContactTableViewController.swift
//  ContactApp
//
//  Created by Mahvish Syed on 25/04/21.
//  Copyright © 2021 Mahvish Syed. All rights reserved.
//

import UIKit

struct Person{
    var imageURLThumbnail : String?
    var imageURLlarge : String?
    var name : String?
    var email : String?
    var number : String?
    var id : String?
    
    var userDefault = UserDefaults(suiteName: "seedStore")
    
    func getContactList(completionHandler : @escaping  ([Person]) -> Void){
        var stringURl = "https://randomuser.me/api/?results=100"
        
        if let value = userDefault?.string(forKey: "seed") as? String{
            stringURl += "&seed=\(value)"
        }
        
        let url = URL(string: stringURl)
        let task = URLSession.shared.dataTask(with: url! , completionHandler: {(data, response, error) in
            if let err = error {
                print("Unsuccessful : \(err)")
            }
            
            guard let res = response as? HTTPURLResponse,
            (200...299).contains(res.statusCode)
                else{
                 print("Unsuccessful : \(response)")
                    return
                }
            
            do{
                if let resultData = data,
                    let jsonData = try JSONSerialization.jsonObject(with: resultData, options: []) as? [String : Any],
                    let jsonArray = jsonData["results"] as? [Any]   {
                    
                    var contactList = [Person]()
                    
                    for obj in jsonArray{
                        if let objJson = obj as? [String : Any]{
                            var personObj = Person()
                            
                            if let cell = objJson["cell"] as? String{
                                personObj.number = cell
                            }
                            if let email = objJson["email"] as? String{
                                personObj.email = email
                            }
                            if let idObj = objJson["login"] as? [String : Any],
                               let id =  idObj["username"] as? String{
                                personObj.id = id
                            }

                            if let nameObj = objJson["name"] as? [String : Any]{
                                var fullName = ""
                                if let prefix = nameObj["tittle"] as? String{
                                    fullName += prefix + " "
                                }
                                if let firstName = nameObj["first"] as? String{
                                    fullName += firstName + " "
                                }
                                if let lastName = nameObj["last"] as? String{
                                    fullName += lastName + " "
                                }
                                personObj.name = fullName
                            }
                            
                            if let imageObj = objJson["picture"] as? [String : Any]{
                               
                                if let large = imageObj["large"] as? String{
                                    personObj.imageURLlarge = large
                                }
                                if let thumbnail = imageObj["thumbnail"] as? String{
                                    personObj.imageURLThumbnail = thumbnail
                                }
                               
                            }
                            
                            contactList.append(personObj)

                        }
                    }
                    
                    if self.userDefault?.string(forKey: "seed") == nil,
                        let seedInfo = jsonData["info"] as? [String : Any],
                        let seedValue = seedInfo["seed"] as? String{
                            self.userDefault?.setValue(seedValue, forKey: "seed")
                    }
                    completionHandler(contactList)
                }
            }catch{}
            
        })
        
        task.resume();
    }
}

class ContactTableViewController: UITableViewController {

    var contactList = [Person]()
    var filtercontactList = [Person]()
    var cacheImage = [String : UIImage]()
    var searchController = UISearchController(searchResultsController: nil)
    var sectioncontactlist = [(Character,  [Person])]()
    var currPerson = Person()
    
    var searchEmpty : Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    var isfiltering : Bool{
        return searchController.isActive && !searchEmpty
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchController()
        loadContactList()
    }
    
    // MARK: - initial contact list setup
    
    func loadContactList(){
        DispatchQueue.global().async {
            Person().getContactList {[unowned self] (data) in
                self.contactList = data
                
                self.sectioncontactlist = Dictionary(grouping: self.contactList) { (contact) -> Character in
                    var fchar : Character?
                    if let name = contact.name as? String{
                        fchar = name.first!
                    }
                    return fchar!
                    }
                    .map { (key: Character, value: [Person]) -> (letter: Character, countries: [Person]) in
                        (letter: key, countries: value)
                    }
                    .sorted { (left, right) -> Bool in
                        left.letter < right.letter
                }
                
                
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    // MARK: - Search contact
    
    func setupSearchController(){
        navigationItem.searchController = searchController
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self as! UISearchResultsUpdating
        definesPresentationContext = true
    }
    
    func filterSearch(for text : String){
        var ltext = text.lowercased()
        filtercontactList = contactList.filter({ (contact) -> Bool in
            return contact.name!.lowercased().contains(ltext)
        })
        tableView.reloadData()
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var headerTittle = String()
        
        if isfiltering {return ""}
        
        if let fchar = sectioncontactlist[section].0 as? Character,
            let fname = String(fchar) as? String{
            headerTittle = fname
        }
        return headerTittle
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        if isfiltering {return 1}
        return sectioncontactlist.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isfiltering {return filtercontactList.count}
        return sectioncontactlist[section].1.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell", for: indexPath) as! ContactTableViewCell
        var contact = Person()
        
        if isfiltering{
            contact = filtercontactList[indexPath.row]
        }else{
            if let personArray = sectioncontactlist[indexPath.section].1 as? [Person],
                let currPerson = personArray[indexPath.row] as? Person{
                contact = currPerson
            }
        }

        if let name = contact.name as? String{
            cell.contactNameLabel.text = name
        }
        
        
        if let id = contact.id as? String,
            let image = cacheImage[id] as? UIImage{
            cell.imageView?.image = image
        }else{
            let imageUrl = URL(string: contact.imageURLThumbnail!)
            DispatchQueue.global().async {
                do{
                    let data = try Data(contentsOf: imageUrl!)
                    if let imageData = data as? Data{
                        DispatchQueue.main.async {
                           
                            cell.imageView?.image = UIImage(data: imageData)
                            self.cacheImage[contact.id!] = cell.imageView?.image
                           
                        }
                    }
                    
                }catch{}
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let personArray = sectioncontactlist[indexPath.section].1 as? [Person],
            let person = personArray[indexPath.row] as? Person{
            currPerson = person
            performSegue(withIdentifier: "ShowContactDetails", sender: nil)
        }   
    }
 

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ViewController{
            vc.person = currPerson
        }
    }
    

}

class ContactTableViewCell : UITableViewCell{
    
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var contactNameLabel: UILabel!
    
}

extension ContactTableViewController : UISearchResultsUpdating{
    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text as? String{
            filterSearch(for: text)
        }
    }
}
