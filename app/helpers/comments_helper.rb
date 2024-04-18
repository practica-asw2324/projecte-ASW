module CommentsHelper

  def user_post_or_comment_class(comment, user_view)
    'user-post-or-comment' if defined?(user_view) && user_view && comment.user == current_user
  end
  def comment_margin_style(comment, escalate)
    'margin-left: ' + (20 * comment.depth).to_s + 'px;' if defined?(escalate) && escalate
  end

end
