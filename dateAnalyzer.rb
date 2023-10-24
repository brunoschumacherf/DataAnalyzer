require 'csv'
require 'byebug'

class DataAnalyzer
  def initialize(file_path)
    @data, @attributes, @class = load_data(file_path)
  end

  def analyze_data
    puts "CSV file dataset:"
    puts @data
    puts

    count_dict = count_attributes(@data, @attributes, @class)
    display_attribute_counts(count_dict)

    proportions = calculate_proportions(count_dict, @data)
    display_attribute_proportions(proportions)
  end

  def discover_rules(min_confidence)
    rules = []

    while @data.length > 0
      best_antecedent, best_confidence = find_best_antecedent(min_confidence)

      if best_antecedent
        rules << [best_antecedent, @class]
        remove_covered_examples(best_antecedent)
      else
        break
      end
    end

    display_discovered_rules(rules)
  end

  private

  def load_data(file_path)
    data = CSV.read(file_path, headers: true)
    attributes = data.headers[1..-2]
    class_label = data.headers[-1]
    [data, attributes, class_label]
  end

  def count_attributes(data, attributes, class_label)
    count = {}
    attributes.each do |attribute|
      count[attribute] = {}
      data[attribute].uniq.each do |value|
        count[attribute][value] = {}
        data[class_label].uniq.each do |class_value|
          count[attribute][value][class_value] = 0
        end
      end
    end

    data.each do |row|
      attributes.each do |attribute|
        count[attribute][row[attribute]][row[class_label]] += 1
      end
    end

    count
  end

  def calculate_proportions(count, data)
    total_count = data.length
    proportions = {}

    count.each do |attribute, values|
      proportions[attribute] = {}
      values.each do |value, class_counts|
        proportions[attribute][value] = {}
        class_counts.each do |class_value, count|
          proportions[attribute][value][class_value] = (count.to_f / total_count * 100).round(9)
        end
      end
    end

    proportions
  end

  def calculate_positive_confidence(data, antecedent, class_label)
    total_examples = data.length
    positive_examples = data.select { |example| example[class_label] == "positive" }

    return 0.0 if positive_examples.empty?

    correctly_classified = positive_examples.count { |example| example[antecedent] == "positive" }

    correctly_classified.to_f / positive_examples.length
  end

  def find_best_antecedent(min_confidence)
    best_antecedent = nil
    best_confidence = 0.0

    @attributes.each do |attribute|
      confidence = calculate_positive_confidence(@data, attribute, @class)

      if confidence > best_confidence && confidence >= min_confidence
        best_antecedent = attribute
        best_confidence = confidence
      end
    end

    [best_antecedent, best_confidence]
  end

  def remove_covered_examples(antecedent)
    @data.reject! { |example| example[antecedent] == "positive" }
  end

  def display_attribute_counts(count_dict)
    puts "Counts of yes and no for each attribute:"
    count_dict.each do |key, values|
      df = values.to_a.to_h
      puts "Attribute: #{key}"
      df.each do |key, values|
        puts "  #{key}: #{values.to_a.to_h}"
      end
      puts
    end

  end

  def display_attribute_proportions(proportions)
    puts "Proportions:"
    proportions.each do |key, values|
      df = values.to_a.to_h
      puts "Attribute: #{key}"
      df.each do |key, values|
        puts "  #{key}: #{values.to_a.to_h}"
      end
      puts
    end
  end

  def display_discovered_rules(rules)
    puts "Discovered Rules:"
    rules.each_with_index do |rule, i|
      puts "Rule #{i + 1}: If #{rule[0]} then #{rule[1]}"
    end
  end
end

# Usage of the DataAnalyzer class
analyzer = DataAnalyzer.new("file.csv")
analyzer.analyze_data
analyzer.discover_rules(0.07) # Adjust this value to see how it affects the rules
