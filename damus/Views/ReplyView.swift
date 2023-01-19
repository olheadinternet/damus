//
//  ReplyView.swift
//  damus
//
//  Created by William Casarin on 2022-04-17.
//

import SwiftUI

func all_referenced_pubkeys(_ ev: NostrEvent) -> [ReferencedId] {
    var keys = ev.referenced_pubkeys
    let ref = ReferencedId(ref_id: ev.pubkey, relay_id: nil, key: "p")
    keys.insert(ref, at: 0)
    return keys
}

struct ReplyView: View {
    let replying_to: NostrEvent
    let damus: DamusState
    @State var referenced_pubkeys: [ReferencedId] = []
    
    func all_referenced_pubkeys(_ ev: NostrEvent) -> [ReferencedId] {
        var keys = ev.referenced_pubkeys
        let ref = ReferencedId(ref_id: ev.pubkey, relay_id: nil, key: "p")
        keys.insert(ref, at: 0)
        return keys
    }
    
    var body: some View {
        VStack {
            Text("Replying to:", comment: "Indicating that the user is replying to the following listed people.")
            List {
                ForEach(referenced_pubkeys, id: \.ref_id) { pubkey in
                    HStack {
                        let pk = pubkey.ref_id
                        let prof = damus.profiles.lookup(id: pk)
                        Text(Profile.displayName(profile: prof, pubkey: pk))
                            .foregroundColor(.gray)
                            .font(.footnote)
                        Spacer()
                        Button(action: {
                            self.referenced_pubkeys.removeAll { $0.ref_id == pubkey.ref_id }
                        }) {
                            Image(systemName: "x.circle")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .onAppear {
                self.referenced_pubkeys = self.all_referenced_pubkeys(self.replying_to)
            }
            ScrollView {
                EventView(event: replying_to, highlight: .none, has_action_bar: false, damus: damus, show_friend_icon: true)
            }
            PostView(replying_to: replying_to, references: gather_reply_ids(our_pubkey: damus.pubkey, from: replying_to))
        }
        .padding()
    }
}

struct ReplyView_Previews: PreviewProvider {
    static var previews: some View {
        ReplyView(replying_to: NostrEvent(content: "hi", pubkey: "pubkey"), damus: test_damus_state())
    }
}
