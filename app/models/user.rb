class User < ApplicationRecord
  has_many :authentications
  has_many :papers
  has_many :upvotes
  has_many :upvoted_papers, through: :upvotes, source: :paper

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  validates :name, presence: true
  validates :email, presence: true

  scope :staff, -> { where(staff: true) }
  scope :contributor, -> { where(staff: nil) }

  def apply_omniauth(omniauth)
    provider, uid, info = omniauth.values_at('provider', 'uid', 'info')
    self.email = info['email'] if email.blank?
    self.name  = info['name']  if name.blank?

    apply_provider_handle(omniauth)
    authentications.build(provider: provider, uid: uid)
  end

  def apply_provider_handle(omniauth)
    provider, info = omniauth.values_at('provider', 'info')

    case provider
    when /github/
      self.github_handle  = info['nickname'] if github_handle.blank?
    when /twitter/
      self.twitter_handle = info['nickname'] if twitter_handle.blank?
    end
  end

  def password_required?
    (authentications.empty? || password.present?) && super
  end

  def connected_with_twitter?
    authentications.where(provider: 'twitter').first
  end

  def connected_with_github?
    authentications.where(provider: 'github').first
  end

  def has_bio?
    ! bio.blank?
  end

  def has_proposal?
    ! papers.empty?
  end

  def give_upvote!(paper)
    return if paper.upvoted_by? self
    upvoted_papers << paper
  end

  def take_upvote!(paper)
    upvoted_papers.delete(paper)
  end
end
