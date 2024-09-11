// Author: SwiftUI-Lab (swiftui-lab.com)
// Description: Implementation of the showSizes() debugging modifier
// blog article: https://swiftui-lab.com/layout-protocol-part-2

import SwiftUI

extension View {
  // If proposal is nil, get min, ideal and max sizes
  @ViewBuilder func showSizes(_ proposals: [MeasureLayout.SizeRequest] = [.minimum, .ideal, .maximum]) -> some View {
    Measure(proposals: proposals) { self }
  }
}

struct Measure<V: View>: View {
  @State private var reportedSizes: [CGSize] = []

  let proposals: [MeasureLayout.SizeRequest]
  @ViewBuilder let content: () -> V

  var body: some View {
    MeasureLayout {
      content()
        .layoutValue(key: MeasureLayout.InfoRequest.self, value: proposals)
        .layoutValue(key: MeasureLayout.InfoReply.self, value: $reportedSizes)
        .overlay(alignment: .topTrailing) {
          Text(mergedSizes)
            .background(.gray)
            .foregroundColor(.white)
            .font(.caption)
            .offset(y: -20)
            .fixedSize()
        }
    }
  }

  var mergedSizes: String {
    String(reportedSizes.map { String(format: "(%.1f, %.1f)", $0.width, $0.height) }.joined(separator: " - "))
  }
}

struct MeasureLayout: Layout {
  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    subviews[0].sizeThatFits(proposal)
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    DispatchQueue.main.async {
      subviews[0][InfoReply.self]?.wrappedValue = subviews[0][InfoRequest.self]
        .map {
          $0.size(view: subviews[0], proposal: proposal)
        }
    }

    subviews[0].place(at: CGPoint(x: bounds.midX, y: bounds.midY), anchor: .center, proposal: proposal)
  }

  struct InfoRequest: LayoutValueKey {
    static var defaultValue: [SizeRequest] = []
  }

  struct InfoReply: LayoutValueKey {
    static var defaultValue: Binding<[CGSize]>?
  }

  enum SizeRequest {
    case minimum
    case ideal
    case maximum
    case current
    case proposal(size: ProposedViewSize)

    func size(view: LayoutSubview, proposal: ProposedViewSize) -> CGSize {
      switch self {
      case .minimum: return view.sizeThatFits(.zero)
      case .ideal: return view.sizeThatFits(.unspecified)
      case .maximum: return view.sizeThatFits(.infinity)
      case .current: return view.sizeThatFits(proposal)
      case .proposal(let prop): return view.sizeThatFits(prop)
      }
    }
  }
}
