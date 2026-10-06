//
//  FreemiumView.swift
//  JustZenGo
//
//  Freemium Tier UI for JustZenGo
//

import SwiftUI

struct FreemiumView: View {
    @StateObject private var viewModel = FreemiumViewModel()
    @State private var showingPaywall = false

    var body: some View {
        ZStack {
            Color(hex: "1C1C1E")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                            Text("Free Tier Active")
                                .font(.headline)
                                .foregroundColor(.green)
                            Spacer()
                            Text("VIP Lv.\(viewModel.vipLevel)")
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.15))
                                .cornerRadius(8)
                        }

                        Divider()
                            .background(Color.gray.opacity(0.3))

                        HStack {
                            Label("Zen Credits", systemImage: "sparkles")
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(viewModel.credits)")
                                .font(.title2.bold())
                                .foregroundColor(.yellow)
                        }

                        HStack {
                            Text("Daily Practice Bonus:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                            Button {
                                Task { await viewModel.signIn() }
                            } label: {
                                Text(viewModel.signedInToday ? "Claimed (+10)" : "Claim Today (+10)")
                                    .font(.subheadline.bold())
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .disabled(viewModel.signedInToday)
                        }
                    }
                    .padding()
                    .background(Color(hex: "2C2C2E"))
                    .cornerRadius(16)

                    Button {
                        showingPaywall = true
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            Text("Unlock Pro Breathing & Soundscapes")
                                .foregroundColor(.white)
                                .bold()
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(hex: "2C2C2E"))
                        .cornerRadius(12)
                    }

                    Text("All basic breathing protocols and local timers remain 100% free forever.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            }
        }
        .navigationTitle("Zen Credits & Pass")
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
}

@MainActor
class FreemiumViewModel: ObservableObject {
    @Published var credits: Int = BuyservicesClient.freeTier.creditsOnRegister
    @Published var vipLevel: Int = BuyservicesClient.freeTier.vipLevelAuto
    @Published var signedInToday: Bool = false

    func signIn() async {
        guard !signedInToday else { return }
        credits += BuyservicesClient.freeTier.signinDaily
        signedInToday = true
    }
}
