require 'json'
require 'active_support/core_ext/hash/deep_merge'
require 'fileutils'
require 'active_support'

module Cenit
  module Collection
    class Base

      VERSION = '0.1.0'

      class << self

        attr_accessor :base_path

        def dependencies
          @dependencies ||= []
        end

        def build_data
          shared = CenitCmd::Collection.collect_data(base_path)
          dependencies.each do |collection|
            shared.deep_merge!(collection.build_data) { |_, val1, val2| array_sum(val1, val2) }
          end
          {'data' => shared}
        end

        def shared_collection
          shared = collection_base
          shared.deep_merge!(build_data)
          {'shared_collection' => shared}
        end

        def sample_model(model)
          open_sample(model)
          #JSON.parse(open_sample(model))
        end

        def push_collection (config)
          Cenit::Client.push(shared_collection.to_json, config)
        end

        def show_collection
          shared_collection
        end

        def pull_collection (parameters,config)
          shared_collection
        end

        def push_sample(model, config)
          Cenit::Client.push(sample_model(model).to_json, config)
        end

        protected

        def open_sample(model)
          sample_dir = File.expand_path(File.join(*%w[ .. .. .. .. spec support sample ]), @base_path)
          File.open(sample_dir + "/#{model}.json", mode: "r:utf-8").read
        rescue {}
        end

        def array_sum(val1, val2)
          val1.is_a?(Array) && val2.is_a?(Array) ? (val1 + val2).uniq : val2
        end
      end

      self.base_path = __dir__
    end
  end
end