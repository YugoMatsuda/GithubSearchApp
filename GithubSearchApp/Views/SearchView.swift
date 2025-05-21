import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    
    var body: some View {
        NavigationStack(path: $viewModel.path) {
            VStack {
                Picker("Mode", selection: $viewModel.mode) {
                    ForEach(SearchViewModel.Mode.allCases) { mode in
                        Text(mode.title)
                            .tag(mode)
                            
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                switch viewModel.mode {
                case .search:
                    seatchResultBody
                case .favorites:
                    favoriteBody
                }
            }
            .navigationTitle("GitHub Search")
            .navigationDestination(for: User.self) { user in
                UserProfileView(username: user.login)
            }
        }
    }
    
    @ViewBuilder
    var seatchResultBody: some View {
        // Search bar
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search GitHub users...", text: $viewModel.searchText)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
        
        // Results or placeholder
        if !viewModel.hasSearched {
            VStack(spacing: 20) {
                Image(systemName: "person.3")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("Search for GitHub users")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            .frame(maxHeight: .infinity)
        } else if viewModel.isLoading {
            Spacer()
            ProgressView("Searching...")
            Spacer()
        } else if let errorMessage = viewModel.errorMessage {
            VStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                    .padding()
                
                Text(errorMessage)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .frame(maxHeight: .infinity)
        } else if viewModel.users.isEmpty && viewModel.hasSearched {
            VStack(spacing: 20) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("No users found")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            .frame(maxHeight: .infinity)
        } else {
            List {
                ForEach(viewModel.userRowUIModels) { user in
                    UserRow(userRowUIModel: user)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    @ViewBuilder
    var favoriteBody: some View {
        if viewModel.facfavoriteUserRowUIModel.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("No users found")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            .frame(maxHeight: .infinity)
        } else {
            List(viewModel.facfavoriteUserRowUIModel) { user in
                UserRow(userRowUIModel: user)
            }
            .listStyle(PlainListStyle())
        }
    }
}
