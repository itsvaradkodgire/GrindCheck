import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: AppColors.muted))

            Text(title)
                .font(.headline)
                .foregroundStyle(.white)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color(hex: AppColors.neutral))
                .multilineTextAlignment(.center)

            if let label = actionLabel, let action {
                Button(label, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: AppColors.primary))
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}
