require_relative 'encoding_holmes'
require_relative 'encoding_rchardet'
require_relative 'encoding_uchardet'

module ACSV
  module Detect
    class << self

      # Default confidence level for encoding detection to succeed
      CONFIDENCE = 0.6
      # Number of bytes to test encoding on
      PREVIEW_BYTES = 8 * 4096

      ENCODING_DETECTORS_ALL = [ EncodingHolmes, EncodingRChardet, EncodingUChardet ]
      ENCODING_DETECTORS_AVAIL = ENCODING_DETECTORS_ALL.select(&:present?)

      # Tries to detect the file encoding.
      #
      # @param file_or_data [File, String] CSV file or data to probe
      # @option options [Number] :confidence minimum confidence level (0-1)
      # @option options [String] :method try only specific method, one of {encoding_methods}
      # @return [String] most probable encoding
      def encoding(file_or_data, options={})
        options = options_with_default(options)

        if file_or_data.is_a? File
          position = file_or_data.tell
          data = file_or_data.read(PREVIEW_BYTES)
          file_or_data.seek(position)
        else
          data = file_or_data
        end

        detector_do(options) do |detector|
          if enc = detector.encoding(data, options)
            return enc
          end
        end
      end

      # @return [Array<String>] List of available methods for encoding
      def encoding_methods
        ENCODING_DETECTORS_AVAIL.map(&:require_name)
      end

      # @return [Array<String>] List of possible methods for encoding (even if its gem is missing)
      def encoding_methods_all
        ENCODING_DETECTORS_ALL.map(&:require_name)
      end

      protected

      # Run supplied block on detectors
      # @option options [Boolean] :method Only try this method, instead of trying all
      def detector_do(options)
        if options[:method]
          detector = ENCODING_DETECTORS_AVAIL.select{|d| d.require_name == options[:method]}.first
          yield detector
        else
          ENCODING_DETECTORS_AVAIL.each do |detector|
            yield detector if detector.present?
          end
        end
      end

      # Merge default options with those supplied
      # @param options [Hash] supplied options
      # @return [Hash<Symbol, Object>] Options with defaults
      def options_with_default(options)
        {confidence: CONFIDENCE}.merge options
      end

    end
  end
end
