//
//  DistributionView.swift
//  Mafia3
//
//  Created by Furqaan Ali on 5/22/20.
//  Copyright © 2020 Furqaan Ali. All rights reserved.
//

import SwiftUI

struct DistributionView: View {
    
    @EnvironmentObject var gameData: GameData
    
    @State private var currentPlayer: String = ""
    @State private var currentIndex: Int = -1
    
    @State private var showingRole: Bool = false
    @State private var finishedDistribution: Bool = false
    
    @State private var password: String = ""
    @State private var isPasswordValid: Bool = false
    @State private var showingPasswordRejected: Bool = false
    
    
    //
    // GenerateRoles:
    //  populate the roles list in the environment object
    //  with the appropriate number of roles
    //  shuffle this list for random distribution
    //
    func generateRoles() -> Void {
        for _ in 1...self.gameData.numMafia {
            gameData.roles.append("Mafia")
        }
        for (roleName, isPresent) in gameData.additionalRoles {
            if isPresent {
                gameData.roles.append(roleName)
            }
        }
        for index in gameData.roles.count...gameData.numPlayers {
            if index != gameData.numPlayers {
                self.gameData.roles.append("Civilian")
            }
        }
        for _ in 1...self.gameData.numPlayers {
            self.gameData.isActive.append(true)
        }
        self.gameData.roles.shuffle()
    }
    
    //
    // ClearRoles:
    //  remove all elements from roles and playerNames
    //  lists to allow a fresh start
    //
    func clearRoles() -> Void {
        self.gameData.roles.removeAll()
        self.gameData.playerNames.removeAll()
    }
    
    //
    // DisplayRole:
    //  pop up a new view where the current player
    //  can view his/her role
    //
    func displayRole() -> some View {
        return (
            VStack {
                Text("Role: \(self.gameData.roles[currentIndex])")
            }
        )
    }
    
    //
    // UpdateForNextPlayer:
    //  update game values and prepare screen
    //  for the next player
    //
    func updateForNextPlayer() -> Void {
        if self.currentPlayer != "" {
            self.gameData.playerNames.append(self.currentPlayer)
            self.gameData.activePlayers.append(self.currentPlayer)
            self.currentPlayer.removeAll()
            self.showingRole.toggle()
            self.currentIndex += 1
        }
    }
    
    //
    // CheckDistributionComplete
    //  updates finishedDistribution value to true
    //  if every player has recieved a role
    //
    func checkDistributionComplete() -> Void {
        if self.currentIndex >= self.gameData.numPlayers - 1 {
            self.finishedDistribution.toggle()
        }
    }
    
    //
    // CreateDistributionView:
    //  generate the view used to acquire each player's name
    //  and provide them with a role
    //
    func createDistributionView() -> some View {
        return (
            VStack {
                Text("Distribution Screen")
                    .onAppear(perform: self.generateRoles)
//                    .onDisappear(perform: self.clearRoles)
                
                
                Text("Player #\(self.currentIndex + 2)")
                
                TextField("Enter your name", text: $currentPlayer)
                
                Button(action: {self.updateForNextPlayer()}) {
                    Text("View Role")
                }
                // DESIGN OPTIONS: ACTION SHEET, SHEET, ALERT
                .alert(isPresented: $showingRole) {
                    Alert(title: Text("\(self.gameData.playerNames[currentIndex]), you are"), message: Text("\(self.gameData.roles[currentIndex])"), dismissButton: .default(Text("Close")) {self.checkDistributionComplete()})
                }
            }
        )
    }
    
    //
    // CreateTransitionView:
    //  generate the transition view that will prevent
    //  players from accessing the next view
    //
    //  prevents roles from being compromised
    //
    // TODO: password protect
    //
    func createTransitionView() -> some View {
        return (
            VStack {
                if !isPasswordValid {
                    Text("Return to Director")
                
                    TextField("Enter Game Password", text: $password)
                    
                    Button(action: {self.validatePassword()}) {
                        Text("Submit Password")
                    }
                    .alert(isPresented: $showingPasswordRejected) {
                    Alert(title: Text("Incorrect Password"), message: Text("Please enter the password that was created earlier in the game"), dismissButton: .default(Text("Close")))
                    }
                }
                
                else {
                    NavigationLink(destination: DirectorsView()) {
                        Text("Continue to Directors Screen")
                    }
                }
            }
        )
    }
    
    //
    // ValidatePassword
    //
    func validatePassword() {
        if password == gameData.password {
            isPasswordValid = true
        }
        else {
            showingPasswordRejected.toggle()
        }
    }

    //
    // Body:
    //  content and behavior of DistributionView
    //
    var body: some View {
        Group {
            if !finishedDistribution {
                createDistributionView()
            }
            else {
                createTransitionView()
            }
        }
    }
    
}

struct DistributionView_Previews: PreviewProvider {
    static var previews: some View {
        DistributionView()
    }
}
