require 'bigdecimal'
require_relative '../loader.rb'
require_relative '../objects/invoice_item.rb'
require_relative '../modules/table_like'

class InvoiceItemRepository
  include TableLike

  attr_accessor :records, :database
  attr_reader :engine, :table

  def initialize(args)
    filename = args.fetch(:filename, 'invoice_items.csv')
    path = args.fetch(:path, './data/fixtures/') + filename
    loaded_csvs = Loader.new.load_csv(path)
    @database = args.fetch(:database, nil)

      create_invoice_item_table
      build_for_database(loaded_csvs)
      @records ||= table_records

    #@records = build_from(loaded_csvs)
    @table = "invoice_items"
    @engine = args.fetch(:engine, nil)
  end

  def create_invoice_item_table
    database.execute( "CREATE TABLE invoice_items(id INTEGER PRIMARY KEY,
                      item_id INTEGER, invoice_id INTEGER, quantity INTEGER,
                      unit_price INTEGER, created_at DATE, updated_at DATE)" );
  end

  def add_record_to_database(record)
    new_record = [record[:id],
                 record[:item_id],
                 record[:invoice_id],
                 record[:quantity],
                 record[:unit_price],
                 record[:created_at],
                 record[:updated_at]]
    prepped = database.prepare( "INSERT INTO invoice_items(id, item_id,
                                 invoice_id, quantity, unit_price, created_at,
                                 updated_at) VALUES (?,?,?,?,?,?,?)")
    prepped.execute(new_record)
  end

  def create_record(record)
    record[:repository] = self
    InvoiceItem.new(record)
  end

  def table_records
    database.execute( "SELECT * FROM invoice_items" ).map do |row|
      row[:repository] = self
      InvoiceItem.new(row)
    end
  end

  def paid_invoice_items
    args = {:repo => :invoice_repository, :use => :paid_invoices}
    @paid_invoices ||= engine.get(args)
    @paid_invoice_items ||= @paid_invoices.map do |invoice|
      invoice.invoice_items
    end.flatten
  end

  def add_items(items, invoice_id)
    items.each do |item|
      record = {
        :id => next_id,
        :invoice_id => invoice_id,
        :item_id => item.id,
        :unit_price => (item.unit_price.to_i)*100,
        :repository => item.repository,
        :created_at => timestamp,
        :updated_at => timestamp
      }
      add_record_to_database(record)
      end
  end

end
