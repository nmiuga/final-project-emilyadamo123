//
//  ContentView.swift
//  Travel-Tracker
//
//  Created by Emily Adamo on 4/21/26.
//

import SwiftUI
import Foundation
internal import Combine

// MARK: - Models (API + App)
// These types model the REST Countries API and the app's saved state.
// Endpoint used:
// https://restcountries.com/v3.1/all?fields=name,capital,population,region,flags,cca2

/// Top-level country model decoded from the REST Countries API.
struct Country: Identifiable, Codable, Hashable {
    // We use the two-letter country code as a stable identifier.
    let id: String // maps to `cca2`
    let name: CountryName
    let capital: [String]? // Some countries have multiple or no capitals
    let population: Int
    let region: String
    let flags: CountryFlags

    enum CodingKeys: String, CodingKey {
        case id = "cca2"
        case name
        case capital
        case population
        case region
        case flags
    }

    /// Convenience: primary capital string or "—" if missing.
    var capitalDisplay: String { capital?.first ?? "—" }
}

/// Nested name object from the API.
struct CountryName: Codable, Hashable { let common: String }

/// Nested flags object from the API.
struct CountryFlags: Codable, Hashable { let png: String?; let svg: String? }

/// The category a user can assign to a country.
enum SavedCategory: String, Codable, CaseIterable, Identifiable {
    case been
    case want
    var id: String { rawValue }
    var title: String { self == .been ? "Been To" : "Want to Visit" }
}

/// A saved country entry with optional visit date.
struct SavedCountry: Identifiable, Codable, Hashable {
    let id: String // country code (cca2)
    let category: SavedCategory
    var visitDate: Date?
}

// MARK: - ViewModel
/// View model responsible for fetching countries and managing UI state.
@MainActor
final class CountriesViewModel: ObservableObject {
//    var objectWillChange: ObservableObjectPublisher
    
    // Published arrays for UI consumption
    @Published private(set) var allCountries: [Country] = []
    @Published var searchText: String = ""
    @Published var activeFilter: SavedCategoryFilter = .all

    // Saved selections keyed by country id
    @Published private(set) var saved: [String: SavedCountry] = [:]

    /// Simple filter enum to control the list view
    enum SavedCategoryFilter { case all, been, want }

    /// Computed countries after applying search and filters
    var visibleCountries: [Country] {
        var list = allCountries
        // Search by name
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchText.lowercased()
            list = list.filter { $0.name.common.lowercased().contains(query) }
        }
        // Apply saved filter
        switch activeFilter {
        case .all:
            break
        case .been:
            list = list.filter { saved[$0.id]?.category == .been }
        case .want:
            list = list.filter { saved[$0.id]?.category == .want }
        }
        return list
    }

    /// Async loader for the REST Countries API
    func loadCountries() async {
        // If we've already loaded, avoid re-fetching
        if !allCountries.isEmpty { return }
        do {
            let url = URL(string: "https://restcountries.com/v3.1/all?fields=name,capital,population,region,flags,cca2")!
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                throw URLError(.badServerResponse)
            }
            let decoded = try JSONDecoder().decode([Country].self, from: data)
            // Sort alphabetically for nicer UX
            self.allCountries = decoded.sorted { $0.name.common < $1.name.common }
        } catch {
            print("Failed to load countries:", error)
        }
    }

    /// Toggle save state for a country with a given category.
    func save(_ country: Country, as category: SavedCategory) {
        if let existing = saved[country.id], existing.category == category {
            // If already saved in the same category, remove it (acts as a toggle)
            saved[country.id] = nil
        } else {
            saved[country.id] = SavedCountry(id: country.id, category: category, visitDate: saved[country.id]?.visitDate)
        }
    }

    /// Update visit date for a saved country.
    func setVisitDate(_ date: Date?, for country: Country) {
        guard var entry = saved[country.id] else { return }
        entry.visitDate = date
        saved[country.id] = entry
    }

    /// Helper to check if a country is saved in a category.
    func isSaved(_ country: Country, as category: SavedCategory) -> Bool {
        saved[country.id]?.category == category
    }
}

