//
//  ModeratorsView.swift
//  Mafia3
//
//  Created by Furqaan Ali on 5/20/20.
//  Copyright © 2020 Furqaan Ali. All rights reserved.
//

import SwiftUI

struct ModeratorsView: View {
    
    @EnvironmentObject var gameData: GameData
    
    @State private var currentRound: Int = 1
    
    @State private var playerBeingLynched: String = ""
    @State private var playerProtectedFromLynch: String = ""
    
    @State private var isNight: Bool = false
    @State private var showingResultsSheet: Bool = false
    @State private var showingLynchSheet: Bool = false
    @State private var lynchAvailable: Bool = false
    
    @State private var nightlyRoles = ["Mafia", "Doctor", "Serial Killer", "Lawyer", "Barman", "Cupid"]
    @State private var nightlyChoices = ["", "", "", "", ""]
    
    @State private var currentEvents: [String] = []
    
    @State var currentRoleIndex = 0
    
    
    //
    // Body:
    //  content and behavior of ModeratorsView
    //
    var body: some View {
        Group {
            if !isNight && !showingLynchSheet {
                createDayView()
            }
            else if isNight {
                createNightView()
            }
            else {
                createLynchView()
            }
        }
    }
    
    //
    // PrepareForNewRound
    //  reset all roundly game values,
    //  update round number,
    //  and trigger NightView()
    //
    func prepareForNewRound() -> Void {
        currentEvents.removeAll()
        for index in 0...nightlyChoices.count-1 {
            nightlyChoices[index] = ""
        }
        self.playerBeingLynched = ""
        self.playerProtectedFromLynch = ""
        self.currentRound += 1
        self.lynchAvailable = false
        self.currentRoleIndex = -1
        self.updateSelectionView()
        self.isNight.toggle()
    }
    
    //
    // EvaluateEvents
    //  evaluate which players were eliminated
    //  and display events to the user
    //
    func evaluateEvents() -> Void {
        if currentRound > 1 {
            if !lynchAvailable {
                processPlayerChoices()
                handleAttacks()
                lynchAvailable.toggle()
            }
            else {
                handleLynch()
            }
        }
        
    }
    
    //
    // ProcessPlayerChoices
    //  collect and display all choices that were made
    //  by special-role players during the night
    //
    func processPlayerChoices() -> Void {
        currentEvents.append("Night Events:")
        if nightlyChoices[0] != "" { // mafia made an attack
            currentEvents.append("\(nightlyChoices[0]) was attacked by the Mafia")
        }
        if nightlyChoices[1] != "" { // doctor made a rescue
            currentEvents.append("\(nightlyChoices[1]) was treated by the Doctor")
        }
        if nightlyChoices[2] != "" {
            currentEvents.append("\(nightlyChoices[2]) was attacked by the Serial Killer")
        }
        if nightlyChoices[3] != "" {
            currentEvents.append("\(nightlyChoices[3]) is protected from lynching by the Lawyer")
        }
        if currentRound == 2 && gameData.roles.contains("Cupid") {
            currentEvents.append("Cupid linked: \(gameData.lovers)")
        }
        if nightlyChoices[4] != "" {
            let inhibitedPlayer = nightlyChoices[4]
            let inhibitedRole = gameData.roles[gameData.playerNames.firstIndex(of: inhibitedPlayer)!]
            if inhibitedRole != "Civilian" {
                currentEvents.append("\(inhibitedRole) (\(inhibitedPlayer)) was inhibited by the Barman")
                switch inhibitedRole {
                case "Mafia": nightlyChoices[0] = ""
                case "Doctor": nightlyChoices[1] = ""
                case "Serial Killer": nightlyChoices[2] = ""
                case "Lawyer": nightlyChoices[3] = ""
                default: break
                }
            }
        }
    }
    
