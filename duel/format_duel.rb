# frozen_string_literal: true

require_relative 'duel_helper'

# Formatting responses: negotiating the format from the Accept header or
# the path's extension, and rendering the body, plain or presented.

Book = Struct.new(:id, :title, :author, :year, :isbn, :tags)

# Stands in for a grape-entity Entity, which `present` calls the same way
# (grape-entity isn't in the development bundle).
class BookRepresenter
  def self.represent(object, options = {})
    return object.map { |book| represent(book, options) } if object.respond_to?(:to_ary)

    { id: object.id, title: object.title, author: object.author, year: object.year, isbn: object.isbn, tags: object.tags }
  end
end

BOOKS = Array.new(50) do |i|
  Book.new(i, "Book #{i}", "Author #{i % 7}", 1900 + i, "978-0-#{i.to_s.rjust(6, '0')}-#{i % 10}", %w[fiction classic])
end.freeze

class FormatAPI < Grape::API
  format :json
  represent Book, with: BookRepresenter

  get('ping') { { status: 'ok' } }
  get('books') { BOOKS.map(&:to_h) }
  get('books/presented') { present BOOKS, root: :books }
  get('books/:id') { present BOOKS.fetch(params[:id].to_i), with: BookRepresenter }
end

class NegotiatingAPI < Grape::API
  content_type :json, 'application/json'
  content_type :xml, 'application/xml'
  content_type :txt, 'text/plain'
  default_format :json

  get('status') { { status: 'ok', version: '1.2.3' } }
end

duel 'format: render a small JSON object' do |n|
  once { prepare(FormatAPI, rack_env('/ping'), 200, 'ok') }
  serve(@app, @env, n)
end

duel 'format: render a JSON array of 50 hashes' do |n|
  once { prepare(FormatAPI, rack_env('/books'), 200, 'Book 49') }
  serve(@app, @env, n)
end

duel 'format: present 50 objects with a representer' do |n|
  once { prepare(FormatAPI, rack_env('/books/presented'), 200, 'Book 49') }
  serve(@app, @env, n)
end

duel 'format: present one object with a representer' do |n|
  once { prepare(FormatAPI, rack_env('/books/7'), 200, 'Book 7') }
  serve(@app, @env, n)
end

duel 'format: negotiate the format from a browser Accept header' do |n|
  once do
    accept = 'text/html,application/xhtml+xml,application/json;q=0.9,application/xml;q=0.8,*/*;q=0.5'
    prepare(NegotiatingAPI, rack_env('/status', headers: { 'Accept' => accept }), 200, '"version"')
  end
  serve(@app, @env, n)
end

duel 'format: take the format from the extension' do |n|
  once { prepare(NegotiatingAPI, rack_env('/status.txt'), 200, 'ok') }
  serve(@app, @env, n)
end
