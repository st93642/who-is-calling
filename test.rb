require 'minitest/autorun'
require 'json'
require_relative 'app'

# Helper module to stub Redis
module RedisStub
  def self.setup(data = {})
    redis = Object.new
    redis.define_singleton_method(:get) do |key|
      data[key]
    end
    redis
  end
end

class PhoneNormalizationTest < Minitest::Test
  def test_normalize_local_number
    result = normalize_phone('22811907')
    assert_equal '37122811907', result
  end

  def test_normalize_international_with_plus
    result = normalize_phone('+37122811907')
    assert_equal '37122811907', result
  end

  def test_normalize_with_spaces
    result = normalize_phone('+371 22811907')
    assert_equal '37122811907', result
  end

  def test_normalize_with_dashes
    result = normalize_phone('+371-22811907')
    assert_equal '37122811907', result
  end

  def test_normalize_with_parentheses
    result = normalize_phone('+371 (22) 811907')
    assert_equal '37122811907', result
  end

  def test_normalize_already_normalized
    result = normalize_phone('37122811907')
    assert_equal '37122811907', result
  end

  def test_normalize_empty_raises_error
    assert_raises(ArgumentError) { normalize_phone('') }
  end

  def test_normalize_nil_raises_error
    assert_raises(ArgumentError) { normalize_phone(nil) }
  end

  def test_normalize_invalid_chars_raises_error
    assert_raises(ArgumentError) { normalize_phone('abc123') }
  end
end

class SearchEndpointTest < Minitest::Test
  def setup
    # Stub Redis for tests
    @test_data = {
      '37122811907' => '["https://example.gov.lv", "https://another.gov.lv"]'
    }
    $redis = RedisStub.setup(@test_data)
  end

  def test_health_check_returns_ok
    app = create_test_app
    result = app.call('REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/')
    assert_equal 200, result[0]
    assert_equal 'OK', result[2].join
  end

  def test_search_with_local_number
    app = create_test_app
    env = {
      'REQUEST_METHOD' => 'GET',
      'PATH_INFO' => '/search',
      'QUERY_STRING' => 'number=22811907',
      'rack.input' => StringIO.new,
      'rack.errors' => $stderr
    }
    result = app.call(env)
    assert_equal 200, result[0]
    
    body = JSON.parse(result[2].join)
    assert body['found']
    assert_equal '37122811907', body['normalized_number']
    assert_equal 2, body['results'].length
  end

  def test_search_with_international_number
    app = create_test_app
    env = {
      'REQUEST_METHOD' => 'GET',
      'PATH_INFO' => '/search',
      'QUERY_STRING' => 'number=+37122811907',
      'rack.input' => StringIO.new,
      'rack.errors' => $stderr
    }
    result = app.call(env)
    assert_equal 200, result[0]
    
    body = JSON.parse(result[2].join)
    assert body['found']
    assert_equal '37122811907', body['normalized_number']
  end

  def test_search_not_found
    app = create_test_app
    env = {
      'REQUEST_METHOD' => 'GET',
      'PATH_INFO' => '/search',
      'QUERY_STRING' => 'number=99999999',
      'rack.input' => StringIO.new,
      'rack.errors' => $stderr
    }
    result = app.call(env)
    assert_equal 200, result[0]
    
    body = JSON.parse(result[2].join)
    refute body['found']
    assert_empty body['results']
    assert_equal '37199999999', body['normalized_number']
  end

  def test_search_missing_parameter
    app = create_test_app
    env = {
      'REQUEST_METHOD' => 'GET',
      'PATH_INFO' => '/search',
      'rack.input' => StringIO.new,
      'rack.errors' => $stderr
    }
    result = app.call(env)
    assert_equal 400, result[0]
    
    body = JSON.parse(result[2].join)
    assert body['error']
  end

  def test_search_invalid_number
    app = create_test_app
    env = {
      'REQUEST_METHOD' => 'GET',
      'PATH_INFO' => '/search',
      'QUERY_STRING' => 'number=invalid',
      'rack.input' => StringIO.new,
      'rack.errors' => $stderr
    }
    result = app.call(env)
    assert_equal 400, result[0]
    
    body = JSON.parse(result[2].join)
    assert body['error']
  end

  private

  def create_test_app
    Sinatra::Application
  end
end