    //
    // HandleAttacks
    //  determine the outcomes for all possible
    //  situations of a player being attacked
    //
    func handleAttacks() -> Void {
        let attackedByMafia = nightlyChoices[0]
        let treatedByDoctor = nightlyChoices[1]
        let attackedByKiller = nightlyChoices[2]
        playerProtectedFromLynch = nightlyChoices[3]
        let inhibitedPlayer = nightlyChoices[4]
        var inhibitedRole = ""
        if inhibitedPlayer != "" {
            inhibitedRole = gameData.roles[gameData.playerNames.firstIndex(of: inhibitedPlayer)!]
        }
        
        if attackedByMafia != "" { // mafia attacked a player
            let attackedPlayerRole = gameData.roles[gameData.playerNames.firstIndex(of: attackedByMafia)!]
            if attackedPlayerRole == "Grandma with a Shotgun" && inhibitedRole != "Grandma with a Shotgun" { // random mafia member is killed
                var aliveMafiaMembers: [String] = []
                for index in 0...gameData.playerNames.count-1 {
                    if gameData.roles[index] == "Mafia" && gameData.isActive[index]{
                        aliveMafiaMembers.append(gameData.playerNames[index])
                    }
                }
                let killedMafiaMember = aliveMafiaMembers.randomElement()
                eliminatePlayer(playerName: killedMafiaMember!, treatedByDoctor: treatedByDoctor)
            }
            else if attackedByMafia != treatedByDoctor {  // player is killed by mafia
                eliminatePlayer(playerName: attackedByMafia, treatedByDoctor: treatedByDoctor)
            }
        }
        
        if attackedByKiller != "" && attackedByKiller != treatedByDoctor { // serial killer attacked player not treated by doctor
            eliminatePlayer(playerName: attackedByKiller, treatedByDoctor: treatedByDoctor)
        }
        
        if attackedByMafia != "" && attackedByMafia == attackedByKiller && attackedByKiller == treatedByDoctor {   // if both serial killer and mafia attacked player treated by doctor, eliminate the player
            eliminatePlayer(playerName: attackedByMafia, treatedByDoctor: treatedByDoctor)
        }
        currentEvents.append("")
    }
    
    //
    // HandleLynch
    //  eliminate a player if chosen by the community
    //  to be lynched while player is not protected
    //
    func handleLynch() -> Void {
        currentEvents.append("Lynch Events:")
        if playerBeingLynched != "" {
            if playerBeingLynched != playerProtectedFromLynch {
                eliminatePlayer(playerName: playerBeingLynched, treatedByDoctor: "")
            }
            else {
                currentEvents.append("\(playerBeingLynched) could not be lynched")
            }
            lynchAvailable.toggle()
        }
    }
    
    //
    // EliminatePlayer
    //  remove player from activePlayers list
    //  and update the isActive list to display
    //  an elimination symbol beside the player name
    //
    //  also eliminate the player's lover if he/she has one
    //
    func eliminatePlayer(playerName: String, treatedByDoctor: String) -> Void {
        var index = gameData.activePlayers.firstIndex(of: playerName)
        if index == nil {return} // player has already been eliminated
        gameData.activePlayers.remove(at: index!)
        index = gameData.playerNames.firstIndex(of: playerName)
        gameData.isActive[index!] = false
        currentEvents.append("\(playerName) has died")
        
        checkForLover(playerName: playerName, treatedByDoctor: treatedByDoctor)
    }
    
    //
    // CheckForLover
    //  check if given player has a lover.
    //  if the lover is not treated by the doctor,
    //  then eliminate the lover
    //
    func checkForLover(playerName: String, treatedByDoctor: String) -> Void {
        if gameData.lovers.contains(playerName) {
            var lover: String
            if gameData.lovers[0] == playerName {
                lover = gameData.lovers[1]
            }
            else {
                lover = gameData.lovers[0]
            }
            gameData.lovers.removeAll()
            
            if lover != treatedByDoctor {
                eliminatePlayer(playerName: lover, treatedByDoctor: "")
            }
        }
    }
    
    //
    // PresentResults
    //  display all events that occurred in the previous round
    //
    func presentResults() -> some View {
        return (
            VStack {
                Text("ROUND EVENTS")
                    .font(.title)
                List(currentEvents, id: \.self) { event in
                    Text(event)
                }
            }
            .padding()
            .background(Color.gray)
        )
    }
    