// MARK: - Views
/// Root view for the Travel Tracker app.
/// It wires up the `CountriesViewModel` and presents the main list UI.
struct ContentView: View {
    // The view model holds fetched countries, search text, and saved selections.
    @StateObject private var viewModel = CountriesViewModel()

    // Simple palette used across the app.
    private let darkGreen = Color(red: 22/255, green: 75/255, blue: 57/255)
    private let lightPink = Color(red: 255/255, green: 175/255, blue: 204/255)
    private let skyBlue = Color(red: 162/255, green: 210/255, blue: 255/255)
    private let medBlue = Color(red: 33/255, green: 158/255, blue: 188/255)
    private let beenGreen = Color(red: 76/255, green: 175/255, blue: 80/255)
    private let toVisitOrange = Color(red: 255/255, green: 159/255, blue: 67/255)
    

    var body: some View {
        NavigationStack {
            CountriesListView()
                .environmentObject(viewModel)
        }
        .tint(darkGreen)
        .task {
            // Fetch on first appearance
            await viewModel.loadCountries()
        }
    }
}

/// Main list view showing countries from the API with search and filters.
struct CountriesListView: View {
    @EnvironmentObject private var viewModel: CountriesViewModel

    // Basic palette
    private let darkGreen = Color(red: 22/255, green: 75/255, blue: 57/255)
    private let lightPink = Color(red: 255/255, green: 175/255, blue: 204/255)
    private let skyBlue = Color(red: 162/255, green: 210/255, blue: 255/255)
    private let medBlue = Color(red: 33/255, green: 158/255, blue: 188/255)
    private let beenGreen = Color(red: 76/255, green: 175/255, blue: 80/255)
    private let toVisitOrange = Color(red: 255/255, green: 159/255, blue: 67/255)
    

    var body: some View {
        VStack(spacing: 0) {

            // HEADER (fixed)
            VStack(spacing: 4) {
                Text("Travel Tracker")
                    .font(.system(size: 50, weight: .bold))
                    .padding(.top, 10)
                    .foregroundStyle(Color.white)
//                    .foregroundStyle(darkGreen)

                Text("Countries travelled to: \(viewModel.saved.values.filter { $0.category == .been }.count)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.white)
//                    .foregroundStyle(medBlue)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)
            .background(lightPink)

            // SEARCH BAR (custom, below header)
            TextField(
                text: $viewModel.searchText,
                prompt: Text("Search countries").foregroundStyle(darkGreen.opacity(0.7))
            ) {
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.75))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(darkGreen.opacity(0.35), lineWidth: 1)
                    )
            )
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .tint(medBlue)
            .background(lightPink)

            // Custom segmented control (below search)
            HStack(spacing: 0) {
                ForEach([
                    CountriesViewModel.SavedCategoryFilter.all,
                    .been,
                    .want
                ], id: \.self) { filter in
                    Button {
                        viewModel.activeFilter = filter
                    } label: {
                        Text(label(for: filter))
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                viewModel.activeFilter == filter
                                ? (filter == .been ? beenGreen : filter == .want ? toVisitOrange : medBlue)
                                : Color.white.opacity(0.6)
                            )
                            .foregroundStyle(
                                viewModel.activeFilter == filter
                                ? Color.white
                                : darkGreen
                            )
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(darkGreen.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(lightPink)
            
            // LIST
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.visibleCountries) { country in
                        NavigationLink(value: country) {
                            CountryRow(country: country)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationDestination(for: Country.self) { country in
                CountryDetailView(country: country)
            }
            .background(lightPink)
        }
    }

    /// A single row with flag, name and quick save buttons.
    @ViewBuilder
    private func CountryRow(country: Country) -> some View {
        HStack(spacing: 14) {
            FlagView(country: country)
                .frame(width: 48, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.2)))

            VStack(alignment: .leading, spacing: 4) {
                Text(country.name.common)
                    .font(.headline)
                    .foregroundStyle(darkGreen)
                Text(country.capitalDisplay)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            // Quick save buttons
            HStack(spacing: 8) {
                SavePill(title: "Been", isActive: viewModel.isSaved(country, as: .been), color: beenGreen) {
                    viewModel.save(country, as: .been)
                }
                SavePill(title: "To Visit", isActive: viewModel.isSaved(country, as: .want), color: toVisitOrange) {
                    viewModel.save(country, as: .want)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.white.opacity(0.06), radius: 6, x: 0, y: 3)
        )
    }

    /// A small, rounded button used to mark a save category.
    private func SavePill(title: String, isActive: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(isActive ? color : medBlue.opacity(0.2))
                )
                .foregroundStyle(isActive ? Color.white : Color.secondary)
        }
        .buttonStyle(.plain)
    }

    private func label(for filter: CountriesViewModel.SavedCategoryFilter) -> String {
        switch filter {
        case .all:
            return "All"
        case .been:
            return "Been"
        case .want:
            return "Wishlist"
        }
    }
}

/// Shows detailed information about a country and allows saving with an optional date.
struct CountryDetailView: View {
    let country: Country
    @EnvironmentObject private var viewModel: CountriesViewModel

