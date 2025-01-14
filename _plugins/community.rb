# frozen_string_literal: true

module Jekyll
  module CommunityFilter
    def community(people, state, sort_by = 'oldest')
      now = Date.today

      past, current = people.partition do |person|
        date = person.data['missions']&.last&.dig('end')

        date && date <= now
      end

      result = state == 'past' ? past : current

      result = if sort_by == 'alpha'
                 result.sort_by { |person| person.data['fullname'] }
               else
                 result.sort_by do |person|
                   person.data['missions']&.map do |e|
                     e['start'] || Date.today
                   end&.min || Date.today
                 end.reverse
               end

      if state == 'recent'
        result.first(3)
      else
        result
      end
    end
  end

  class RenderCommunityStatsTag < Liquid::Tag
    def initialize(tag_name, input, tokens)
      super
      @input = input
    end

    def render(context)
      result = {
        'employer' => {
          'admin' => [],
          'independent' => [],
          'service' => []
        },
        'domaineOverDate' => {
          'Déploiement' => [],
          'Design' => [],
          'Développement' => [],
          'Coaching' => [],
          'Autre' => [],
          'Intraprenariat' => [],
          'Animation' => [],
          'Produit' => [],
          'Data' => []
        },
        'domaine' => {
          'Déploiement' => 0,
          'Design' => 0,
          'Développement' => 0,
          'Coaching' => 0,
          'Autre' => 0,
          'Intraprenariat' => 0,
          'Animation' => 0,
          'Produit' => 0,
          'Data' => 0
        },
        'total' => 0
      }
      authors = context.registers[:site].collections['authors']
      now = Date.today
      authors.docs.each do |author|
        next unless author.data['missions']

        author.data['missions'].each do |mission|
          startDate = mission['start']
          endDate = mission['end']
          result['employer'][mission['status']] << { date: startDate, increment: 1 } if startDate && (startDate != '')
          result['employer'][mission['status']] << { date: endDate, increment: -1 } if endDate && (endDate != '')
          if startDate && (startDate != '')
            result['domaineOverDate'][author.data['domaine']] << { date: startDate,
                                                                   increment: 1 }
          end
          if endDate && (endDate != '')
            result['domaineOverDate'][author.data['domaine']] << { date: endDate,
                                                                   increment: -1 }
          end
        end
        if author.data['missions']&.last&.[]('end')&.>= now
          result['domaine'][author.data['domaine']] = result['domaine'][author.data['domaine']] + 1
          result['total'] = result['total'] + 1
        end
      end
      return result.to_json unless !@input.nil? && !@input.empty?

      key = @input.strip
      result[key]
    end
  end
end

Liquid::Template.register_filter(Jekyll::CommunityFilter)
Liquid::Template.register_tag('render_community_stats', Jekyll::RenderCommunityStatsTag)
