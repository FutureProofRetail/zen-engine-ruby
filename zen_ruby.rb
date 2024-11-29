require "ffi"
require "json"

module ZenRuby
  module LibC
    extend FFI::Library
    ffi_lib FFI::Library::LIBC

    attach_function :strdup, [:string], :pointer
  end

  extend FFI::Library
  ffi_lib "deps/darwin_arm64/libzen_ffi.dylib"

  # typedef struct ZenDecisionLoaderResult {
  #   char *content;
  #   char *error;
  # } ZenDecisionLoaderResult;
  class ZenDecisionLoaderResult < FFI::Struct
    layout :content, :pointer,
           :error, :pointer
  end

  # typedef struct ZenCustomNodeResult {
  #   char *content;
  #   char *error;
  # } ZenCustomNodeResult;
  class ZenCustomNodeResult < FFI::Struct
    layout :content, :pointer,
           :error, :pointer
  end

  # typedef struct ZenEngineEvaluationOptions {
  #   bool trace;
  #   uint8_t max_depth;
  # } ZenEngineEvaluationOptions;
  class ZenEngineEvaluationOptions < FFI::Struct
    layout :trace, :bool,
           :max_depth, :uint8
  end

  # typedef struct ZenResult_c_char {
  #   char *result;
  #   uint8_t error;
  #   char *details;
  # } ZenResult_c_char;
  class ZenResult_c_char < FFI::Struct
    layout :result, :pointer,
           :error, :uint8,
           :details, :pointer
  end

  # typedef struct ZenResult_c_int {
  #   int *result;
  #   uint8_t error;
  #   char *details;
  # } ZenResult_c_int;
  class ZenResult_c_int < FFI::Struct
    layout :result, :pointer,
           :error, :uint8,
           :details, :pointer
  end

  # typedef struct ZenResult_ZenDecisionStruct {
  #   struct ZenDecisionStruct *result;
  #   uint8_t error;
  #   char *details;
  # } ZenResult_ZenDecisionStruct;
  class ZenResult_ZenDecisionStruct < FFI::Struct
    layout :result, :pointer,
           :error, :uint8,
           :details, :pointer
  end

  # typedef struct ZenDecisionLoaderResult (*ZenDecisionLoaderNativeCallback)(const char *key);
  callback :zen_decision_loader_native_callback, [:string], ZenDecisionLoaderResult.by_value

  # typedef struct ZenCustomNodeResult (*ZenCustomNodeNativeCallback)(const char *request);
  callback :zen_custom_node_native_callback, [:string, :pointer], ZenCustomNodeResult.by_value

  attach_function :zen_engine_new_native, 
    [:zen_decision_loader_native_callback, :zen_custom_node_native_callback], 
    :pointer

  # void zen_engine_free(struct ZenEngineStruct *engine);
  attach_function :zen_engine_free, [:pointer], :void

  # struct ZenResult_c_char zen_engine_evaluate(const struct ZenEngineStruct *engine,
  #                                         const char *key,
  #                                         const char *context,
  #                                         struct ZenEngineEvaluationOptions options);
  attach_function :zen_engine_evaluate,
                  [:pointer, :string, :string, ZenEngineEvaluationOptions.by_value],
                  ZenResult_c_char.by_value

  # struct ZenResult_ZenDecisionStruct zen_engine_get_decision(const struct ZenEngineStruct *engine,
  #                                                          const char *key);
  attach_function :zen_engine_get_decision,
                  [:pointer, :string],
                  ZenResult_ZenDecisionStruct.by_value

  # struct ZenResult_ZenDecisionStruct zen_engine_create_decision(const struct ZenEngineStruct *engine,
  #                                                            const char *content);
  attach_function :zen_engine_create_decision,
                  [:pointer, :string],
                  ZenResult_ZenDecisionStruct.by_value

  # struct ZenResult_c_char zen_decision_evaluate(const struct ZenDecisionStruct *decision,
  #                                              const char *context_ptr,
  #                                              struct ZenEngineEvaluationOptions options);
  attach_function :zen_decision_evaluate,
                  [:pointer, :string, ZenEngineEvaluationOptions.by_value],
                  ZenResult_c_char.by_value

  # struct ZenResult_c_char zen_evaluate_expression(const char *expression, const char *context);
  attach_function :zen_evaluate_expression,
                  [:string, :string],
                  ZenResult_c_char.by_value

  # struct ZenResult_c_int zen_evaluate_unary_expression(const char *expression, const char *context);
  attach_function :zen_evaluate_unary_expression,
                  [:string, :string],
                  ZenResult_c_int.by_value

  # struct ZenResult_c_char zen_evaluate_template(const char *template_, const char *context);
  attach_function :zen_evaluate_template,
                  [:string, :string],
                  ZenResult_c_char.by_value

  class Engine
    def initialize(loader: nil, custom_handler: nil)
      if loader
        @loader_callback = Proc.new do |key|
          content_json = loader.call(key)

          loader_result = ZenDecisionLoaderResult.new
          
          # Allocate memory that won't be managed by Ruby
          # (if we use MemoryPointer here, it'll cause double-free errors)
          loader_result[:content] = LibC.strdup(content_json)
          loader_result
        end
      end

      if custom_handler
        raise NotImplementedError, "Custom Node handler not implemented yet"
        # @custom_node_callback = Proc.new do |request_str|
        #   request = JSON.parse(request_str)
        #   custom_handler.call(request).tap do |a|
        #     puts a

        #   end
        # end
      end

      raw_pointer = ZenRuby.zen_engine_new_native(@loader_callback, @custom_node_callback)

      # Because we need to do custom cleanup (via `zen_engine_free`) rather than
      # just the usual `free` performed by MemoryPointer, we use AutoPointer.
      @engine_ptr = FFI::AutoPointer.new(raw_pointer, ZenRuby.method(:zen_engine_free))
    end

    def evaluate(key, context, trace: false, max_depth: 10)
      evaluation_options = ZenEngineEvaluationOptions.new
      evaluation_options[:trace] = trace
      evaluation_options[:max_depth] = max_depth

      raw_result = ZenRuby.zen_engine_evaluate(@engine_ptr, key, context.to_json, evaluation_options)
      ZenRuby::Result.from_raw_result(raw_result)
    end

    def evaluate!(key, context, trace: false, max_depth: 10)
      ZenRuby.unwrap_result!(evaluate(key, context, trace:, max_depth:))
    end

    # Fetch a decision by providing a key to the decision JSON file. Uses
    # the loader to fetch/read the actual JSON data for the Decision graph.
    def get_decision(key)
      # Caller is responsible for freeing: key and ZenResult.
      raw_result = ZenRuby.zen_engine_get_decision(@engine_ptr, key)
      ZenDecisionResult.from_raw_result(raw_result)
    end

    def get_decision!(key)
      result = get_decision(key)
      raise "Error getting decision for #{key}: #{result.error_code} #{result.details}" if result.error
      result
    end

    # Create a decision from a JSON string directly; bypasses the loader.
    def create_decision(content)
      # Caller is responsible for freeing: content and ZenResult.
      raw_result = ZenRuby.zen_engine_create_decision(@engine_ptr, content)
      ZenDecisionResult.from_raw_result(raw_result)
    end

    # Create a decision from a JSON string directly; bypasses the loader.
    def create_decision!(content)
      result = create_decision(content)
      raise "Error creating decision: #{result.error_code} #{result.details}" if result.error
      result
    end
  end

  ZenDecisionResult = Struct.new(:result, :error, :error_code, :details) do
    def evaluate(context, trace: false, max_depth: 10)
      if error
        raise "Error evaluating decision for #{key}: #{error_code} #{details}"
      end

      evaluation_options = ZenEngineEvaluationOptions.new
      evaluation_options[:trace] = trace
      evaluation_options[:max_depth] = max_depth

      raw_result = ZenRuby.zen_decision_evaluate(result, context.to_json, evaluation_options)
      ZenRuby::Result.from_raw_result(raw_result)
    end

    def evaluate!(...)
      ZenRuby.unwrap_result!(evaluate(...))
    end

    def self.from_raw_result(raw_result)
      if raw_result[:error] == 0
        ZenDecisionResult.new(raw_result[:result], false, 0, nil)
      else
        ZenDecisionResult.new(nil, true, raw_result[:error], raw_result[:details].null? ? nil : raw_result[:details].read_string)
      end
    end
  end

  Result = Struct.new(:result, :error, :error_code, :details) do
    def self.from_raw_result(raw_result)
      if raw_result[:error] == 0
        json_string = raw_result[:result].read_string
        ZenRuby::Result.new(JSON.parse(json_string), false, 0, nil)
      else
        ZenRuby::Result.new(nil, true, raw_result[:error], raw_result[:details].read_string)
      end
    end
  end

  def self.unwrap_result!(result)
    raise "Error evaluating: #{result.error_code} #{result.details}" if result.error
    result.result
  end

  def self.evaluate_expression(expression, context)
    raw_result = ZenRuby.zen_evaluate_expression(expression, context.to_json)
    ZenRuby::Result.from_raw_result(raw_result)
  end

  def self.evaluate_expression!(expression, context)
    ZenRuby.unwrap_result!(evaluate_expression(expression, context))
  end

  def self.evaluate_unary_expression(expression, context)
    raw_result = ZenRuby.zen_evaluate_unary_expression(expression, context.to_json)
    if raw_result[:error] == 0
      value = raw_result[:result].read(:int)
      ZenRuby::Result.new(value == 1, false, 0, nil)
    else
      ZenRuby::Result.new(nil, true, raw_result[:error], raw_result[:details].read_string)
    end
  end

  def self.evaluate_unary_expression!(expression, context)
    ZenRuby.unwrap_result!(evaluate_unary_expression(expression, context))
  end

  def self.render_template(template, context)
    raw_result = ZenRuby.zen_evaluate_template(template, context.to_json)
    ZenRuby::Result.from_raw_result(raw_result)
  end

  def self.render_template!(template, context)
    ZenRuby.unwrap_result!(render_template(template, context))
  end
end
