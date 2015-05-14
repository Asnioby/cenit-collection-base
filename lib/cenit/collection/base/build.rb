module Cenit
  module Collection
    module Base

      require 'json'
      require 'active_support/core_ext/hash/deep_merge'

      class Build

        attr_accessor :base_path
        attr_accessor :collection_dep

        def initialize (base_path)
          @base_path = base_path
          @collection_dep = []
        end

        def register_dep (dep)
          @collection_dep << dep
        end

        def build_data
          shared = {}
          hash = {}
          models = ['flows','connection_roles','translators','events','connections','webhooks']
          models.collect do |model|
            temp = []
            hash.merge!({model => []})
            @collection_dep.collect do |collection|
              temp = collection.process_model(model)
              hash.deep_merge!({model => temp}){ |_, val1, val2| array_sum(val1, val2) }
            end
             temp = process_model(model)
             hash.deep_merge!({model => temp}){ |_, val1, val2| array_sum(val1, val2) }
          end
          shared.merge!(hash)
          temp = []
          hash = {'libraries' => []}
          @collection_dep.collect do |collection|
            temp = collection.process_libraries
            hash.deep_merge!({'libraries' => temp}){ |_, val1, val2| array_sum(val1, val2) }
          end
            temp = process_libraries
            hash.deep_merge!({'libraries' => temp}){ |_, val1, val2| array_sum(val1, val2) }
          shared.merge!(hash)
          {"data" => shared}
        end

        def shared_collection
          shared = collection_base
          shared.deep_merge!(build_data)
          {"shared_collection" => shared}
        end

    protected

        def process_model(model)
          result = []
          files = load_json_dir(model).to_a
          files.collect do |file|
            result << JSON.parse(open_json(file))
          end
          result
        end

        def process_libraries
          results = []
          lib_index = @base_path + '/libraries/index.json'
          libraries = JSON.parse(open_json(lib_index)).to_a
          libraries.collect do |lib|
            schemas = []
            files = load_library_dir(lib["file"]).to_a
            files.collect do |file|
              hash = {"uri" => File.basename(file),
                      "schema" => open_json(file).to_s,
                      "library" => {
                          "_reference" => true,
                          "name" => lib["name"]
                      }
              }
              schemas << hash
            end
            results << {"name" => lib["name"], "schemas" => schemas}
          end
          results
        end

        def collection_base
          JSON.parse(open_head)
        end

        def sample_model(model)
          JSON.parse(open_sample(model))
        end

        def open_json(file)
          File.open(file, mode: "r:utf-8").read
        rescue {}
        end

        def open_head
          File.open(@base_path + '/index.json', mode: "r:utf-8").read
        rescue {}
        end

        def open_sample(model)
          File.open(@base_path + "/support/sample/#{model}.json", mode: "r:utf-8").read
        rescue {}
        end

        def load_json_dir(model)
          Dir.glob("#{@base_path}/#{model}/*.json")
        rescue []
        end

        def load_library_dir(lib)
          Dir.glob("#{@base_path}/libraries/#{lib}/*.json")
        rescue []
        end

        def array_sum(val1, val2)
          val1.is_a?(Array) && val2.is_a?(Array) ? (val1 + val2).uniq : val2
        end

      end
    end
  end
end