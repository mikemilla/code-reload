import 'dart:async';

class ToolParameter {
  const ToolParameter({
    required this.name,
    required this.type,
    required this.description,
    this.required_ = true,
    this.enumValues,
  });

  final String name;
  final String type;
  final String description;
  final bool required_;
  final List<String>? enumValues;

  Map<String, dynamic> toJsonSchema() {
    final schema = <String, dynamic>{
      'type': type,
      'description': description,
    };
    if (enumValues != null) schema['enum'] = enumValues;
    return schema;
  }
}

abstract class BunbuTool {
  String get name;
  String get description;
  List<ToolParameter> get parameters;

  Future<String> execute(Map<String, dynamic> args);

  Map<String, dynamic> toFunctionSchema() {
    final properties = <String, dynamic>{};
    final required = <String>[];

    for (final param in parameters) {
      properties[param.name] = param.toJsonSchema();
      if (param.required_) required.add(param.name);
    }

    return {
      'type': 'function',
      'function': {
        'name': name,
        'description': description,
        'parameters': {
          'type': 'object',
          'properties': properties,
          'required': required,
        },
      },
    };
  }
}

class ToolRegistry {
  final Map<String, BunbuTool> _tools = {};

  void register(BunbuTool tool) {
    _tools[tool.name] = tool;
  }

  void unregister(String name) {
    _tools.remove(name);
  }

  BunbuTool? get(String name) => _tools[name];

  List<BunbuTool> get all => _tools.values.toList();

  List<Map<String, dynamic>> toFunctionSchemas() {
    return _tools.values.map((t) => t.toFunctionSchema()).toList();
  }

  Future<String> executeTool(String name, Map<String, dynamic> args) async {
    final tool = _tools[name];
    if (tool == null) {
      throw ToolNotFoundException('Tool not found: $name');
    }
    return tool.execute(args);
  }
}

class ToolNotFoundException implements Exception {
  const ToolNotFoundException(this.message);
  final String message;

  @override
  String toString() => 'ToolNotFoundException: $message';
}
