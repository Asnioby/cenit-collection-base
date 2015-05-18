module Cenit
  module Collection
    module Base

      require 'json'
      require 'active_support/core_ext/hash/deep_merge'
      require 'fileutils'
      require 'active_support'

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

        def import_data(data)
          shared_data = JSON.parse(data)
          hash_data = shared_data['data']
          hash_model = []
          models = ["flows","connection_roles","translators","events","connections","webhooks"]
          models.collect do |model|
            if hash_model = hash_data[model].to_a
              hash_model.collect do |hash|
                if file_name = format_filename(hash['name'])
                  File.open(@base_path + '/' + model + '/' + file_name + '.json', mode: "w:utf-8") do |f|
                    f.write(JSON.pretty_generate(hash))
                  end
                end
              end
            end
          end
          libraries = hash_data['libraries']
          library_index = []
          libraries.collect do |library|
            if library_name = library['name']
              library_file = format_filename (library_name)
              FileUtils.mkpath(@base_path +'/libraries/' + library_file) unless File.directory?(@base_path +'/libraries/' + library_file)
              library['schemas'].collect do |schema|
                if schema_file = schema['uri']
                  File.open(@base_path +'/libraries/' + library_file + '/' + schema_file, mode: "w:utf-8") do |f|
                    f.write(JSON.pretty_generate(JSON.parse(schema['schema'])))
                  end
                end
              end
              library_index << {'name' => library_name, 'file' => library_file}
            end
          end
          File.open(@base_path +'/libraries/index.json', mode: "w:utf-8") do |f|
            f.write(JSON.pretty_generate(library_index))
          end
          File.open(@base_path +'/index.json', mode: "w:utf-8") do |f|
            f.write(JSON.pretty_generate(shared_data.except('data')))
          end

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

        def format_filename(name)
          name.gsub(/[^\w\s_-]+/, '')
          .gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2')
          .gsub(/\s+/, '_')
          .downcase
        end

        def sanitize_filename(filename)
          fn = filename.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m
          fn.map! { |s| s.gsub /[^a-z0-9\-]+/i, '_' }
          fn.join '.'
          fn.to_s.downcase
        end

      end
    end
  end
end