    //
    // CheckGameOver
    //  if only Mafia remain, mafia win.
    //  if only Serial Killer remains, Serial Killer wins.
    //  if no Mafia or Serial Killer remain, the Town wins.
    //
    //  return string of who won
    //
    func checkGameOver() -> String {
        var isMafiaPresent: Bool = false
        var isSerialKillerPresent: Bool = false
        var isTownsPeoplePresent: Bool = false
        
        if gameData.activePlayers.count == 0 {
            return "NO ONE"
        }
        
        for index in 0...gameData.roles.count-1 {
            if gameData.isActive[index] {
                if gameData.roles[index] == "Mafia" {
                    isMafiaPresent = true
                }
                else if gameData.roles[index] == "Serial Killer" {
                    isSerialKillerPresent = true
                }
                else {
                    isTownsPeoplePresent = true
                }
            }
        }
        
        if isMafiaPresent && !isSerialKillerPresent && !isTownsPeoplePresent {
            return "MAFIA"
        }
        else if !isMafiaPresent && isSerialKillerPresent && !isTownsPeoplePresent {
            return "SERIAL KILLER"
        }
        else if !isMafiaPresent && !isSerialKillerPresent && isTownsPeoplePresent {
            return "TOWNSMEN"
        }
        else {
            return ""
        }
        
    }
    
    //
    // IsSelected
    //  provide a bool for the selection list
    //  to determine whether a player is selected or not
    //
    func isSelected(player: String) -> Bool {
        if nightlyRoles[self.currentRoleIndex] == "Cupid" {
            return (self.gameData.lovers.contains(player))
        }
        else {
            return (self.nightlyChoices[self.currentRoleIndex] == player)
        }
    }
    
    //
    // SelectionAction
    //  provide the action() function for the selection list
    //  to determine which elements to update
    //  if an item is selected/deselected
    //
    func selectionAction(player: String) -> Void {
        if nightlyRoles[self.currentRoleIndex] == "Cupid" {
            if self.gameData.lovers.contains(player) {
                self.gameData.lovers.removeAll(where: { $0 == player })
            }
            else {
                self.gameData.lovers.append(player)
            }
        }
        else {
            if self.nightlyChoices[self.currentRoleIndex] == player {
                self.nightlyChoices[self.currentRoleIndex] = ""
            }
            else {
                self.nightlyChoices[self.currentRoleIndex] = player
            }
        }
    }
    
    //
    // UpdateSelectionView
    //  update the selection view for the next players/role
    //  to make their choice
    //  if all players have chosen, exit the selection view
    //
    func updateSelectionView() -> Void {
        repeat {
            self.currentRoleIndex += 1
            if self.currentRound == 2 {
                if self.currentRoleIndex >= 6 {
                    self.isNight.toggle()
                    break
                }
            }
            else {
                if self.currentRoleIndex >= 5 {
                    self.isNight.toggle()
                    break
                }
            }
        }
        while ( !(self.gameData.roles.contains(self.nightlyRoles[self.currentRoleIndex]) && self.gameData.isActive[self.gameData.roles.firstIndex(of: self.nightlyRoles[self.currentRoleIndex])!]))
    }
    
