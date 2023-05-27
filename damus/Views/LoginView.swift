//
//  LoginView.swift
//  damus
//
//  Created by William Casarin on 2022-05-22.
//

import SwiftUI

enum ParsedKey {
    case pub(String)
    case priv(String)
    case hex(String)
    case nip05(String)

    var is_pub: Bool {
        if case .pub = self {
            return true
        }

        if case .nip05 = self {
            return true
        }
        return false
    }

    var is_hex: Bool {
        if case .hex = self {
            return true
        }
        return false
    }
}

struct LoginView: View {
    @State private var create_account = false
    @State var key: String = ""
    @State var is_pubkey: Bool = false
    @State var error: String? = nil
    @State private var credential_handler = CredentialHandler()
    
    @Binding var accepted: Bool

    func get_error(parsed_key: ParsedKey?) -> String? {
        if self.error != nil {
            return self.error
        }

        if !key.isEmpty && parsed_key == nil {
            return LoginError.invalid_key.errorDescription
        }

        return nil
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            if accepted {
                NavigationLink(destination: CreateAccountView(), isActive: $create_account) {
                    EmptyView()
                }
            }
            
            VStack {
                SignInHeader()
                    .padding(.top, 100)
                
                SignInEntry(key: $key)
                
                let parsed = parse_key(key)
                
                if parsed?.is_hex ?? false {
                    // convert to bech32 here
                }

                if let error = get_error(parsed_key: parsed) {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }

                if parsed?.is_pub ?? false {
                    Text("This is a public key, you will not be able to make posts or interact in any way. This is used for viewing accounts from their perspective.", comment: "Warning that the inputted account key is a public key and the result of what happens because of it.")
                        .foregroundColor(Color.orange)
                        .bold()
                }

                if let p = parsed {
                    
                    Button(action: {
                        Task {
                            do {
                                try await process_login(p, is_pubkey: is_pubkey)
                            } catch {
                                self.error = error.localizedDescription
                            }
                        }
                    }) {
                        HStack {
                            Text("Login", comment:  "Button to log into account.")
                                .fontWeight(.semibold)
                        }
                        .frame(minWidth: 300, maxWidth: .infinity, maxHeight: 12, alignment: .center)
                    }
                    .buttonStyle(GradientButtonStyle())
                    .padding(.top, 10)
                }

                CreateAccountPrompt(create_account: $create_account)
                    .padding(.top, 10)

                Spacer()
            }
            .padding()
        }
        .background(
            Image("login-header")
                .resizable()
                .frame(maxWidth: .infinity, maxHeight: 350, alignment: .center)
                .ignoresSafeArea(),
            alignment: .top
        )
        .onAppear {
            credential_handler.check_credentials()
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: BackNav())
    }
}

func parse_key(_ thekey: String) -> ParsedKey? {
    var key = thekey
    if key.count > 0 && key.first! == "@" {
        key = String(key.dropFirst())
    }

    if hex_decode(key) != nil {
        return .hex(key)
    }

    if (key.contains { $0 == "@" }) {
        return .nip05(key)
    }

    if let bech_key = decode_bech32_key(key) {
        switch bech_key {
        case .pub(let pk):
            return .pub(pk)
        case .sec(let sec):
            return .priv(sec)
        }
    }

    return nil
}

enum LoginError: LocalizedError {
    case invalid_key
    case nip05_failed
    
    var errorDescription: String? {
        switch self {
        case .invalid_key:
            return NSLocalizedString("Invalid key", comment: "Error message indicating that an invalid account key was entered for login.")
        case .nip05_failed:
            return "Could not fetch pubkey"
        }
    }
}

func process_login(_ key: ParsedKey, is_pubkey: Bool) async throws {
    switch key {
    case .priv(let priv):
        try handle_privkey(priv)
    case .pub(let pub):
        try clear_saved_privkey()
        save_pubkey(pubkey: pub)

    case .nip05(let id):
        guard let nip05 = await get_nip05_pubkey(id: id) else {
            throw LoginError.nip05_failed
        }
        
        // this is a weird way to login anyways
        /*
         var bootstrap_relays = load_bootstrap_relays(pubkey: nip05.pubkey)
         for relay in nip05.relays {
         if !(bootstrap_relays.contains { $0 == relay }) {
         bootstrap_relays.append(relay)
         }
         }
         */
        save_pubkey(pubkey: nip05.pubkey)

    case .hex(let hexstr):
        if is_pubkey {
            try clear_saved_privkey()
            save_pubkey(pubkey: hexstr)
        } else {
            try handle_privkey(hexstr)
        }
    }
    
    func handle_privkey(_ privkey: String) throws {
        try save_privkey(privkey: privkey)
        
        guard let pk = privkey_to_pubkey(privkey: privkey) else {
            throw LoginError.invalid_key
        }
        
        if let pub = bech32_pubkey(pk), let priv = bech32_privkey(privkey) {
            CredentialHandler().save_credential(pubkey: pub, privkey: priv)
        }
        save_pubkey(pubkey: pk)
    }
    
    await MainActor.run {
        notify(.login, ())
    }
}

