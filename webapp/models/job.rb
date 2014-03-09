class Job
  include Mongoid::Document
  include Mongoid::Timestamps
  attr_accessor :query
  belongs_to :account, :dependent => :nullify
  embeds_many :genes, :cascade_callbacks => true

  # field <name>, :type => <type>, :default => <value>
  field :completed,     :type => Boolean, :default => false
  field :description,   :type => String
  field :species,       :type => String
  field :email,         :type => Boolean, :default => false

  validates_presence_of :query, :if => :query_required
  validates_presence_of :completed
  validates_presence_of :email
  validates_presence_of :description
  validates_length_of   :description, :within => 5..256

  def self.find_by_id(id)
    find(id) rescue nil
  end

  private

  def query_required
    return !self.completed
  end

  # You can define indexes on documents using the index macro:
  # index :field <, :unique => true>

  # You can create a composite key in mongoid to replace the default id using the key macro:
  # key :field <, :another_field, :one_more ....>
end
