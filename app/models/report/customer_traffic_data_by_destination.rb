# == Schema Information
#
# Table name: reports.customer_traffic_report_data_by_destination
#
#  id                  :integer          not null, primary key
#  report_id           :integer          not null
#  destination_prefix  :string
#  dst_country_id      :integer
#  dst_network_id      :integer
#  calls_count         :integer          not null
#  calls_duration      :integer          not null
#  acd                 :float
#  asr                 :float
#  origination_cost    :decimal(, )
#  termination_cost    :decimal(, )
#  profit              :decimal(, )
#  success_calls_count :integer
#  first_call_at       :datetime
#  last_call_at        :datetime
#  short_calls_count   :integer          not null
#

class Report::CustomerTrafficDataByDestination < Cdr::Base
  self.table_name = 'reports.customer_traffic_report_data_by_destination'

  belongs_to :report, class_name: 'Report::CustomerTraffic', foreign_key: :report_id
  belongs_to :country, class_name: System::Country, foreign_key: :dst_country_id
  belongs_to :network, class_name: System::Network, foreign_key: :dst_network_id


  def display_name
    "#{self.id}"
  end

  def self.totals
    select("sum(calls_count)::int as calls_count,
            sum(success_calls_count)::int as success_calls_count,
            sum(short_calls_count)::int as short_calls_count,
            sum(calls_duration) as calls_duration,
            sum(origination_cost) as origination_cost,
            sum(termination_cost) as termination_cost,
            sum(profit) as profit,
            min(first_call_at) as first_call_at,
            max(last_call_at) as last_call_at,
            coalesce(sum(calls_duration)::float/nullif(sum(success_calls_count),0),0) as agg_acd"
    ).take
  end

  def self.report_records
    includes(:country, :network)
  end

  def self.csv_columns
    [
        :destination_prefix,
        :country,
        :network,
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
        :short_calls_count
    ]
  end

end
