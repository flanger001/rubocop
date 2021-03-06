# frozen_string_literal: true

module RuboCop
  class CLI
    module Command
      # Run all the selected cops and report the result.
      # @api private
      class SuggestExtensions < Base
        # Combination of short and long formatter names.
        INCLUDED_FORMATTERS = %w[p progress fu fuubar pa pacman].freeze

        self.command_name = :suggest_extensions

        def self.dependent_gems
          return [] unless defined?(Bundler)

          # This only includes gems in Gemfile, not in lockfile
          Bundler.load.dependencies.map(&:name)
        rescue Bundler::GemfileNotFound
          []
        end

        def run
          return if skip? || extensions.none?

          puts
          puts 'Tip: Based on detected gems, the following '\
            'RuboCop extension libraries might be helpful:'

          extensions.sort.each do |extension|
            puts "  * #{extension} (http://github.com/rubocop-hq/#{extension})"
          end

          puts
          puts 'You can opt out of this message by adding the following to your config '\
            '(see https://docs.rubocop.org/rubocop/extensions.html#extension-suggestions '\
            'for more options):'
          puts '  AllCops:'
          puts '    SuggestExtensions: false'

          puts if @options[:display_time]
        end

        private

        def skip?
          # Disable outputting the notification:
          # 1. On CI
          # 2. When given RuboCop options that it doesn't make sense for
          # 3. For all formatters except specified in `INCLUDED_FORMATTERS'`
          ENV['CI'] ||
            @options[:only] || @options[:debug] || @options[:list_target_files] || @options[:out] ||
            !INCLUDED_FORMATTERS.include?(current_formatter)
        end

        def current_formatter
          @options[:format] || @config_store.for_pwd.for_all_cops['DefaultFormatter'] || 'p'
        end

        def extensions
          return [] unless dependent_gems.any?

          @extensions ||= begin
            extensions = @config_store.for_pwd.for_all_cops['SuggestExtensions'] || {}
            extensions.select { |_, v| (Array(v) & dependent_gems).any? }.keys - dependent_gems
          end
        end

        def puts(*args)
          output = (@options[:stderr] ? $stderr : $stdout)
          output.puts(*args)
        end

        def dependent_gems
          @dependent_gems ||= self.class.dependent_gems
        end
      end
    end
  end
end