    //
    // CreateDayView
    //  generate view where Moderator can
    //  see all player and round information
    //
    func createDayView() -> some View {
        return (
            ZStack {
                Image("mafiaBackground")
                    .resizable()
                    .edgesIgnoringSafeArea(.all)
                    .aspectRatio(contentMode: .fill)
                
                VStack {
                    
                    Text("PLAYERS")
                        .foregroundColor(Color.white)
                        .fontWeight(.bold)
                        .font(.title)
                    
                    List(gameData.playerNames.indices, id: \.self) { index in
                        PlayerRow(index: index, isActive: self.gameData.isActive[index])
                    }
                    .background(Color.gray)
                    .opacity(0.80)
                    
                    Divider()
                    
                    if currentRound > 1 {
                        Button(action: {self.showingResultsSheet = true}) {
                            Text("View Round Events")
                                .fontWeight(.heavy)
                        }
                    }
                    
                    if checkGameOver() == "" {
                        HStack {
                            Button(action: {self.prepareForNewRound()}) {
                                Text("Begin Night")
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.white)
                                    .padding()
                                    .background(Color.gray)
                                    .opacity(0.75)
                                    .cornerRadius(1000)
                            }
                            
                            if lynchAvailable {
                                Spacer()
                                Button(action: {self.showingLynchSheet.toggle()}) {
                                    Text("Lynch")
                                        .fontWeight(.bold)
                                        .foregroundColor(Color.white)
                                        .padding()
                                        .background(Color.gray)
                                        .opacity(0.75)
                                        .cornerRadius(1000)
                                }
                            }
                        }
                        .padding()
                        .padding()
                    }
                    
                    else {
                        Divider()
                        Text("GAME OVER:")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color.green)
                        Text("\(checkGameOver()) WON!")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.green)
                        Divider()
                    }
                    
                    
                    Text("Round: \(currentRound)")
                        .foregroundColor(Color.white)
                        .onAppear(perform: {self.evaluateEvents()})
                        .sheet(isPresented: self.$showingResultsSheet) {
                            self.presentResults()
                    }
                }
                .navigationBarTitle("")
                .navigationBarHidden(true)
                .padding()
            }
        )
    }
    
    //
    // CreateNightView
    //  generate view where Moderator can
    //  select all events that occurred in the round
    //
    func createNightView() -> some View {
        return (
            ZStack {
                Image("mafiaBackground")
                    .resizable()
                    .edgesIgnoringSafeArea(.all)
                    .aspectRatio(contentMode: .fill)
                
                VStack {
                    Group {
                        Text("Who does \(self.nightlyRoles[currentRoleIndex]) choose?")
                            .font(.title)
                            .foregroundColor(Color.white)
                        List {
                            ForEach(self.gameData.activePlayers, id: \.self) { player in
                                SelectionRow(title: player, isSelected: self.isSelected(player: player)) {
                                    self.selectionAction(player: player)
                                }
                            }
                        }
                        .background(Color.blue)
                        .opacity(0.60)
                    }

                    Form {
                        ForEach(nightlyChoices.indices, id: \.self) {index in
                            Group {
                                if self.nightlyChoices[index] != "" {
                                    Text("\(self.nightlyRoles[index]) chose \(self.nightlyChoices[index])")
                                }
                            }
                        }
                    }
                    .background(Color.red)
                    .opacity(0.60)
                    

                    Button(action: {self.updateSelectionView()}) {
                        Text("Confirm")
                    }
                }
                .padding()
                .padding()
                .navigationBarTitle("")
                .navigationBarHidden(true)
            }
        )
    }
    
    //
    // CreateLynchView
    //  generate view where Moderator can
    //  select which player the community
    //  decided to lynch
    //
    func createLynchView() -> some View {
        return (
            ZStack {
                Image("mafiaBackground")
                    .resizable()
                    .edgesIgnoringSafeArea(.all)
                    .aspectRatio(contentMode: .fill)
                
                VStack {
                    Text("Who does the community lynch?")
                        .font(.title)
                        .foregroundColor(Color.white)
                    List {
                        ForEach(self.gameData.activePlayers, id: \.self) { player in
                            SelectionRow(title: player, isSelected: self.playerBeingLynched == player) {
                                if self.playerBeingLynched == player {
                                    self.playerBeingLynched = ""
                                }
                                else {
                                    self.playerBeingLynched = player
                                }
                            }
                        }
                    }
                    .background(Color.blue)
                    .opacity(0.60)
                    
                    Form {
                        if playerBeingLynched != "" {
                            Text("Community chose: \(self.playerBeingLynched)")
                        }
                    }
                    .background(Color.red)
                    .opacity(0.60)
                    
                    Button(action: {self.showingLynchSheet.toggle()}) {
                        Text("Confirm")
                    }
                }
                .padding()
                .padding()
                .navigationBarTitle("")
                .navigationBarHidden(true)
            }
        )
    }
    
}


//
// SelectionRow
//  creates a row that toggles a boolean value
//  and updates the row appearance accordingly
//
struct SelectionRow: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: self.action) {
            HStack {
                Text(self.title)
                if self.isSelected {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }
    
}
