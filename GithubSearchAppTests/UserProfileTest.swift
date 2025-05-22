import ComposableArchitecture
import Testing
import Foundation

@MainActor
struct UserProfileTest {
    @Test
    func onAppear_success() async {
        let repositories: [Repository] = (1...10).map { Repository.mock(id: $0) }
        let userDetail = UserDetail.mock(id: 1)
        let store = TestStoreOf<UserProfile>(
            initialState: UserProfile.State.init(
                userName: "mock",
                userProfileHeaderDisplayResult: .initial,
                userProfileRepositoriesDisplayResult: .initial
            )
        ) {
            UserProfile()
        } withDependencies: {
            $0.networkService.getUserRepositories = { _ in
                repositories
            }
            $0.networkService.getUserDetails = { _ in
                userDetail
            }
        }
        await store.send(.view(.onAppear)) {
            $0.userProfileHeaderDisplayResult = .loading
            $0.userProfileRepositoriesDisplayResult = .loading
        }
                    
        await store.receive(\.internal.didReceiveUserDetailResult.success) {
            $0.userProfileHeaderDisplayResult = .success(userDetail)
        }
        await store.receive(\.internal.didReceiveRepositorieslResult.success) {
            $0.userProfileRepositoriesDisplayResult = .success(repositories)
        }
    }
    
    @Test
    func onAppear_failure() async {
        let store = TestStoreOf<UserProfile>(
            initialState: UserProfile.State.init(
                userName: "mock",
                userProfileHeaderDisplayResult: .initial,
                userProfileRepositoriesDisplayResult: .initial
            )
        ) {
            UserProfile()
        } withDependencies: {
            $0.networkService.getUserRepositories = { _ in
                throw UserProfileTestError()
            }
            $0.networkService.getUserDetails = { _ in
                throw UserProfileTestError()
            }
        }
        await store.send(.view(.onAppear)) {
            $0.userProfileHeaderDisplayResult = .loading
            $0.userProfileRepositoriesDisplayResult = .loading
        }
                    
        await store.receive(\.internal.didReceiveUserDetailResult.failure) {
            $0.userProfileHeaderDisplayResult = .failure("Unknown error: Test error")
        }
        await store.receive(\.internal.didReceiveRepositorieslResult.failure) {
            $0.userProfileRepositoriesDisplayResult = .failure("Unknown error: Test error")
        }
    }
    
    @Test
    func didTapRetryFetchUserDetailButton() async {
        let userDetail = UserDetail.mock(id: 1)
        let store = TestStoreOf<UserProfile>(
            initialState: UserProfile.State.init(
                userName: "mock",
                userProfileHeaderDisplayResult: .failure("Test error"),
                userProfileRepositoriesDisplayResult: .initial
            )
        ) {
            UserProfile()
        } withDependencies: {
            $0.networkService.getUserDetails = { _ in
                userDetail
            }
        }
        
        await store.send(.view(.didTapRetryFetchUserDetailButton)) {
            $0.userProfileHeaderDisplayResult = .loading
        }
        
        await store.receive(\.internal.didReceiveUserDetailResult.success) {
            $0.userProfileHeaderDisplayResult = .success(userDetail)
        }
    }
    
    @Test
    func didTapRetryFetchRepositoriesButton() async {
        let repositories: [Repository] = (1...10).map { Repository.mock(id: $0) }

        let store = TestStoreOf<UserProfile>(
            initialState: UserProfile.State.init(
                userName: "mock",
                userProfileHeaderDisplayResult: .initial,
                userProfileRepositoriesDisplayResult: .failure("Test error")
            )
        ) {
            UserProfile()
        } withDependencies: {
            $0.networkService.getUserRepositories = { _ in
                repositories
            }
        }
        
        await store.send(.view(.didTapRetryFetchRepositoriesButton)) {
            $0.userProfileRepositoriesDisplayResult = .loading
        }
        
        await store.receive(\.internal.didReceiveRepositorieslResult.success) {
            $0.userProfileRepositoriesDisplayResult = .success(repositories)
        }
    }
}

extension UserProfileTest {
    struct UserProfileTestError: LocalizedError, Equatable {
        var errorDescription: String? {
            return "Test error"
        }
    }
}
