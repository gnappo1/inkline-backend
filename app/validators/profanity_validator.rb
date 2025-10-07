class ProfanityValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    record.errors.add(attribute, (options[:message] || "contains inappropriate language")) \
      if Filters::Profanity.blocked?(value)
  end
end
