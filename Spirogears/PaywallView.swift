import StoreKit
import SwiftUI

// Identifiable wrapper used as the `.sheet(item:)` trigger in ContentView.
// Carrying the feature string in the item avoids the timing issue where a
// Bool-based sheet can capture a stale feature string from a prior render.
struct PaywallRequest: Identifiable {
    let id = UUID()
    let feature: String
}

struct PaywallView: View {
    /// Short description of the feature being unlocked (e.g. "Animation").
    let feature: String
    let onDismiss: () -> Void

    @Environment(SubscriptionStore.self) private var store
    @State private var selectedProductID: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    trialBadge
                    productList
                    subscribeButton
                    footer
                }
                .padding(.top, 32)
                .padding(.bottom, 24)
            }
            .navigationTitle("Spirogears Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not Now") { onDismiss() }
                }
            }
            .onChange(of: store.entitlement) { _, newValue in
                if newValue == .subscribed { onDismiss() }
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 52))
                .foregroundStyle(.yellow)
            Text("\(feature) is a Pro feature")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("Subscribe for unlimited saved drawings, unlimited layers per drawing, and future Pro features.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }

    private var trialBadge: some View {
        Text("7-day free trial — cancel anytime")
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.yellow.opacity(0.18), in: Capsule())
    }

    private var productList: some View {
        VStack(spacing: 12) {
            if store.products.isEmpty {
                ProgressView()
                    .padding()
            } else {
                ForEach(store.products, id: \.id) { product in
                    ProductRow(product: product, isSelected: effectiveSelection == product.id)
                        .onTapGesture { selectedProductID = product.id }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var subscribeButton: some View {
        Button {
            guard let product = selectedProduct else { return }
            Task { await store.purchase(product) }
        } label: {
            Group {
                if store.isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Start Free Trial")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(store.products.isEmpty ? Color.secondary : Color.blue,
                        in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.white)
        }
        .disabled(store.isPurchasing || store.products.isEmpty)
        .padding(.horizontal, 20)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Button("Restore Purchases") {
                Task { await store.restorePurchases() }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            if let err = store.purchaseError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            Text("Subscriptions renew automatically. Cancel at least 24 hours before renewal in App Store settings.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    // MARK: - Helpers

    private var effectiveSelection: String? {
        if let id = selectedProductID { return id }
        // Default to annual (last after price-ascending sort).
        return store.products.last?.id
    }

    private var selectedProduct: Product? {
        guard let id = effectiveSelection else { return nil }
        return store.products.first(where: { $0.id == id })
    }
}

// MARK: - Product row

private struct ProductRow: View {
    let product: Product
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(periodLabel)
                    .font(.headline)
                subscriptionDetail
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? .blue : .secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isSelected ? Color.blue : Color.secondary.opacity(0.35),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .contentShape(Rectangle())
    }

    private var periodLabel: String {
        switch product.subscription?.subscriptionPeriod.unit {
        case .month: return "Monthly"
        case .year:  return "Annual"
        case .week:  return "Weekly"
        case .day:   return "Daily"
        default:     return product.displayName
        }
    }

    @ViewBuilder
    private var subscriptionDetail: some View {
        let hasTrial = product.subscription?.introductoryOffer != nil
        if hasTrial {
            Text("7-day free trial, then \(product.displayPrice)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            Text(product.displayPrice)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