struct NIP05Result: Decodable {
    let names: Dictionary<String, String>
    let relays: Dictionary<String, [String]>?
}

struct NIP05User {
    let pubkey: String
    let relays: [String]
}

func get_nip05_pubkey(id: String) async -> NIP05User? {
    let parts = id.components(separatedBy: "@")

    guard parts.count == 2 else {
        return nil
    }

    let user = parts[0]
    let host = parts[1]

    guard let url = URL(string: "https://\(host)/.well-known/nostr.json?name=\(user)") else {
        return nil
    }

    guard let (data, _) = try? await URLSession.shared.data(for: URLRequest(url: url)) else {
        return nil
    }

    guard let json: NIP05Result = decode_data(data) else {
        return nil
    }

    guard let pubkey = json.names[user] else {
        return nil
    }

    var relays: [String] = []
    if let rs = json.relays {
        if let rs = rs[pubkey] {
            relays = rs
        }
    }

    return NIP05User(pubkey: pubkey, relays: relays)
}

struct KeyInput: View {
    let title: String
    let key: Binding<String>

    init(_ title: String, key: Binding<String>) {
        self.title = title
        self.key = key
    }

    var body: some View {
        HStack {
            Image(systemName: "doc.on.clipboard")
                .foregroundColor(.gray)
                .onTapGesture {
                    if let pastedkey = UIPasteboard.general.string {
                        self.key.wrappedValue = pastedkey
                    }
                }
            TextField("", text: key)
                .placeholder(when: key.wrappedValue.isEmpty) {
                    Text(title).foregroundColor(.white.opacity(0.6))
                }
                .padding(10)
                .autocapitalization(.none)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .font(.body.monospaced())
                .textContentType(.password)
        }
        .padding(.horizontal, 10)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray, lineWidth: 1)
        }
    }
}

struct SignInHeader: View {
    var body: some View {
        VStack {
            Image("logo-nobg")
                .resizable()
                .frame(width: 56, height: 56, alignment: .center)
                .shadow(color: DamusColors.purple, radius: 2)
                .padding(.bottom)
            
            Text("Sign in", comment: "Title of view to log into an account.")
                .font(.system(size: 32, weight: .bold))
                .padding(.bottom, 5)
            
            Text("Welcome to the social network you control", comment: "Welcome text")
                .foregroundColor(Color("DamusMediumGrey"))
        }
    }
}

struct SignInEntry: View {
    let key: Binding<String>
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Enter your account key", comment: "Prompt for user to enter an account key to login.")
                .fontWeight(.medium)
                .padding(.top, 30)
            
            KeyInput(NSLocalizedString("nsec1...", comment: "Prompt for user to enter in an account key to login. This text shows the characters the key could start with if it was a private key."), key: key)
        }
    }
}

struct CreateAccountPrompt: View {
    @Binding var create_account: Bool
    var body: some View {
        HStack {
            Text("New to nostr?", comment: "Ask the user if they are new to nostr")
                .foregroundColor(Color("DamusMediumGrey"))
            
            Button(NSLocalizedString("Create account", comment: "Button to navigate to create account view.")) {
                create_account.toggle()
            }
            
            Spacer()
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
//        let pubkey = "3efdaebb1d8923ebd99c9e7ace3b4194ab45512e2be79c1b7d68d9243e0d2681"
        let pubkey = "npub18m76awca3y37hkvuneavuw6pjj4525fw90necxmadrvjg0sdy6qsngq955"
        let bech32_pubkey = "KeyInput"
        Group {
            LoginView(key: pubkey, accepted: .constant(true))
            LoginView(key: bech32_pubkey, accepted: .constant(true))
        }
    }
}