    // Palette
    private let darkGreen = Color(red: 22/255, green: 75/255, blue: 57/255)
    private let lightPink = Color(red: 255/255, green: 230/255, blue: 236/255)
    private let skyBlue = Color(red: 162/255, green: 210/255, blue: 255/255)
    
    // Local date state bound to the view model when changed
    @State private var selectedDate: Date? = nil
    @State private var includeDate: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Section 1: Header Card
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 12) {
                            FlagView(country: country)
                                .frame(width: 96, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                            VStack(alignment: .leading, spacing: 6) {
                                Text(country.name.common)
                                    .font(.title.bold())
                                    .foregroundStyle(darkGreen)
                                Text("Region: \(country.region)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } label: {
                    Text("Overview").font(.headline)
                }

                // Section 2: Facts Card
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(label: "Capital", value: country.capitalDisplay)
                        InfoRow(label: "Population", value: country.population.formatted())
                        InfoRow(label: "Region", value: country.region)
                    }
                } label: {
                    Text("Details").font(.headline)
                }

                // Section 3: Save Options Card
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            TogglePill(title: "Been To", category: .been)
                            TogglePill(title: "Want to Visit", category: .want)
                        }
                        Divider()
                        Toggle("Add visit date", isOn: $includeDate.animation())
                        if includeDate {
                            DatePicker("Visit Date", selection: Binding(get: {
                                selectedDate ?? Date()
                            }, set: { newValue in
                                selectedDate = newValue
                                viewModel.setVisitDate(newValue, for: country)
                            }), displayedComponents: .date)
                            .datePickerStyle(.compact)
                        }
                    }
                } label: {
                    Text("Save").font(.headline)
                }
            }
            .padding()
        }
        .onAppear {
            // Initialize local date controls based on saved state
            if let entry = viewModel.saved[country.id] {
                includeDate = entry.visitDate != nil
                selectedDate = entry.visitDate
            }
        }
        .navigationTitle(country.name.common)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    private func InfoRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.subheadline.weight(.semibold)).foregroundStyle(darkGreen)
            Spacer()
            Text(value).font(.body).foregroundStyle(.primary)
        }
    }

    private func TogglePill(title: String, category: SavedCategory) -> some View {
        let isActive = viewModel.isSaved(country, as: category)
        return Button {
            viewModel.save(country, as: category)
        } label: {
            Text(title)
                .font(.body.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(isActive ? darkGreen : lightPink.opacity(0.4)))
                .foregroundStyle(isActive ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }
}

struct FlagView: View {
    let country: Country

    private var flagURL: URL? {
        let code = country.id.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return URL(string: "https://flagsapi.com/\(code)/flat/64.png")
    }

    var body: some View {
        Group {
            if let url = flagURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .clipped()
    }

    private var placeholder: some View {
        ZStack {
            Color.gray.opacity(0.1)
            Image(systemName: "photo")
                .foregroundStyle(.secondary)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    ContentView()
}
