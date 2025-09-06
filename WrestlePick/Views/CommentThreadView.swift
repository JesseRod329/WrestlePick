import SwiftUI

struct CommentThreadView: View {
    let postId: String
    @StateObject private var socialService = SocialService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var comments: [Comment] = []
    @State private var newComment = ""
    @State private var replyingTo: Comment?
    @State private var replyText = ""
    @State private var isLoading = false
    @State private var isSubmitting = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Comments list
                if isLoading {
                    LoadingView()
                } else if comments.isEmpty {
                    EmptyCommentsView()
                } else {
                    CommentsList(
                        comments: comments,
                        onReply: { comment in
                            replyingTo = comment
                        },
                        onLike: { comment in
                            likeComment(comment)
                        }
                    )
                }
                
                // Reply section
                if let replyingTo = replyingTo {
                    ReplySection(
                        replyingTo: replyingTo,
                        replyText: $replyText,
                        onCancel: {
                            self.replyingTo = nil
                            replyText = ""
                        },
                        onSubmit: {
                            submitReply(to: replyingTo)
                        },
                        isSubmitting: isSubmitting
                    )
                }
                
                // New comment section
                NewCommentSection(
                    newComment: $newComment,
                    onSubmit: {
                        submitComment()
                    },
                    isSubmitting: isSubmitting
                )
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadComments()
            }
            .alert("Comment", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func loadComments() {
        isLoading = true
        
        socialService.loadComments(for: postId) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let loadedComments):
                    comments = loadedComments
                case .failure(let error):
                    alertMessage = "Failed to load comments: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func submitComment() {
        guard !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSubmitting = true
        
        let comment = Comment(
            postId: postId,
            authorId: "current_user", // TODO: Get from auth service
            authorUsername: "current_user",
            authorDisplayName: "Current User",
            content: newComment
        )
        
        socialService.createComment(comment) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                switch result {
                case .success:
                    newComment = ""
                    loadComments()
                case .failure(let error):
                    alertMessage = "Failed to submit comment: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func submitReply(to parentComment: Comment) {
        guard !replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSubmitting = true
        
        let reply = Comment(
            postId: postId,
            authorId: "current_user", // TODO: Get from auth service
            authorUsername: "current_user",
            authorDisplayName: "Current User",
            content: replyText
        )
        
        socialService.replyToComment(parentComment.id ?? "", reply: reply) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                switch result {
                case .success:
                    replyText = ""
                    replyingTo = nil
                    loadComments()
                case .failure(let error):
                    alertMessage = "Failed to submit reply: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func likeComment(_ comment: Comment) {
        socialService.likeComment(comment.id ?? "") { result in
            // Handle result
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading comments...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty Comments View
struct EmptyCommentsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Comments Yet")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Be the first to comment on this post!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Comments List
struct CommentsList: View {
    let comments: [Comment]
    let onReply: (Comment) -> Void
    let onLike: (Comment) -> Void
    
    var body: some View {
        List {
            ForEach(comments) { comment in
                CommentRow(
                    comment: comment,
                    onReply: {
                        onReply(comment)
                    },
                    onLike: {
                        onLike(comment)
                    }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Comment Row
struct CommentRow: View {
    let comment: Comment
    let onReply: () -> Void
    let onLike: () -> Void
    
    @State private var isLiked = false
    @State private var showingReplies = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Comment header
            HStack {
                AsyncImage(url: URL(string: comment.authorAvatarURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(comment.authorDisplayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        if comment.authorUsername != comment.authorDisplayName {
                            Text("@\(comment.authorUsername)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(comment.timeAgo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Comment content
            Text(comment.content)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Comment actions
            HStack(spacing: 16) {
                Button(action: {
                    toggleLike()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .secondary)
                        
                        Text("\(comment.engagement.likes)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: onReply) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .foregroundColor(.secondary)
                        
                        Text("Reply")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Replies section
            if !comment.replies.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: {
                        showingReplies.toggle()
                    }) {
                        HStack {
                            Text("\(comment.replies.count) replies")
                                .font(.caption)
                                .foregroundColor(.wweBlue)
                            
                            Image(systemName: showingReplies ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(.wweBlue)
                        }
                    }
                    
                    if showingReplies {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(comment.replies) { reply in
                                ReplyRow(
                                    reply: reply,
                                    onLike: {
                                        // Handle reply like
                                    }
                                )
                            }
                        }
                        .padding(.leading, 16)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            isLiked = comment.engagement.isLiked
        }
    }
    
    private func toggleLike() {
        isLiked.toggle()
        onLike()
    }
}

// MARK: - Reply Row
struct ReplyRow: View {
    let reply: Comment
    let onLike: () -> Void
    
    @State private var isLiked = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            AsyncImage(url: URL(string: reply.authorAvatarURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 24, height: 24)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(reply.authorDisplayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if reply.authorUsername != reply.authorDisplayName {
                        Text("@\(reply.authorUsername)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(reply.timeAgo)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(reply.content)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 12) {
                    Button(action: {
                        toggleLike()
                    }) {
                        HStack(spacing: 2) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundColor(isLiked ? .red : .secondary)
                            
                            Text("\(reply.engagement.likes)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            isLiked = reply.engagement.isLiked
        }
    }
    
    private func toggleLike() {
        isLiked.toggle()
        onLike()
    }
}

// MARK: - Reply Section
struct ReplySection: View {
    let replyingTo: Comment
    @Binding var replyText: String
    let onCancel: () -> Void
    let onSubmit: () -> Void
    let isSubmitting: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Replying to \(replyingTo.authorDisplayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            TextField("Write a reply...", text: $replyText, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
            
            HStack {
                Spacer()
                
                Button(action: onSubmit) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Reply")
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(replyText.isEmpty ? Color.gray : Color.wweBlue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                .disabled(replyText.isEmpty || isSubmitting)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: -1)
    }
}

// MARK: - New Comment Section
struct NewCommentSection: View {
    @Binding var newComment: String
    let onSubmit: () -> Void
    let isSubmitting: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            TextField("Write a comment...", text: $newComment, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
            
            HStack {
                Spacer()
                
                Button(action: onSubmit) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Comment")
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(newComment.isEmpty ? Color.gray : Color.wweBlue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                .disabled(newComment.isEmpty || isSubmitting)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: -1)
    }
}

// MARK: - Custom Text Field Style
struct RoundedBorderTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}

#Preview {
    CommentThreadView(postId: "sample_post_id")
}
