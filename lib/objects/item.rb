require_relative '../modules/record_like.rb'
require 'date'

class Item
  include RecordLike

  attr_accessor :name,
                :description,
                :unit_price,
                :merchant_id,
                :created_at,
                :updated_at
  attr_reader :id, :repository

  def initialize(record)
    @id          = record[:id]
    @name        = record[:name]
    @description = record[:description]
    @unit_price  = record[:unit_price]
    @merchant_id = record[:merchant_id]
    @created_at  = record[:created_at]
    @updated_at  = record[:updated_at]
    @repository  = record.fetch(:repository, nil)
  end

  def invoice_items
    repository.get(__callee__, id, :item_id)
  end

  def invoice_items_for(invoice_date)
    if invoice_date == "all"
      invoice_items
    else
      invoice_items.select do |ii|
        ii.invoice.created_at.to_date == DateTime.parse(invoice_date).to_date
      end
    end
  end

  def merchant
    repository.get(__callee__, merchant_id, :id).reduce
  end

  def invoices
    invoice_items.map{|ii| ii.invoice}
  end

  def paid_invoices
    invoices.select(&:paid?)
  end

  def unpaid_invoices
    invoices.reject(&:paid?)
  end

  def paid_invoices_for(date)
    if date == "all"
      paid_invoices
    else
      paid_invoices.select do |invoice|
        invoice.created_at.to_date == DateTime.parse(date).to_date
      end
    end
  end

  def paid_invoice_items_for(date = "all")
    invoice_items_for(date).select do |ii|
      ii.invoice.paid?
    end
  end

  def revenue(date = "all")
    cents = paid_invoice_items_for(date).reduce(0) do |acc, ii|
      acc + ii.total_price
    end
    to_dollars(cents)
  end

  def quantity_sold(date = "all")
    paid_invoice_items_for(date).reduce(0) do |acc, ii|
      ii.quantity
    end
  end

  def dates_sold
    paid_invoices.map{|invoice| invoice.created_at.to_date}.uniq
  end

  def best_day
    if dates_sold.empty?
      nil
    else
      dates_sold.max_by{|date| revenue(date.to_s) }
    end
  end

end