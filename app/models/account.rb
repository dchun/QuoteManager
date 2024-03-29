class Account < ActiveRecord::Base
  belongs_to :plan
  has_many :forms, :dependent => :destroy
  has_many :requests, :dependent => :destroy
  has_many :quotes, :dependent => :destroy
  has_many :contacts, :dependent => :destroy
  has_many :users, :dependent => :destroy
  has_many :templates, :dependent => :destroy
  accepts_nested_attributes_for :users
  validates :company_name, :presence => true

  has_one :company_logo, as: :viewable, dependent: :destroy, :class => Image
  accepts_nested_attributes_for :company_logo

  has_one :address, as: :addressable
  accepts_nested_attributes_for :address

  validates :plan, presence: true, :on => :update

  liquid_methods :company_logo, :company_name

  attr_accessor :stripe_card_token

  def resource_used
    [ forms.pluck(:id).count, requests.pluck(:id).count, storage_usage.to_f/1000000 ]
  end

  def count_quote
    sum, quotes = 0, self.quotes.to_a
    quotes.each { |q| sum = sum + q[:email_opened] }
    { viewed: sum, draft: quotes.size }
  end

  def actived?
    self.users.all? { |u| u.active }
  end
end
