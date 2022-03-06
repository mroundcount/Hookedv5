//
//  AudioAPI.swift
//  Hooked
//
//  Created by Michael Roundcount on 5/8/20.
//  Copyright © 2020 Michael Roundcount. All rights reserved.
//

import Foundation
import Firebase

class AudioApi {
        
    //Method to load files to the "AudioFile" table.
    func uploadAudioFile(value: Dictionary<String, Any>) {
        let ref = Ref().databaseAudioFileOnly()
        ref.childByAutoId().updateChildValues(value)
    }
    
    //Pulling audio from AudioFiles.. filters out the current artist
    //https://stackoverflow.com/questions/41606963/how-to-make-firebase-database-query-to-get-some-of-the-children-using-swift-3
    func loadAudioFile(artist: String, onSuccess: @escaping(Audio) -> Void) {
        let ref = Database.database().reference().child("audioFiles")
        ref.queryOrdered(byChild: "artist").queryEqual(toValue: artist).observe(.childAdded, with: { snapshot in
            if let dict = snapshot.value as? [String : AnyObject] {
                if let audio = Audio.transformAudio(dict: dict, keyId: snapshot.key) {
                    onSuccess(audio)
                }
            }
        })
    }
    
    
    //Looking for which audio file is liked by a given user.
    func observeNewLike(onSuccess: @escaping(AudioCompletion)) {
        Ref().databaseRoot.child("likes").child(Api.User.currentUserId).observeSingleEvent(of: .value) { (snapshot) in
            guard let dict = snapshot.value as? [String: Bool] else { return }
            dict.forEach({ (key, value) in
                self.getAudioInforSingleEvent(id: key, onSuccess: { (audio) in
                    onSuccess(audio)
                })
            })
        }
    }
        
    //Looking for which audio file is liked by a given user.
    //Commented out 1/22
    /*
    func observerCountLikes(id: String, onSuccess: @escaping(AudioCompletion)) {
        let ref = Database.database().reference().child("likes")
        ref.queryOrdered(byChild: "id").queryEqual(toValue: id).observe(.childAdded, with: { snapshot in
            print("Inside of the likes for the count")
        })
    }
 */
    
    //Maybe trying using the reference from User API.... might be worth testing.
    //used to be called getUserInforSingleEvent
    func getAudioInforSingleEvent(id: String, onSuccess: @escaping(AudioCompletion)) {
        let ref = Ref().databaseSpecificAudio(id: id)
        ref.observeSingleEvent(of: .value) { (snapshot) in
            if let dict = snapshot.value as? Dictionary<String, Any> {
                if let audio = Audio.transformAudio(dict: dict, keyId: snapshot.key) {
                    onSuccess(audio)
                }
            }
        }
    }
    
    //Pulling within all of the audio files.
    func observeAudio(onSuccess: @escaping(Audio) -> Void) {
        //returns a snapshot of each audio object. We can also listed for children added, this way it can be added to the snapshot, so we don't have to reload it all the time.
        //Ref().databaseAudioFileOnly().queryLimited(toFirst: 10).observe(.childAdded) { (snapshot) in
        Ref().databaseAudioFileOnly().observe(.childAdded) { (snapshot) in
            //the value of each snapshot is like a dictionary
            if let dict = snapshot.value as? Dictionary<String, Any> {
                //encapsulate these data dictionaries in an abstract class called 'audio'
                //Now we will transfor the dictionary into an object
                if let audio = Audio.transformAudio(dict: dict, keyId: snapshot.key) {
                    onSuccess(audio)
                }
            }
        }
    }

    
}

typealias AudioCompletion = (Audio) -> Void

