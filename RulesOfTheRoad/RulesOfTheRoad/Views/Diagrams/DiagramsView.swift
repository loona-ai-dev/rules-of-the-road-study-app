import SwiftUI

// MARK: - Diagrams View

struct DiagramsView: View {
    @State private var selectedDiagram: Int?
    @State private var searchText = ""

    let diagramCount = 87

    var filteredDiagrams: [Int] {
        if searchText.isEmpty {
            return Array(1...diagramCount)
        }
        let nums = Array(1...diagramCount).filter {
            "diagram \($0)".contains(searchText.lowercased()) ||
            "\($0)".contains(searchText)
        }
        return nums
    }

    let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        // Search bar
                        searchBar

                        // Grid
                        if filteredDiagrams.isEmpty {
                            emptyState
                        } else {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(filteredDiagrams, id: \.self) { num in
                                    DiagramThumbnail(
                                        number: num,
                                        onTap: { selectedDiagram = num }
                                    )
                                }
                            }
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Diagrams")
                        .font(RORFont.headerMed)
                        .foregroundColor(.gold)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(diagramCount)")
                        .font(RORFont.mono)
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .fullScreenCover(item: Binding(
                get: { selectedDiagram.map { IdentifiableInt(value: $0) } },
                set: { selectedDiagram = $0?.value }
            )) { item in
                DiagramDetailView(diagramNumber: item.value)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))

            TextField("Search diagrams...", text: $searchText)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .tint(.gold)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassPanel(cornerRadius: 12)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.fill")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.2))
            Text("No diagrams found")
                .font(RORFont.label)
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.top, 60)
    }
}

// MARK: - Diagram Thumbnail

struct DiagramThumbnail: View {
    let number: Int
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Image
                Group {
                    if let image = UIImage(named: "diagram_\(number)") {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        // Placeholder
                        ZStack {
                            Color.white.opacity(0.05)
                            VStack(spacing: 6) {
                                Image(systemName: "photo")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white.opacity(0.2))
                                Text("DGM \(number)")
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                    }
                }
                .frame(height: 90)
                .clipped()

                // Label
                Text("Diagram \(number)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(Color.navyDeep.opacity(0.6))
            }
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Diagram Detail View

struct DiagramDetailView: View {
    let diagramNumber: Int
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image = UIImage(named: "diagram_\(diagramNumber)") {
                GeometryReader { geo in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = max(1.0, min(lastScale * value, 5.0))
                                    }
                                    .onEnded { _ in
                                        lastScale = scale
                                        if scale < 1.0 {
                                            withAnimation(.spring()) { scale = 1.0; offset = .zero }
                                            lastScale = 1.0
                                            lastOffset = .zero
                                        }
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        guard scale > 1.0 else { return }
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring(response: 0.4)) {
                                if scale > 1.0 {
                                    scale = 1.0
                                    offset = .zero
                                    lastScale = 1.0
                                    lastOffset = .zero
                                } else {
                                    scale = 2.5
                                    lastScale = 2.5
                                }
                            }
                        }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.3))
                    Text("Diagram \(diagramNumber)")
                        .font(RORFont.headerMed)
                        .foregroundColor(.white.opacity(0.6))
                    Text("Image not found in bundle.\nAdd diagram_\(diagramNumber).jpg to Assets.xcassets")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .padding(40)
            }

            // Controls overlay
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .overlay(Circle().strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5))
                            )
                    }
                    .padding(.leading, 20)
                    .padding(.top, 60)

                    Spacer()

                    Text("Diagram \(diagramNumber)")
                        .font(RORFont.label)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.6))
                        )
                        .padding(.trailing, 20)
                        .padding(.top, 60)
                }
                Spacer()

                // Pinch hint
                if scale == 1.0 {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 11))
                        Text("Pinch to zoom • Double-tap to zoom")
                            .font(RORFont.label)
                    }
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.black.opacity(0.5)))
                    .padding(.bottom, 40)
                }
            }
        }
        .ignoresSafeArea()
        .statusBar(hidden: true)
    }
}

// MARK: - Helper

struct IdentifiableInt: Identifiable {
    let value: Int
    var id: Int { value }
}
