module Normalizers
  module Email
    def self.included(base)
      base.extend ClassMethods
      # base.private_class_method :normalize_email_for_query
    end

    module ClassMethods
      def normalize_email_for_query(raw)
        raw.to_s
          .unicode_normalize(:nfkc)
          .strip
          .downcase
          .gsub(/[[:space:]]+/, "")
      end
    end
  end
end