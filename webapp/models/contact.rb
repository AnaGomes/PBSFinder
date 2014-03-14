class Contact

  include Mongoid::Document

  field :name,              :type => String
  field :email,             :type => String
  field :message,           :type => String

  validates_presence_of     :name
  validates_presence_of     :email
  validates_presence_of     :message
  validates_format_of       :email,     :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
  validates_length_of       :name,      :within => 5..256
  validates_length_of       :email,     :within => 3..100
  validates_length_of       :message,   :within => 10..2048

end
