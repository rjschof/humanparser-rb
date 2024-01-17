class NameParser
  class << self

    def diff(a1, a2)
      (a1 + a2).select { |val| (a1 + a2).count(val) == 1 }
    end

    def lc(value)
      value.downcase
    end

    def parse_name(name, opts = {})
      extra_compound, extra_salutations, extra_suffixes, ignore_compound, ignore_salutation, ignore_suffix = parse_options(opts)

      salutations = ['mr', 'master', 'mister', 'mrs', 'miss', 'ms', 'dr', 'prof', 'rev', 'fr', 'judge', 'honorable', 'hon', 'tuan', 'sr', 'srta', 'br', 'pr', 'mx', 'sra', *extra_salutations].reject { |salutation| ignore_salutation.include?(salutation) }
      suffixes = ['i', 'ii', 'iii', 'iv', 'v', 'senior', 'junior', 'jr', 'sr', 'phd', 'apr', 'rph', 'pe', 'md', 'ma', 'dmd', 'cme', 'qc', 'kc', *extra_suffixes].reject { |suffix| ignore_suffix.include?(suffix) }
      compound = ['vere', 'von', 'van', 'de', 'del', 'della', 'der', 'den', 'di', 'da', 'pietro', 'vanden', 'du', 'st.', 'st', 'la', 'lo', 'ter', 'bin', 'ibn', 'te', 'ten', 'op', 'ben', 'al', *extra_compound].reject { |comp| ignore_compound.include?(comp) }

      parts = name
        .strip
        .gsub(/\b\s+(,\s+)\b/, '\1')  # fix name , suffix -> name, suffix
        .gsub(/\b,\b/, ', ')          # fix name,suffix -> name, suffix
        .scan(/[^\s"]+|"[^"]+"/)
        .map { |n| n.match(/^".*"$/) ? n[1..-2] : n }

      attrs = {}

      return attrs if parts.empty?

      if parts.length == 1
        attrs[:first_name] = parts[0]
      end

      if parts.length > 1 && suffixes.include?(parts[-1].downcase.delete('.'))
        attrs[:suffix] = parts.pop
        parts[-1] = parts[-1].delete(',')
      end

      first_name_first_format = parts.all? { |part| !part.include?(',') }

      if !first_name_first_format
        last_name_index = nil

        parts.each_with_index do |current, index|
          if current.include?(',')
            current = current.delete(',')

            if suffixes.include?(current.downcase.delete('.'))
              attrs[:suffix] = current
            else
              last_name_index = index + 1
            end

            break
          end
        end

        last_name = last_name_index ? parts[0...last_name_index].join(' ') : parts.join(' ')
        attrs[:last_name] = last_name

        remaining_parts = parts[last_name_index..-1]

        if remaining_parts.length > 1
          attrs[:first_name] = remaining_parts.shift
          attrs[:middle_name] = remaining_parts.join(' ')
        elsif remaining_parts.length == 1
          attrs[:first_name] = remaining_parts[0]
        end

        full_name = [attrs[:first_name], attrs[:middle_name], attrs[:last_name], attrs[:suffix]].compact.join(' ')
        attrs[:full_name] = full_name
      else
        if parts.length > 1 && salutations.include?(parts[0].downcase.delete('.'))
          attrs[:salutation] = parts.shift

          if parts.length == 1
            attrs[:last_name] = parts.shift
          else
            attrs[:first_name] = parts.shift
          end
        else
          attrs[:first_name] = parts.shift
        end

        if !attrs[:last_name]
          attrs[:last_name] = parts.length > 0 ? parts.pop : ''
        end

        rev_parts = parts.reverse
        compound_parts = []

        rev_parts.each do |part|
          test = part.downcase.delete('.')
          if compound.include?(test)
            compound_parts.push(part)
          else
            break
          end
        end

        if !compound_parts.empty?
          attrs[:last_name] = compound_parts.reverse.join(' ') + ' ' + attrs[:last_name]
          parts = diff(parts, compound_parts)
        end

        if !parts.empty?
          attrs[:middle_name] = parts.join(' ')
        end

        attrs[:last_name] = attrs[:last_name].delete(',')
      end

      attrs.transform_values!(&:strip)
      attrs
    end

    def get_fullest_name(str)
      name = str
      names = []

      if name.include?('&') || name.downcase.include?(' and ')
        names = name.split(/\s+(?:and|&)\s+/i)
        name = names.max_by { |n| n.split(/\s+/).length }
      end

      name
    end

    def parse_address(str)
      str = str.gsub(/\n/i, ', ')
      parts = str.split(/,\s+/).reverse
      state_zip = parts[0].split(/\s+/)
      city = parts[1]
      
      {
        address: parts[2..-1].reverse.join(', '),
        city: city,
        state: state_zip[0],
        zip: state_zip[1],
        full_address: str
      }
    end

    private

    def parse_options(opts)
      if opts.is_a?(Array)
        ignore_suffix = opts.map(&:downcase)
      else
        extra_compound = Array(opts[:extra_compound]).map(&method(:lc))
        extra_salutations = Array(opts[:extra_salutations]).map(&method(:lc))
        extra_suffixes = Array(opts[:extra_suffixes]).map(&method(:lc))
        ignore_compound = Array(opts[:ignore_compound]).map(&method(:lc))
        ignore_salutation = Array(opts[:ignore_salutation]).map(&method(:lc))
        ignore_suffix = Array(opts[:ignore_suffix]).map(&method(:lc))
      end

      [extra_compound, extra_salutations, extra_suffixes, ignore_compound, ignore_salutation, ignore_suffix]
    end
  end
end
