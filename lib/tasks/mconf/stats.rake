namespace :mconf do

  desc "Global Statistics"
  task :stats => :environment do
    %w(User Space Event Post).map(&:constantize).each{ |k| print_stats(k) }
  end

  def print_stats(klass)
    puts "#{ I18n.t(klass.to_s.underscore, :count => :other) }:"
    puts "\tTotal: #{ klass.count }"

    # Create a Hash like stats_hash[year][month] = 0
    stats_hash = Hash.new{ |h, year| h[year] = Hash.new{ |year, month| year[month] = 0 } }

    klass.all.each do |obj|
      stats_hash[obj.created_at.year][obj.created_at.month] += 1
    end

    stats_hash.each_pair do |year, months|
      (1..12).each do |month|
        puts "\t#{year} #{ format("%2d", month) }: #{months[month] }"
      end
    end
  end

end
