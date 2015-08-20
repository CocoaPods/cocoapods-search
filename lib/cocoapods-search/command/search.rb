module Pod
  class Command
    # This is an example of a cocoapods plugin adding a top-level subcommand
    # to the 'pod' command.
    #
    # You can also create subcommands of existing or new commands. Say you
    # wanted to add a subcommand to `list` to show newly deprecated pods,
    # (e.g. `pod list deprecated`), there are a few things that would need
    # to change.
    #
    # - move this file to `lib/pod/command/list/deprecated.rb` and update
    #   the class to exist in the the Pod::Command::List namespace
    # - change this class to extend from `List` instead of `Command`. This
    #   tells the plugin system that it is a subcommand of `list`.
    # - edit `lib/cocoapods_plugins.rb` to require this file
    #
    # @todo Create a PR to add your plugin to CocoaPods/cocoapods.org
    #       in the `plugins.json` file, once your plugin is released.
    #
     UI.puts "under class Command"
    class Search < Command
      UI.puts "under class Search"
      self.summary = 'Search for pods.'

      self.description = <<-DESC
        Searches for pods, ignoring case, whose name matches `QUERY`. If the
        `--full` option is specified, this will also search in the summary and
        description of the pods.
      DESC

      self.arguments = [
        CLAide::Argument.new('QUERY', true),
      ] #'NAME'

      def self.options
        [
          ['--regex', 'Interpret the `QUERY` as a regular expression'],
          ['--full',  'Search by name, summary, and description'],
          ['--stats', 'Show additional stats (like GitHub watchers and forks)'],
          ['--ios',   'Restricts the search to Pods supported on iOS'],
          ['--osx',   'Restricts the search to Pods supported on OS X'],
          ['--web',   'Searches on cocoapods.org'],
        ].concat(super.reject { |option, _| option == '--silent' })
      end 

      def initialize(argv)
        #@name = argv.shift_argument  - default when i created the plugin
        @use_regex = argv.flag?('regex')
        @full_text_search = argv.flag?('full')
        @stats = argv.flag?('stats')
        @supported_on_ios = argv.flag?('ios')
        @supported_on_osx = argv.flag?('osx')
        @web = argv.flag?('web')
        @query = argv.arguments! unless argv.arguments.empty?
        config.silent = false
        super
      end

      def validate!
        super
        #help! 'A Pod name is required.' unless @name
        help! 'A search query is required.' unless @query

        unless @web || !@use_regex
          begin
            /#{@query.join(' ').strip}/
          rescue RegexpError
            help! 'A valid regular expression is required.'
          end
        end  

      end

      def run
        UI.puts "run local cocoapods-search" #for debuging purpose
        #UI.puts "Add your implementation for the cocoapods-search plugin in #{__FILE__}"
        ensure_master_spec_repo_exists!
        if @web
          web_search
        else
          local_search
        end
      end

      def web_search
        query_parameter = [
          ('on:osx' if @supported_on_osx),
          ('on:ios' if @supported_on_ios),
          @query,
        ].compact.flatten.join(' ')
        url = "http://cocoapods.org/?q=#{CGI.escape(query_parameter).gsub('+', '%20')}"
        UI.puts("Opening #{url}")
        open!(url)
      end

      def local_search
        query_regex = @query.join(' ').strip
        query_regex = Regexp.escape(query_regex) unless @use_regex

        sets = SourcesManager.search_by_name(query_regex, @full_text_search)
        if @supported_on_ios
          sets.reject! { |set| !set.specification.available_platforms.map(&:name).include?(:ios) }
        end
        if @supported_on_osx
          sets.reject! { |set| !set.specification.available_platforms.map(&:name).include?(:osx) }
        end

       sets.each do |set|
          begin
            if @stats
              UI.pod(set, :stats)
            else
              UI.pod(set, :normal)
            end
          rescue DSLError
            UI.warn "Skipping `#{set.name}` because the podspec contains errors."
          end 
        end
      end
    end
  end
end
