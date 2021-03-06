require_relative 'find'
require_relative 'find_by_x'

module TableLike
  include Find
  include FindByX

  def build_from(loaded_csvs)
    records = []
    loaded_csvs.each do |row|
      row[:repository] = self
      records << create_record(row)
    end
    records
  end

  def build_for_database(loaded_csvs)
    loaded_csvs.each do |row|
      row[:repository] = self
      add_record_to_database(row) if database
    end
  end

  def get(what, source_key_value, remote_key_name)
    foreign_repo = repo_map[what.to_sym]
    engine.send(foreign_repo).find_all_by(remote_key_name, source_key_value)
  end

  def foreign_key_for(repo, class_name)
    engine.send(repo).holds_type.foreign_keys[class_name]
  end

  def repo_map
    {
      :item => :item_repository,
      :items => :item_repository,
      :invoice => :invoice_repository,
      :invoices => :invoice_repository,
      :transactions => :transaction_repository,
      :invoice_items => :invoice_item_repository,
      :customer => :customer_repository,
      :merchant => :merchant_repository,
      :paid_invoices => :invoice_repository, #not yet used
      :paid_invoice_items => :invoice_item_repository
    }
  end

  def to_dollars(cents)
    cents.round(2)
  end

  def inspect
    "#<#{self.class} #{@records.size} rows>"
  end

  def timestamp
    Time.now.utc.to_s
  end

  def next_id
    all.last.id + 1
  end
end
