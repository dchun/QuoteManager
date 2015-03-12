class Quote < ActiveRecord::Base
  belongs_to :account
  belongs_to :template
  belongs_to :request, :autosave => true
  before_create :generate_token
  liquid_methods :amount, :options, :id, :token, :expires_at, :description

  has_many :visitors, as: :eventable, dependent: :destroy, :class_name => Visit

protected

  def generate_token
    self.token = SecureRandom.urlsafe_base64(nil, false)
  end
end
