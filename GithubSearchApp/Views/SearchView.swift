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
                
                if case .search = viewModel.mode {
                    searchBarView
                }
                
                switch viewModel.displayResult {
                case .success(let successBodyType):
                    successBodyView(successBodyType)
                case .empty:
                    emptyView
                case .failure(let errorMessage):
                    failureView(errorMessage)
                case .loading:
                    loadingView
                case .initial:
                    initialView
                }
            }
            .navigationTitle("GitHub Search")
            .navigationDestination(for: User.self) { user in
                UserProfileView(username: user.login)
            }
        }
    }
    
    private var searchBarView: some View {
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
    }
    
    private func successBodyView(_ successBodyType: SearchViewModel.DisplayResult.SuccessBodyType) -> some View {
        switch successBodyType {
        case .favoites(let favoriteUsers):
            List(favoriteUsers) { user in
                UserRow(userRowUIModel: user)
            }
            .listStyle(PlainListStyle())
        case .searchResult(let searchResults):
            List(searchResults) { user in
                UserRow(userRowUIModel: user)
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No users found")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxHeight: .infinity)
    }
    
    private func failureView(_ errorMessage: String) -> some View {
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
    }
    
    private var loadingView: some View {
        Group {
            Spacer()
            ProgressView("Searching...")
            Spacer()
        }
    }
    
    private var initialView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Search for GitHub users")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxHeight: .infinity)
    }
}
