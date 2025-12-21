//
//  NumberPad.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import SwiftUI

struct NumberPad: View {
    let onNumberTap: (String) -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Row 1: 1, 2, 3
            HStack(spacing: 12) {
                NumberButton(number: "1", action: { onNumberTap("1") })
                NumberButton(number: "2", action: { onNumberTap("2") })
                NumberButton(number: "3", action: { onNumberTap("3") })
            }
            
            // Row 2: 4, 5, 6
            HStack(spacing: 12) {
                NumberButton(number: "4", action: { onNumberTap("4") })
                NumberButton(number: "5", action: { onNumberTap("5") })
                NumberButton(number: "6", action: { onNumberTap("6") })
            }
            
            // Row 3: 7, 8, 9
            HStack(spacing: 12) {
                NumberButton(number: "7", action: { onNumberTap("7") })
                NumberButton(number: "8", action: { onNumberTap("8") })
                NumberButton(number: "9", action: { onNumberTap("9") })
            }
            
            // Row 4: ., 0, Delete
            HStack(spacing: 12) {
                NumberButton(number: ".", action: { onNumberTap(".") })
                NumberButton(number: "0", action: { onNumberTap("0") })
                DeleteButton(action: onDelete)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct NumberButton: View {
    let number: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.system(size: 32, weight: .black))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 80)
        }
        .buttonStyle(.plain)
    }
}

struct DeleteButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "delete.backward")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 80)
        }
        .buttonStyle(.plain)
    }
}

