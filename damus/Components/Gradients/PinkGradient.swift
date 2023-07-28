//
//  PinkGradient.swift
//  damus
//
//  Created by eric on 5/20/23.
//

import SwiftUI

fileprivate let damus_grad_c1 = hex_col(r: 0xf5, g: 0x95, b: 0x21)
fileprivate let damus_grad_c2 = hex_col(r: 0xf2, g: 0xa3, b: 0x3c)
fileprivate let pink_grad = [damus_grad_c1, damus_grad_c2]

let PinkGradient = LinearGradient(colors: pink_grad, startPoint: .topTrailing, endPoint: .bottom)

struct PinkGradientView: View {
    var body: some View {
        PinkGradient
            .edgesIgnoringSafeArea([.top,.bottom])
    }
}

struct PinkGradientView_Previews: PreviewProvider {
    static var previews: some View {
        PinkGradientView()
    }
}

