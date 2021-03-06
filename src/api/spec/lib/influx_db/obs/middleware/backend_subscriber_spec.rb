require 'rails_helper'
require Rails.root.join('lib', 'influxdb_obs', 'obs', 'middleware', 'backend_subscriber').to_s

RSpec.describe InfluxDB::OBS::Middleware::BackendSubscriber do
  let(:series_name) { 'rails' }

  subject { described_class.new(series_name) }

  describe '#call' do
    let(:start_time)   { Time.at(1_517_567_368) }
    let(:finish_time)  { Time.at(1_517_567_370) }
    let(:data) do
      {
        hook: 'obs_backend',
        http_status_code: 200,
        http_method: 'GET',
        host: 'backend',
        controller_location: 'UsersController#index',
        backend_location: 'Cloud#upload',
        runtime: 2
      }
    end

    let(:result) do
      {
        # :request might be nil. In that case we have to filter it out.
        values: InfluxDB::Rails.current.values.reject { |_, v| v.nil? }.update(value: 2000),
        tags: {
          http_status_code: 200,
          http_method: 'GET',
          hook: 'obs_backend',
          host: 'backend',
          controller_location: 'UsersController#index',
          backend_location: 'Cloud#upload',
          additional_tag: true
        },
        timestamp: 1_517_567_370
      }
    end

    before do
      stub_const('CONFIG', CONFIG.merge('influxdb_hosts' => ['localhost']))
      InfluxDB::Rails.current.tags = {
        additional_tag: true
      }
      allow_any_instance_of(InfluxDB::Rails::Configuration).to receive(:time_precision).and_return('ms')
    end

    it 'writes to InfluxDB' do
      expect_any_instance_of(InfluxDB::Client).to receive(:write_point).with(series_name, result)
      subject.call('_name', start_time, finish_time, '_unique_id', data)
    end
  end
end
