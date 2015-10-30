module Pod
  class Command
    class Search < Command
      self.summary = 'Search for pods.'

      self.description = <<-DESC
        Searches for pods, ignoring case, whose name matches `QUERY`. If the
        `--full` option is specified, this will also search in the summary and
        description of the pods.
      DESC

      self.arguments = [
        CLAide::Argument.new('QUERY', true),
      ]

      def self.all_platforms
        Specification::PLATFORMS.map do |platform|
          platform.to_s
        end
      end

      def all_platforms
        self.class.all_platforms
      end

      def self.options
        options = [
          ['--regex',   'Interpret the `QUERY` as a regular expression'],
          ['--full',    'Search by name, summary, description, and authors'],
          ['--stats',   'Show additional stats (like GitHub watchers and forks)'],
          ['--web',     'Searches on cocoapods.org'],
        ]
        options += all_platforms.map do |platform|
          ["--#{platform}",     "Restricts the search to Pods supported on #{platform}"]
        end
        options.concat(super.reject { |option, _| option == '--silent' })
      end 

      def initialize(argv)
        @use_regex = argv.flag?('regex')
        @full_text_search = argv.flag?('full')
        @stats = argv.flag?('stats')
        @web = argv.flag?('web')
        @platform_filters = all_platforms.map do |platform|
          argv.flag?(platform) ? platform.to_sym : nil
        end.compact
        @query = argv.arguments! unless argv.arguments.empty?
        config.silent = false
        super
      end

      def validate!
        super
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
        ensure_master_spec_repo_exists!
        if @web
          web_search
        else
          local_search
        end
      end

      def web_search
        queries = @platform_filters.map do |platform|
          "on:#{platform}"
        end
        queries += @query
        query_parameter = queries.compact.flatten.join(' ')
        url = "https://cocoapods.org/?q=#{CGI.escape(query_parameter).gsub('+', '%20')}"
        UI.puts("Opening #{url}")
        open!(url)
      end

      def local_search
        query_regex = @query.reduce([]) { |result, q|
          result << (@use_regex ? q : Regexp.escape(q))
        }.join(' ').strip

        sets = SourcesManager.search_by_name(query_regex, @full_text_search)

        @platform_filters.each do |platform|
          sets.reject! { |set| !set.specification.available_platforms.map(&:name).include?(platform) }
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
