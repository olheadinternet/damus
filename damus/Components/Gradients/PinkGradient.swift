//
//  PinkGradient.swift
//  damus
//
//  Created by eric on 5/20/23.
//

import SwiftUI

fileprivate let damus_grad_c1 = hex_col(r: 0x00, g: 0xff, b: 0x00)
fileprivate let damus_grad_c2 = hex_col(r: 0x00, g: 0x00, b: 0xff)
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

