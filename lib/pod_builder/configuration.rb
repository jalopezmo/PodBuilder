require 'json'
require 'tmpdir'

module PodBuilder  
  class Configuration  
    # Remember to update README.md accordingly
    DEFAULT_BUILD_SETTINGS = {
      "ENABLE_BITCODE" => "NO",
      "GCC_OPTIMIZATION_LEVEL" => "s",
      "SWIFT_OPTIMIZATION_LEVEL" => "-Osize",
      "SWIFT_COMPILATION_MODE" => "wholemodule",
      "CODE_SIGN_IDENTITY" => "",
      "CODE_SIGNING_REQUIRED" => "NO",
      "CODE_SIGN_ENTITLEMENTS" => "",
      "CODE_SIGNING_ALLOWED" => "NO"
    }.freeze
    DEFAULT_SPEC_OVERRIDE = {
      "Google-Mobile-Ads-SDK" => {
        "module_name": "GoogleMobileAds"
      }
    }.freeze
    DEFAULT_SKIP_PODS = ["GoogleMaps"]
    DEFAULT_FORCE_PREBUILD_PODS = ["Firebase", "GoogleTagManager"]
    DEFAULT_BUILD_SYSTEM = "Legacy".freeze # either Latest (New build system) or Legacy (Standard build system)
    DEFAULT_LIBRARY_EVOLUTION_SUPPORT = false
    MIN_LFS_SIZE_KB = 256.freeze
    DEFAULT_PLATFORMS = ["iphoneos", "iphonesimulator", "appletvos", "appletvsimulator"].freeze
    DEFAULT_BUILD_FOR_APPLE_SILICON = false
    DEFAULT_BUILD_USING_REPO_PATHS = false
    
    private_constant :DEFAULT_BUILD_SETTINGS
    private_constant :DEFAULT_BUILD_SYSTEM
    private_constant :DEFAULT_LIBRARY_EVOLUTION_SUPPORT
    private_constant :MIN_LFS_SIZE_KB
    
    class <<self      
      attr_accessor :allow_building_development_pods
      attr_accessor :build_settings
      attr_accessor :build_settings_overrides
      attr_accessor :build_system
      attr_accessor :library_evolution_support
      attr_accessor :base_path
      attr_accessor :spec_overrides      
      attr_accessor :skip_licenses
      attr_accessor :skip_pods
      attr_accessor :force_prebuild_pods
      attr_accessor :license_filename
      attr_accessor :subspecs_to_split
      attr_accessor :development_pods_paths
      attr_accessor :build_base_path
      attr_accessor :build_path
      attr_accessor :configuration_filename
      attr_accessor :dev_pods_configuration_filename
      attr_accessor :lfs_min_file_size
      attr_accessor :lfs_update_gitattributes
      attr_accessor :lfs_include_pods_folder
      attr_accessor :project_name
      attr_accessor :restore_enabled
      attr_accessor :framework_plist_filename
      attr_accessor :lockfile_name
      attr_accessor :lockfile_path
      attr_accessor :use_bundler
      attr_accessor :deterministic_build
      attr_accessor :supported_platforms
      attr_accessor :build_for_apple_silicon
      attr_accessor :build_using_repo_paths
    end
    
    @allow_building_development_pods = false
    @build_settings = DEFAULT_BUILD_SETTINGS
    @build_settings_overrides = {}
    @build_system = DEFAULT_BUILD_SYSTEM
    @library_evolution_support = DEFAULT_LIBRARY_EVOLUTION_SUPPORT
    @base_path = "Frameworks" # Not nice. This value is used only for initial initization. Once config is loaded it will be an absolute path. FIXME
    @spec_overrides = DEFAULT_SPEC_OVERRIDE
    @skip_licenses = []
    @skip_pods = DEFAULT_SKIP_PODS
    @force_prebuild_pods = DEFAULT_FORCE_PREBUILD_PODS
    @license_filename = "Pods-acknowledgements"
    @subspecs_to_split = []
    @development_pods_paths = []
    @build_base_path = "/tmp/pod_builder".freeze
    @build_path = build_base_path
    @configuration_filename = "PodBuilder.json".freeze
    @dev_pods_configuration_filename = "PodBuilderDevPodsPaths.json".freeze
    @lfs_min_file_size = MIN_LFS_SIZE_KB
    @lfs_update_gitattributes = false
    @lfs_include_pods_folder = false
    @project_name = ""
    @restore_enabled = true
    @framework_plist_filename = "PodBuilder.plist"
    @lockfile_name = "PodBuilder.lock"
    @lockfile_path = "/tmp/#{lockfile_name}"

    @use_bundler = false
    @deterministic_build = false

    @supported_platforms = DEFAULT_PLATFORMS
    @build_for_apple_silicon = DEFAULT_BUILD_FOR_APPLE_SILICON
    @build_using_repo_paths = DEFAULT_BUILD_USING_REPO_PATHS
    
    def self.check_inited
      raise "\n\nNot inited, run `pod_builder init`\n".red if podbuilder_path.nil?
    end
    
    def self.exists
      return !config_path.nil? && File.exist?(config_path)
    end
    
    def self.load
      unless podbuilder_path
        return
      end
      
      Configuration.base_path = podbuilder_path
      
      if exists
        begin
          json = JSON.parse(File.read(config_path))
        rescue => exception
          raise "\n\n#{File.basename(config_path)} is an invalid JSON\n".red
        end

        if value = json["spec_overrides"]
          if value.is_a?(Hash) && value.keys.count > 0
            Configuration.spec_overrides = value
          end
        end
        if value = json["skip_licenses"]
          if value.is_a?(Array)
            Configuration.skip_licenses = value
          end
        end
        if value = json["skip_pods"]
          if value.is_a?(Array)
            Configuration.skip_pods = value
          end
        end
        if value = json["force_prebuild_pods"]
          if value.is_a?(Array)
            Configuration.force_prebuild_pods = value
          end
        end
        if value = json["build_settings"]
          if value.is_a?(Hash) && value.keys.count > 0
            Configuration.build_settings = value
          end
        end
        if value = json["build_settings_overrides"]
          if value.is_a?(Hash) && value.keys.count > 0
            Configuration.build_settings_overrides = value
          end
        end
        if value = json["build_system"]
          if value.is_a?(String) && ["Latest", "Legacy"].include?(value)
            Configuration.build_system = value
          end
        end
        if value = json["library_evolution_support"]
          if [TrueClass, FalseClass].include?(value.class)
            Configuration.library_evolution_support = value
          end
        end
        if value = json["license_filename"]
          if value.is_a?(String) && value.length > 0
            Configuration.license_filename = value
          end
        end
        if value = json["subspecs_to_split"]
          if value.is_a?(Array) && value.count > 0
            Configuration.subspecs_to_split = value
          end
        end
        if value = json["lfs_update_gitattributes"]
          if [TrueClass, FalseClass].include?(value.class)
            Configuration.lfs_update_gitattributes = value
          end
        end
        if value = json["lfs_include_pods_folder"]
          if [TrueClass, FalseClass].include?(value.class)
            Configuration.lfs_include_pods_folder = value
          end
        end
        if value = json["project_name"]
          if value.is_a?(String) && value.length > 0
            Configuration.project_name = value
          end
        end
        if value = json["restore_enabled"]
          if [TrueClass, FalseClass].include?(value.class)
            Configuration.restore_enabled = value
          end
        end
        if value = json["allow_building_development_pods"]
          if [TrueClass, FalseClass].include?(value.class)
            Configuration.allow_building_development_pods = value
          end
        end
        if value = json["use_bundler"]
          if [TrueClass, FalseClass].include?(value.class)
            Configuration.use_bundler = value
          end
        end
        if value = json["deterministic_build"]
          if [TrueClass, FalseClass].include?(value.class)
            Configuration.deterministic_build = value
          end
        end
        if value = json["build_for_apple_silicon"]
          if [TrueClass, FalseClass].include?(value.class)
            Configuration.build_for_apple_silicon = value
          end
        end
        if value = json["build_using_repo_paths"]
          if [TrueClass, FalseClass].include?(value.class)
            Configuration.build_using_repo_paths = value
          end
        end
        
        Configuration.build_settings.freeze

        sanity_check()
      end
      
      dev_pods_configuration_path = File.join(Configuration.base_path, Configuration.dev_pods_configuration_filename)
      
      if File.exist?(dev_pods_configuration_path)
        begin
          json = JSON.parse(File.read(dev_pods_configuration_path))  
        rescue => exception
          raise "\n\n#{File.basename(dev_pods_configuration_path)} is an invalid JSON\n".red
        end

        Configuration.development_pods_paths = json || []
        Configuration.development_pods_paths.freeze
      end

      if !deterministic_build
        build_path = "#{build_base_path}#{(Time.now.to_f * 1000).to_i}"
        lockfile_path = File.join(PodBuilder::home, lockfile_name)
      end
    end
    
    def self.write
      config = {}
      
      config["project_name"] = Configuration.project_name
      config["spec_overrides"] = Configuration.spec_overrides
      config["skip_licenses"] = Configuration.skip_licenses
      config["skip_pods"] = Configuration.skip_pods
      config["force_prebuild_pods"] = Configuration.force_prebuild_pods
      config["build_settings"] = Configuration.build_settings
      config["build_settings_overrides"] = Configuration.build_settings_overrides
      config["build_system"] = Configuration.build_system
      config["library_evolution_support"] = Configuration.library_evolution_support
      config["license_filename"] = Configuration.license_filename
      config["subspecs_to_split"] = Configuration.subspecs_to_split
      config["lfs_update_gitattributes"] = Configuration.lfs_update_gitattributes
      config["lfs_include_pods_folder"] = Configuration.lfs_include_pods_folder
      config["restore_enabled"] = Configuration.restore_enabled
      config["allow_building_development_pods"] = Configuration.allow_building_development_pods
      config["use_bundler"] = Configuration.use_bundler
      config["deterministic_build"] = Configuration.deterministic_build
      config["build_for_apple_silicon"] = Configuration.build_for_apple_silicon
      config["build_using_repo_paths"] = Configuration.build_using_repo_paths
      
      File.write(config_path, JSON.pretty_generate(config))
    end
    
    private 

    def self.sanity_check
      Configuration.skip_pods.each do |pod|
        if Configuration.force_prebuild_pods.include?(pod)
          puts "PodBuilder.json contains '#{pod}' both in `force_prebuild_pods` and `skip_pods`. Will force prebuilding.".yellow
        end
      end
    end
    
    def self.config_path
      unless path = podbuilder_path
        return nil
      end
      
      return File.join(path, Configuration.configuration_filename)
    end
    
    def self.podbuilder_path
      paths = Dir.glob("#{PodBuilder::home}/**/.pod_builder")
      paths.reject! { |t| t.match(/pod-builder-.*\/Example\/Frameworks\/\.pod_builder$/i) }
      raise "\n\nToo many .pod_builder found `#{paths.join("\n")}`\n".red if paths.count > 1
      
      return paths.count > 0 ? File.dirname(paths.first) : nil
    end
  end  
end
