//
//  ReplyView.swift
//  damus
//
//  Created by William Casarin on 2022-04-17.
//

import SwiftUI

struct ReplyView: View {
    let replying_to: NostrEvent
    let damus: DamusState
    
    @Binding var originalReferences: [ReferencedId]
    @Binding var references: [ReferencedId]
    @State var participantsShown: Bool = false
    
    var ReplyingToSection: some View {
        HStack {
            Group {
                let names = references.pRefs
                    .map { pubkey in
                        let pk = pubkey.ref_id
                        let prof = damus.profiles.lookup(id: pk)
                        return "@" + Profile.displayName(profile: prof, pubkey: pk).username.truncate(maxLength: 50)
                    }
                    .joined(separator: " ")
                if names.isEmpty {
                    Text("Replying to \(Text("self", comment: "Part of a larger sentence 'Replying to self' in US English. 'self' indicates that the user is replying to themself and no one else.").foregroundColor(.accentColor).font(.footnote))", comment: "Indicating that the user is replying to the themself and no one else, where the parameter is 'self' in US English.")
                        .foregroundColor(.gray)
                        .font(.footnote)
                } else {
                    Text("Replying to \(Text(verbatim: names).foregroundColor(.accentColor).font(.footnote))", comment: "Indicating that the user is replying to the following listed people.")
                        .foregroundColor(.gray)
                        .font(.footnote)
                }
            }
            .onTapGesture {
                participantsShown.toggle()
            }
            .sheet(isPresented: $participantsShown) {
                if #available(iOS 16.0, *) {
                    ParticipantsView(damus_state: damus, references: $references, originalReferences: $originalReferences)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                } else {
                    ParticipantsView(damus_state: damus, references: $references, originalReferences: $originalReferences)
                }
            }
            .padding(.leading, 75)
            Spacer()
        }
    }

    func line(height: CGFloat) -> some View {
        return Rectangle()
            .fill(Color.gray.opacity(0.25))
            .frame(width: 2, height: height)
            .offset(x: 25, y: 40)
            .padding(.leading)
    }

    var body: some View {
        VStack(alignment: .leading) {
            EventView(damus: damus, event: replying_to, options: [.no_action_bar])
                .padding()
                .background(GeometryReader { geometry in
                    let eventHeight = geometry.frame(in: .global).height
                    line(height: eventHeight)
                })
            
            ReplyingToSection
                .background(GeometryReader { geometry in
                    let replyingToHeight = geometry.frame(in: .global).height
                    line(height: replyingToHeight)
                })
        }
    }
}

struct ReplyView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ReplyView(replying_to: test_event, damus: test_damus_state(), originalReferences: .constant([]), references: .constant([]))
                .frame(height: 300)

            ReplyView(replying_to: test_longform_event.event, damus: test_damus_state(), originalReferences: .constant([]), references: .constant([]))
                .frame(height: 300)
        }
    }
}
