//
//  DamusGradient.swift
//  damus
//
//  Created by William Casarin on 2023-05-09.
//

import SwiftUI

fileprivate let damus_grad_c1 = hex_col(r: 0xe7, g: 0xc4, b: 0x83)
fileprivate let damus_grad_c2 = hex_col(r: 0xf2, g: 0xa3, b: 0x3c)
fileprivate let damus_grad_c3 = hex_col(r: 0xf5, g: 0x95, b: 0x21)
fileprivate let damus_grad = [damus_grad_c1, damus_grad_c2, damus_grad_c3]

struct DamusGradient: View {
    var body: some View {
        DamusGradient.gradient
            .edgesIgnoringSafeArea([.top,.bottom])
    }
    
    static var gradient: LinearGradient {
         LinearGradient(colors: damus_grad, startPoint: .bottomLeading, endPoint: .topTrailing)
    }
}

struct DamusGradient_Previews: PreviewProvider {
    static var previews: some View {
        DamusGradient()
    }
}
