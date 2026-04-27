import Observation
import StoreKit

// MARK: - Product identifiers

enum SubscriptionProductID {
    static let monthly = "com.spirogears.monthly"
    static let annual  = "com.spirogears.annual"
    static let all: [String] = [monthly, annual]
}

// MARK: - Entitlement

enum Entitlement: Equatable {
    case free
    case subscribed   // covers both trial and paid
}

// MARK: - SubscriptionStore

@Observable
final class SubscriptionStore {
    private(set) var entitlement: Entitlement = .free
    private(set) var products: [Product] = []
    private(set) var purchaseError: String? = nil
    private(set) var isPurchasing = false

    /// Maximum drawings a free-tier user may create (persisted across sessions).
    static let freeTierDrawingLimit = 3
    /// Maximum saved drawings for free-tier users.
    static let freeTierSaveLimit = 3
    /// Maximum layers per drawing for free-tier users.
    static let freeTierLayerLimit = 5

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = listenForTransactionUpdates()
        Task { @MainActor in
            await self.loadProducts()
            await self.refreshEntitlement()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Products

    @MainActor
    func loadProducts() async {
        do {
            products = try await Product.products(for: SubscriptionProductID.all)
                .sorted { $0.price < $1.price }
        } catch {
            products = []
        }
    }

    // MARK: - Purchase

    @MainActor
    func purchase(_ product: Product) async {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlement()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Restore

    @MainActor
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlement()
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Entitlement refresh

    @MainActor
    func refreshEntitlement() async {
#if DEBUG
        entitlement = .subscribed
        return
#endif
        
        var hasActive = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               tx.revocationDate == nil,
               tx.expirationDate.map({ $0 > Date() }) ?? true {
                hasActive = true
                break
            }
        }
        entitlement = hasActive ? .subscribed : .free
    }

    // MARK: - Transaction updates listener

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.refreshEntitlement()
                }
            }
        }
    }

    // MARK: - Verification helper

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let value): return value
        }
    }
}
