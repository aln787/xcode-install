require 'uri'

module XcodeInstall
  class Command
    class Install < Command
      self.command = 'install'
      self.summary = 'Install a specific version of Xcode.'

      self.arguments = [
        CLAide::Argument.new('VERSION', :true)
      ]

      def self.options
        [['--url', 'Custom Xcode DMG file path or HTTP URL.'],
         ['--force', 'Install even if the same version is already installed.'],
         ['--no-switch', 'Don’t switch to this version after installation'],
         ['--no-install', 'Only download DMG, but do not install it.'],
         ['--no-progress', 'Don’t show download progress.'],
         ['--no-clean', 'Don’t delete DMG after installation.']].concat(super)
      end

      def initialize(argv)
        @installer = Installer.new
        @version = argv.shift_argument
        @url = argv.option('url')
        @force = argv.flag?('force', false)
        @should_clean = argv.flag?('clean', true)
        @should_install = argv.flag?('install', true)
        @should_switch = argv.flag?('switch', true)
        @progress = argv.flag?('progress', true)
        super
      end

      def validate!
        super
        
        osx_version = `sw_vers -productVersion`.delete!("\n")
        version_parts = osx_version.split('.')

        major = version_parts[0].to_i
        minor = version_parts[1].to_i
        patch = version_parts[2].to_i

        errorMsg = "An OS X version >10.11.4 is required for xcode 8, you have #{osx_version}."

        if minor < 12
          fail Informative, errorMsg
        elsif minor == 11
          if patch < 8
            fail Informative, errorMsg
          end
        end
        
        help! 'A VERSION argument is required.' unless @version
        fail Informative, "Version #{@version} already installed." if @installer.installed?(@version) && !@force
        fail Informative, "Version #{@version} doesn't exist." unless @url || @installer.exist?(@version)
        fail Informative, "Invalid URL: `#{@url}`" unless !@url || @url =~ /\A#{URI.regexp}\z/
      end

      def run
        @installer.install_version(@version, @should_switch, @should_clean, @should_install,
                                   @progress, @url)
      end
    end
  end
end
