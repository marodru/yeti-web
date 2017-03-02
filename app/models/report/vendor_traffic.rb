# == Schema Information
#
# Table name: reports.vendor_traffic_report
#
#  id         :integer          not null, primary key
#  created_at :datetime
#  date_start :datetime
#  date_end   :datetime
#  vendor_id  :integer          not null
#

class Report::VendorTraffic < Cdr::Base
  self.table_name = 'reports.vendor_traffic_report'

  has_many :vendor_traffic_data, class_name: 'Report::VendorTrafficData', foreign_key: :report_id, dependent: :delete_all

  belongs_to :vendor, -> { where vendor: true }, class_name: 'Contractor', foreign_key: :vendor_id

  def report_records
    vendor_traffic_data.includes(:customer)
  end

  validates_presence_of :date_start, :date_end, :vendor_id

  def display_name
    "#{self.id}"
  end

  after_create do
    #execute_sp("SELECT * FROM reports.vendor_traffic_report(?)", self.id)
    execute_sp("INSERT INTO reports.vendor_traffic_report_data(
                  report_id, customer_id,
                  calls_count,
                  short_calls_count,
                  success_calls_count,
                  calls_duration,acd,asr,
                  origination_cost, termination_cost, profit,
                  first_call_at,last_call_at
               )
               SELECT
                  ?, customer_id,
                  count(id),
                  count(nullif(duration>?,false)),
                  count(nullif(success,false)),
                  sum(duration),
                  sum(duration)::float/nullif(count(nullif(success,false)),0)::float,
                  count(nullif(success,false))::float/nullif(count(id),0)::float,
                  sum(customer_price),sum(vendor_price),sum(profit),
                  min(time_start), max(time_start)
               from cdr.cdr
               WHERE
                  time_start>=?
                  AND time_start<?
                  AND vendor_id=?
            GROUP BY customer_id",
               self.id,
               GuiConfig.short_call_length,
               self.date_start,
               self.date_end,
               self.vendor_id
    )
  end

  include Hints
  include CsvReport
  after_create do
    Reporter::VendorTraffic.new(self).save!
  end

  def csv_columns
    [:customer,
     :calls_count,
     :calls_duration,
     :acd,
     :asr,
     :origination_cost,
     :termination_cost,
     :profit,
     :success_calls_count,
     :first_call_at,
     :last_call_at,
     :short_calls_count]
  end


end

