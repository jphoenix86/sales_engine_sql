require_relative '../loader'
require_relative '../objects/merchant'
require_relative '../modules/table_like'

class MerchantRepository
  include TableLike

  attr_accessor :records, :all_paid_invoices, :all_unpaid_invoices,
    :cached_dates_by_revenue, :cached_invoices, :cached_items,
    :cached_dates_with_sales, :database
  attr_reader :engine, :table

  def initialize(args)
    filename = args.fetch(:filename, 'merchants.csv')
    path = args.fetch(:path, './data/fixtures/') + filename
    loaded_csvs = Loader.new.load_csv(path)
    @database = args.fetch(:database, nil)

      create_merchant_table
      build_for_database(loaded_csvs)
      @records ||= table_records

    #@records = build_from(loaded_csvs)
    @table = "merchants"
    @engine = args.fetch(:engine, nil)
  end

  def create_merchant_table
    database.execute( "CREATE TABLE merchants(id INTEGER PRIMARY KEY, name
                       VARCHAR(31), created_at DATE, updated_at DATE)" );
  end

  def add_record_to_database(record)
    new_record = [record[:id],
                 record[:name],
                 record[:created_at],
                 record[:updated_at]]
    prepped = database.prepare( "INSERT INTO merchants(id, name, created_at,
                                 updated_at) VALUES (?,?,?,?)" )
    prepped.execute(new_record)
  end

  def create_record(record)
    record[:repository] = self
    Merchant.new(record)
  end

  def table_records
    database.execute( "SELECT * FROM merchants" ).map do |row|
      row[:repository] = self
      Merchant.new(row)
    end
  end

  def most_revenue(x)
    all.max_by(x) {|merchant| merchant.revenue}
  end

  def most_items(x)
    items ||= engine.item_repository.all
    grouped ||= items.group_by {|item| item.merchant_id}
    ranked = grouped.max_by(x) do |merchant, items|
      items.reduce(0) do |acc, item|
        acc + item.quantity_sold
      end
    end
    ranked.flat_map{|x| self.find_by_id(x.first) }
  end

  def revenue_date(date)
    all.inject(0) do |acc, merchant|
      acc + merchant.revenue(date)
    end
  end

  def revenue(dates)
    dates = dates..dates if !(dates.is_a?(Range))
    dates.map{|date| revenue_date(date)}.reduce(:+)
  end

  def dates_by_revenue(x = "all")
    if x == "all"
      all_dates_ranked
    else
      all_dates_ranked.take(x)
    end
  end

  def all_dates_ranked
    dates_with_sales.each_with_object({}) do |date, hash|
      hash[date] = revenue(date)
    end.sort_by {|_, revenue| revenue}.to_h.keys.reverse
  end

  def dates_with_sales
    cached_dates_with_sales ||= begin
      args = {:repo => :invoice_repository, :use => :paid_invoice_dates}
      dates = engine.get(args)
    end
  end

  def paid_invoices(for_merchant)
    args = {
      :repo => :invoice_repository,
      :use => :paid_invoices
    }
    @all_paid_invoices ||= engine.get(args)
    all_paid_invoices.select do |invoice|
      invoice.merchant_id == for_merchant.id
    end
  end

  def unpaid_invoices(for_merchant)
    args = {
      :repo => :invoice_repository,
      :use => :unpaid_invoices
    }
    @all_unpaid_invoices ||= engine.get(args)
    all_unpaid_invoices.select do |invoice|
      invoice.merchant_id == for_merchant.id
    end
  end

  def invoices
    cached_invoices ||= begin
      args = {
        :repo => :invoice_repository,
        :use => :all
      }
      engine.get(args)
    end
  end

  def items
    cached_items ||= begin
      args = {
        :repo => :item_repository,
        :use => :all
      }
      engine.get(args)
    end
  end

  def items_for(merchant)
    items.select do |item|
      item.merchant_id == merchant.id
    end
  end

  def invoices_for(merchant)
    invoices.select do |invoice|
      invoice.merchant_id == merchant.id
    end
  end
end
