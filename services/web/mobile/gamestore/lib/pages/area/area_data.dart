class Area {
  int id;
  String name;
  String color;
  String icon;
  bool subscribable;
  String description;
  List<Action> actions;
  List<Reaction> reactions;

  Area({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.subscribable,
    required this.description,
    required this.actions,
    required this.reactions,
  });

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      id: json['id'],
      name: json['name'],
      color: json['color'],
      icon: json['icon'],
      subscribable: json['subscribable'],
      description: json['description'],
      actions: (json['actions'] as List)
          .map((action) => Action.fromJson(action))
          .toList(),
      reactions: (json['reactions'] as List)
          .map((reaction) => Reaction.fromJson(reaction))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'subscribable': subscribable,
      'actions': actions.map((a) => a.toJson()).toList(),
      'reactions': reactions.map((r) => r.toJson()).toList(),
    };
  }
}

class Action {
  int id;
  String name;
  String description;
  int serviceId;
  List<Param> parameters;
  List<dynamic> outputs;

  Action({
    required this.id,
    required this.name,
    required this.description,
    required this.serviceId,
    required this.parameters,
    required this.outputs,
  });

  factory Action.fromJson(Map<String, dynamic> json) {
    return Action(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      serviceId: json['service_id'],
      parameters: (json['parameters'] as List)
          .map((param) => Param.fromJson(param))
          .toList(),
      outputs: json['outputs'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'service_id': serviceId,
      'parameters': parameters.map((p) => p.toJson()).toList(),
      'outputs': outputs,
    };
  }
}

class Reaction {
  int id;
  String name;
  String description;
  int serviceId;
  List<Param> parameters;

  Reaction({
    required this.id,
    required this.name,
    required this.description,
    required this.serviceId,
    required this.parameters,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      serviceId: json['service_id'],
      parameters: (json['parameters'] as List)
          .map((param) => Param.fromJson(param))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'service_id': serviceId,
      'parameters': parameters.map((p) => p.toJson()).toList(),
    };
  }
}

class Param {
  String name;
  String type;
  bool?
      required;
  String? value;

  Param({
    required this.name,
    required this.type,
    this.required,
    this.value,
  });

  factory Param.fromJson(Map<String, dynamic> json) {
    return Param(
      name: json['name'],
      type: json['type'],
      required: json['required'],
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'required': required,
      'value': value,
    };
  }
}
