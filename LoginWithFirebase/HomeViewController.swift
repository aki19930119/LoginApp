//
//  HomeViewController.swift
//  LoginWithFirebase
//
//  Created by 柿沼儀揚 on 2020/03/25.
//  Copyright © 2020 柿沼儀揚. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseAuth

class HomeViewController: UIViewController {
    //オプショナル型
    var user: User?{
        didSet{
            print("user: ",user?.name)
        }
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var LogoutButton: UIButton!
    
    @IBAction func tappedLogoutButton(_ sender: Any) {
        handleLogout()
    }
    //logout
    private func handleLogout() {
        do{
            try Auth.auth().signOut()
            presentToMainViewController()
        }catch (let err){
            print("ログアウトに失敗しました: \(err)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        LogoutButton.layer.cornerRadius = 10
        
        if let user = user {
            nameLabel.text = user.name + "さんようこそ"
            emailLabel.text = user.email
            let dateString = dateFormatterForCreatedAt(date: user.creatAt.dateValue())
            dateLabel.text = "作成日:" + dateString
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        confilmLoggedUser()
    }

    private func confilmLoggedUser(){
        if Auth.auth().currentUser?.uid == nil || user == nil{
            presentToMainViewController()
        }
        
    }
    
    private func presentToMainViewController(){
        //遷移
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyBoard.instantiateViewController(identifier: "ViewController") as! ViewController
        let navController = UINavigationController(rootViewController: viewController)
        //画面をフルスクリーンにする
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    //日本時間に変更
    private func dateFormatterForCreatedAt(date: Date) ->String{
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}
