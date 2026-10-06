//
//  PaywallView.swift
//  JustZenGo
//
//  Self-Service Paywall for JustZenGo
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var openAIKey = ""
    @State private var isSavedKey = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.yellow)
                            Text("JustZenGo Pro Pass")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            Text("Unlock Eyes-Free Haptics, Resonant Frequencies, and HRV Analytics")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top)

                        VStack(spacing: 12) {
                            Button {} label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Monthly Subscription")
                                            .font(.headline)
                                        Text("$4.99 / month")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Text("Subscribe")
                                        .bold()
                                }
                                .padding()
                                .background(Color(hex: "2C2C2E"))
                                .cornerRadius(12)
                            }

                            Button {} label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Annual Pass (Best Value)")
                                            .font(.headline)
                                        Text("$29.99 / year")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Text("Save 50%")
                                        .bold()
                                        .foregroundColor(.green)
                                }
                                .padding()
                                .background(Color(hex: "2C2C2E"))
                                .cornerRadius(12)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bring Your Own API Key (Optional)")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                            HStack {
                                SecureField("OpenAI API Key (sk-...)", text: $openAIKey)
                                    .padding(10)
                                    .background(Color(hex: "2C2C2E"))
                                    .cornerRadius(8)
                                Button(isSavedKey ? "Saved" : "Save") {
                                    isSavedKey = true
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(openAIKey.isEmpty)
                            }
                        }
                        .padding(.top, 10)

                        Text("Subscription billed via PayPal or Apple Pay. Cancel anytime in account settings.")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
}
