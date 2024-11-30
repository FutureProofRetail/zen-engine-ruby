require 'minitest/autorun'
require 'json'
require_relative '../lib/zen-engine-ruby'

def loader(key)
  File.read(File.expand_path("../test-data/#{key}", __FILE__))
end

def graph_loader(key)
  File.read(File.expand_path("../test-data/graphs/#{key}", __FILE__))
end

def custom_handler(request)
  p1 = request.fetch("node").fetch("config").fetch("prop1")
  {
    "output" => {
      "sum" => p1
    }
  }
end

class TestZenEngine < Minitest::Test
  def test_decision_using_loader
    engine = ZenRuby::Engine.new(loader: method(:loader))
    r1 = engine.evaluate!("function.json", { "input" => 5 })
    r2 = engine.evaluate!("table.json", { "input" => 2 })
    r3 = engine.evaluate!("table.json", { "input" => 12 })

    assert_equal 10, r1["result"]["output"]
    assert_equal 0, r2["result"]["output"]
    assert_equal 10, r3["result"]["output"]
  end

  def test_decisions_using_get_decision
    engine = ZenRuby::Engine.new(loader: method(:loader))

    function_decision = engine.get_decision!("function.json")

    table_decision = engine.get_decision!("table.json")

    r1 = function_decision.evaluate!({ "input" => 10 })
    r2 = table_decision.evaluate!({ "input" => 5 })
    r3 = table_decision.evaluate!({ "input" => 12 })

    assert_equal 20, r1["result"]["output"]
    assert_equal 0, r2["result"]["output"]
    assert_equal 10, r3["result"]["output"]
  end

  def test_create_decisions_from_content
    engine = ZenRuby::Engine.new
    function_content = File.read(File.expand_path("../test-data/function.json", __FILE__))
    function_decision = engine.create_decision!(function_content)

    r = function_decision.evaluate!({ "input" => 15 })
    assert_equal 30, r["result"]["output"]
  end

  def test_engine_custom_handler
    skip "Custom node handler not implemented yet"
    engine = ZenRuby::Engine.new(loader: method(:loader), custom_handler: method(:custom_handler))
    r1 = engine.evaluate!("custom.json", { "a" => 10 })
    r2 = engine.evaluate!("custom.json", { "a" => 20 })
    r3 = engine.evaluate!("custom.json", { "a" => 30 })

    assert_equal 20, r1["result"]["sum"]
    assert_equal 30, r2["result"]["sum"]
    assert_equal 40, r3["result"]["sum"]
  end

  def test_evaluate_expression
    result = ZenRuby.evaluate_expression!("sum(a)", { "a" => [1, 2, 3, 4] })
    assert_equal 10, result
  end

  def test_evaluate_unary_expression
    result = ZenRuby.evaluate_unary_expression!("'FR', 'ES', 'GB'", { "$" => "GB" })
    assert_equal true, result
  end

  def test_render_template
    result = ZenRuby.render_template!("{{ a + b }}", { "a" => 10, "b" => 20 })
    assert_equal 30, result
  end

  def test_evaluate_graphs
    engine = ZenRuby::Engine.new(loader: method(:graph_loader))
    json_files = Dir.glob("./test-data/graphs/*.json")

    json_files.each do |json_file|
      json_contents = JSON.parse(File.read(json_file))

      json_contents["tests"].each do |test_case|
        key = File.basename(json_file)

        engine_response = engine.evaluate!(key, test_case["input"])
        decision = engine.get_decision!(key)
        decision_response = decision.evaluate!(test_case["input"])

        assert_equal test_case["output"], engine_response["result"]
        assert_equal test_case["output"], decision_response["result"]
      end
    end
  end
end
