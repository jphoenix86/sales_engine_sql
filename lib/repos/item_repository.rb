require 'bigdecimal'
require_relative '../loader.rb'
require_relative '../objects/item'
require_relative '../modules/util'
require_relative '../modules/table_like'


class ItemRepository
  include Util
  include TableLike

  attr_accessor :items
  attr_reader :engine, :records

  def initialize(args)
    @engine = args.fetch(:engine, nil)
    filename = args.fetch(:filename, 'items.csv')
    path = args.fetch(:path, './data/fixtures/') + filename
    @loader = Loader.new
    loaded_csvs = @loader.load_csv(path)
    # @items = populate_items(loaded_csvs)
    # @records = @items
    @records = build_from(loaded_csvs)
  end

  def create_record(record)
    record[:unit_price] = BigDecimal.new(record[:unit_price]) / 100
    Item.new(record)
  end

  # def build_from(loaded_csvs)
  #   records = {}
  #   loaded_csvs.each do |item|
  #     id = item.first
  #     record = item.last
  #     record[:unit_price] = (BigDecimal.new(record[:unit_price]) / 100)
  #     record[:repository] = self
  #     records[id] = create_record(record)
  #   end
  #   records
  # end


  # def populate_items(loaded_csvs)
  #   items = {}
  #   loaded_csvs.each do |item|
  #     id = item.first
  #     record = item.last
  #     record[:unit_price] = (BigDecimal.new(record[:unit_price]) / 100)
  #     record[:repository] = self
  #     items[id] = create_record(record)
  #   end
  #   items
  # end

  def paid_invoice_items(for_object)
      match = for_object.id
      key = for_object.class.to_s.downcase + "_id"
      args = {}
      
      args[:use] = __callee__
      args[:repo] = :invoice_item_repository
      engine.get(args).select{|ii| ii.send(key.to_sym) == match}
  end

  def most_revenue(x)
    all.max_by(x) {|item| item.revenue}
  end

  def most_items(x)
    all.max_by(x) {|item| item.quantity_sold}
  end

  def inspect
    "#<#{self.class} #{@items.size} rows>"
  end

end