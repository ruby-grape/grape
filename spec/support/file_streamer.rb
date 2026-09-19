# frozen_string_literal: true

class FileStreamer
  def initialize(file_path)
    @file_path = file_path
  end

  def each(&)
    File.open(@file_path, 'rb') do |file|
      file.each(10, &)
    end
  end
end
