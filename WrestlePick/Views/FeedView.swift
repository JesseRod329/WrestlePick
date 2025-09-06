import SwiftUI

struct FeedView: View {
    @StateObject private var socialService = SocialService.shared
    @State private var selectedFilter: FeedFilter = .all
    @State private var searchText = ""
    @State private var showingCreatePost = false
    @State private var showingSearch = false
    @State private var isLoading = false
    @State private var refreshTrigger = false
    
    var filteredPosts: [SocialPost] {
        var posts = socialService.socialPosts
        
        // Filter by selected filter
        switch selectedFilter {
        case .all:
            break
        case .predictions:
            posts = posts.filter { $0.postType == .prediction }
        case .news:
            posts = posts.filter { $0.postType == .news }
        case .achievements:
            posts = posts.filter { $0.postType == .achievement }
        case .awards:
            posts = posts.filter { $0.postType == .award }
        case .discussions:
            posts = posts.filter { $0.postType == .discussion }
        case .polls:
            posts = posts.filter { $0.postType == .poll }
        case .following:
            posts = posts.filter { socialService.followingUsers.contains { $0.userId == $0.authorId } }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            posts = posts.filter { post in
                post.content.localizedCaseInsensitiveContains(searchText) ||
                post.hashtags.contains { $0.localizedCaseInsensitiveContains(searchText) } ||
                post.mentions.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return posts
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with search and filters
                HeaderView(
                    searchText: $searchText,
                    selectedFilter: $selectedFilter,
                    showingSearch: $showingSearch,
                    showingCreatePost: $showingCreatePost
                )
                
                // Content
                if isLoading {
                    LoadingView()
                } else if filteredPosts.isEmpty {
                    EmptyStateView(selectedFilter: selectedFilter)
                } else {
                    FeedList(
                        posts: filteredPosts,
                        refreshTrigger: $refreshTrigger
                    )
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadFeed()
            }
            .refreshable {
                await refreshFeed()
            }
            .sheet(isPresented: $showingCreatePost) {
                CreatePostView()
            }
            .sheet(isPresented: $showingSearch) {
                SearchView()
            }
        }
    }
    
    private func loadFeed() {
        isLoading = true
        socialService.loadSocialPosts()
        socialService.loadFollowingUsers()
        isLoading = false
    }
    
    private func refreshFeed() async {
        socialService.loadSocialPosts()
        socialService.loadFollowingUsers()
        refreshTrigger.toggle()
    }
}

// MARK: - Feed Filter
enum FeedFilter: String, CaseIterable {
    case all = "all"
    case following = "following"
    case predictions = "predictions"
    case news = "news"
    case achievements = "achievements"
    case awards = "awards"
    case discussions = "discussions"
    case polls = "polls"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .following: return "Following"
        case .predictions: return "Predictions"
        case .news: return "News"
        case .achievements: return "Achievements"
        case .awards: return "Awards"
        case .discussions: return "Discussions"
        case .polls: return "Polls"
        }
    }
    
    var iconName: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .following: return "person.2"
        case .predictions: return "crystal.ball"
        case .news: return "newspaper"
        case .achievements: return "trophy"
        case .awards: return "star"
        case .discussions: return "bubble.left.and.bubble.right"
        case .polls: return "chart.bar"
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    @Binding var searchText: String
    @Binding var selectedFilter: FeedFilter
    @Binding var showingSearch: Bool
    @Binding var showingCreatePost: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Button(action: {
                    showingSearch = true
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        Text("Search posts, users, hashtags...")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                Button(action: {
                    showingCreatePost = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.wweBlue)
                }
            }
            .padding(.horizontal)
            
            // Filter tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FeedFilter.allCases, id: \.self) { filter in
                        FilterTab(
                            filter: filter,
                            isSelected: selectedFilter == filter,
                            onTap: {
                                selectedFilter = filter
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Filter Tab
struct FilterTab: View {
    let filter: FeedFilter
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: filter.iconName)
                    .font(.caption)
                
                Text(filter.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.wweBlue : Color(.systemGray6))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading feed...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let selectedFilter: FeedFilter
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedFilter.iconName)
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text(emptyStateTitle)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateTitle: String {
        switch selectedFilter {
        case .all: return "No Posts Yet"
        case .following: return "No Following Posts"
        case .predictions: return "No Predictions"
        case .news: return "No News Posts"
        case .achievements: return "No Achievements"
        case .awards: return "No Awards"
        case .discussions: return "No Discussions"
        case .polls: return "No Polls"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all: return "Be the first to share something with the community!"
        case .following: return "Follow some users to see their posts here"
        case .predictions: return "No prediction posts yet"
        case .news: return "No news posts yet"
        case .achievements: return "No achievement posts yet"
        case .awards: return "No award posts yet"
        case .discussions: return "No discussion posts yet"
        case .polls: return "No poll posts yet"
        }
    }
}

// MARK: - Feed List
struct FeedList: View {
    let posts: [SocialPost]
    @Binding var refreshTrigger: Bool
    
    var body: some View {
        List {
            ForEach(posts) { post in
                PostCard(post: post)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
        .id(refreshTrigger)
    }
}

// MARK: - Post Card
struct PostCard: View {
    let post: SocialPost
    @StateObject private var socialService = SocialService.shared
    @State private var showingComments = false
    @State private var showingLikes = false
    @State private var isLiked = false
    @State private var isBookmarked = false
    @State private var isShared = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author info
            HStack {
                AsyncImage(url: URL(string: post.authorAvatarURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(post.authorDisplayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if post.authorUsername != post.authorDisplayName {
                            Text("@\(post.authorUsername)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(post.timeAgo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    PostTypeBadge(type: post.postType)
                }
            }
            
            // Content
            Text(post.content)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Media
            if !post.mediaURLs.isEmpty {
                MediaGallery(mediaURLs: post.mediaURLs)
            }
            
            // Hashtags and mentions
            if !post.hashtags.isEmpty || !post.mentions.isEmpty {
                HStack {
                    if !post.hashtags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(post.hashtags, id: \.self) { hashtag in
                                    Text("#\(hashtag)")
                                        .font(.caption)
                                        .foregroundColor(.wweBlue)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.wweBlue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                }
            }
            
            // Engagement stats
            HStack {
                Text("\(post.engagement.views) views")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if post.engagement.comments > 0 {
                    Button(action: {
                        showingComments = true
                    }) {
                        Text("\(post.engagement.comments) comments")
                            .font(.caption)
                            .foregroundColor(.wweBlue)
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: 20) {
                Button(action: {
                    toggleLike()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .secondary)
                        
                        Text("\(post.engagement.likes)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: {
                    showingComments = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .foregroundColor(.secondary)
                        
                        Text("\(post.engagement.comments)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: {
                    toggleShare()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isShared ? "square.and.arrow.up.fill" : "square.and.arrow.up")
                            .foregroundColor(isShared ? .wweBlue : .secondary)
                        
                        Text("\(post.engagement.shares)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    toggleBookmark()
                }) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .foregroundColor(isBookmarked ? .wweBlue : .secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
        .onAppear {
            isLiked = post.engagement.isLiked
            isBookmarked = post.engagement.isBookmarked
            isShared = post.engagement.isShared
        }
        .sheet(isPresented: $showingComments) {
            CommentThreadView(postId: post.id ?? "")
        }
        .sheet(isPresented: $showingLikes) {
            LikesView(postId: post.id ?? "")
        }
    }
    
    private func toggleLike() {
        isLiked.toggle()
        socialService.likePost(post.id ?? "") { result in
            // Handle result
        }
    }
    
    private func toggleBookmark() {
        isBookmarked.toggle()
        socialService.bookmarkPost(post.id ?? "") { result in
            // Handle result
        }
    }
    
    private func toggleShare() {
        isShared.toggle()
        socialService.sharePost(post.id ?? "") { result in
            // Handle result
        }
    }
}

// MARK: - Post Type Badge
struct PostTypeBadge: View {
    let type: PostType
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type.iconName)
                .font(.caption2)
            
            Text(type.rawValue.capitalized)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(typeColor)
        .cornerRadius(4)
    }
    
    private var typeColor: Color {
        switch type {
        case .prediction: return .blue
        case .news: return .green
        case .achievement: return .yellow
        case .award: return .purple
        case .discussion: return .orange
        case .poll: return .red
        case .general: return .gray
        }
    }
}

// MARK: - Media Gallery
struct MediaGallery: View {
    let mediaURLs: [String]
    @State private var selectedIndex = 0
    
    var body: some View {
        VStack(spacing: 8) {
            // Main image
            AsyncImage(url: URL(string: mediaURLs[selectedIndex])) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                    )
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Thumbnail strip
            if mediaURLs.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(mediaURLs.enumerated()), id: \.offset) { index, url in
                            AsyncImage(url: URL(string: url)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(selectedIndex == index ? Color.wweBlue : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                selectedIndex = index
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Create Post View
struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var socialService = SocialService.shared
    
    @State private var content = ""
    @State private var selectedType: PostType = .general
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var imageData: [Data] = []
    @State private var hashtags: [String] = []
    @State private var mentions: [String] = []
    @State private var isCreating = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Content editor
                VStack(alignment: .leading, spacing: 16) {
                    // Post type selector
                    Picker("Post Type", selection: $selectedType) {
                        ForEach(PostType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    // Text editor
                    TextEditor(text: $content)
                        .font(.body)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    // Media picker
                    PhotosPicker(
                        selection: $selectedImages,
                        maxSelectionCount: 5,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: "camera")
                            Text("Add Photos")
                        }
                        .font(.headline)
                        .foregroundColor(.wweBlue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.wweBlue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Selected images
                    if !imageData.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(imageData.enumerated()), id: \.offset) { index, data in
                                    Image(uiImage: UIImage(data: data) ?? UIImage())
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            Button(action: {
                                                imageData.remove(at: index)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.white)
                                                    .background(Color.black.opacity(0.6))
                                                    .clipShape(Circle())
                                            }
                                            .padding(4),
                                            alignment: .topTrailing
                                        )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
                
                // Create button
                Button(action: createPost) {
                    HStack {
                        if isCreating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Create Post")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.wweBlue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!isFormValid || isCreating)
                .padding()
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedImages) { newImages in
                loadImages()
            }
            .alert("Post Creation", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func loadImages() {
        imageData.removeAll()
        
        for image in selectedImages {
            image.loadTransferable(type: Data.self) { result in
                switch result {
                case .success(let data):
                    if let data = data {
                        DispatchQueue.main.async {
                            imageData.append(data)
                        }
                    }
                case .failure(let error):
                    print("Error loading image: \(error)")
                }
            }
        }
    }
    
    private func createPost() {
        isCreating = true
        
        let post = SocialPost(
            authorId: "current_user", // TODO: Get from auth service
            authorUsername: "current_user",
            authorDisplayName: "Current User",
            content: content,
            postType: selectedType,
            mediaURLs: [] // TODO: Upload images and get URLs
        )
        
        socialService.createPost(post) { result in
            DispatchQueue.main.async {
                isCreating = false
                switch result {
                case .success:
                    alertMessage = "Post created successfully!"
                    showingAlert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                case .failure(let error):
                    alertMessage = "Failed to create post: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Search View
struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var socialService = SocialService.shared
    
    @State private var searchText = ""
    @State private var searchResults: [SocialPost] = []
    @State private var userResults: [SocialUser] = []
    @State private var selectedTab: SearchTab = .posts
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search posts, users, hashtags...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onSubmit {
                            performSearch()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                            userResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Search tabs
                Picker("Search Type", selection: $selectedTab) {
                    Text("Posts").tag(SearchTab.posts)
                    Text("Users").tag(SearchTab.users)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Results
                if isLoading {
                    LoadingView()
                } else if selectedTab == .posts && searchResults.isEmpty {
                    EmptySearchView(type: "posts")
                } else if selectedTab == .users && userResults.isEmpty {
                    EmptySearchView(type: "users")
                } else {
                    SearchResultsView(
                        posts: searchResults,
                        users: userResults,
                        selectedTab: selectedTab
                    )
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isLoading = true
        
        if selectedTab == .posts {
            socialService.searchPosts(searchText) { result in
                DispatchQueue.main.async {
                    isLoading = false
                    switch result {
                    case .success(let posts):
                        searchResults = posts
                    case .failure(let error):
                        print("Search error: \(error)")
                    }
                }
            }
        } else {
            socialService.searchUsers(searchText) { result in
                DispatchQueue.main.async {
                    isLoading = false
                    switch result {
                    case .success(let users):
                        userResults = users
                    case .failure(let error):
                        print("Search error: \(error)")
                    }
                }
            }
        }
    }
}

// MARK: - Search Tab
enum SearchTab: String, CaseIterable {
    case posts = "posts"
    case users = "users"
}

// MARK: - Search Results View
struct SearchResultsView: View {
    let posts: [SocialPost]
    let users: [SocialUser]
    let selectedTab: SearchTab
    
    var body: some View {
        if selectedTab == .posts {
            List(posts) { post in
                PostCard(post: post)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
            }
            .listStyle(PlainListStyle())
        } else {
            List(users) { user in
                UserCard(user: user)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
            }
            .listStyle(PlainListStyle())
        }
    }
}

// MARK: - User Card
struct UserCard: View {
    let user: SocialUser
    @StateObject private var socialService = SocialService.shared
    @State private var isFollowing = false
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: user.avatarURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(user.displayNameOrUsername)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.wweBlue)
                            .font(.caption)
                    }
                    
                    Spacer()
                }
                
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !user.bio.isEmpty {
                    Text(user.bio)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text("\(user.followerCount) followers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("\(user.followingCount) following")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                toggleFollow()
            }) {
                Text(isFollowing ? "Following" : "Follow")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isFollowing ? .primary : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isFollowing ? Color(.systemGray6) : Color.wweBlue)
                    .cornerRadius(16)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func toggleFollow() {
        isFollowing.toggle()
        
        if isFollowing {
            socialService.followUser(user.userId) { result in
                // Handle result
            }
        } else {
            socialService.unfollowUser(user.userId) { result in
                // Handle result
            }
        }
    }
}

// MARK: - Empty Search View
struct EmptySearchView: View {
    let type: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No \(type) found")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Try searching with different keywords")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FeedView()
}
